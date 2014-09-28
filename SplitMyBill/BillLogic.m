//
//  BillLogic.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BillLogic.h"

/*
 notes:
  item total - 2 digit
  total tax - round to 2 digit
  total tip - round to 2 digit

 user total:
  1. determine the % owed (positive items / all positive items)
  2. determine tax & tip on item totals (no rounding)
  3. determine the totals items + tax - discounts + tip
  4. multiply by % owed and round to 2 digits
  5. add up all user totals
  6. adjust if sum is < or > than actual totals (adding/subtracting based on how much user was rounded to their current value)
*/

@interface BillLogic() <NSDecimalNumberBehaviors>

@property (nonatomic, strong) NSMutableArray *userAmounts;
@property (nonatomic, strong) NSMutableArray *userSubtotals;
@property (nonatomic) bool userValuesCalculated;
@property (nonatomic, strong) NSMutableArray *myItems;
@property (nonatomic, strong) NSDecimalNumber *userTax;

//cache of local variables to speed up multiple calls (all are calculated at once whenever anyone is needed)
@property NSInteger internalTax;
@property NSInteger internalTip;
@property NSInteger internalRawTip;
@property NSInteger internalItemTotal;
@property NSInteger internalSubtotal;
@property NSInteger internalTotal;
@property NSInteger internalRawTotal;

@end

@implementation BillLogic
- (id) initWithBill:(Bill *)bill andContext:(NSManagedObjectContext *)context
{
    self = [super init];
    self.bill = bill;
    self.managedContext = context;
    
    //populate data from bill here...
    for(BillPerson *person in self.bill.people) {
        [self.users addObject:[[BillUser alloc] initWithPerson:person]];
    }

    //now populate the items
    for(BillItem *item in self.bill.items) {
        [self.myItems addObject:[[BillLogicItem alloc] initWithItem:item]];
    }
    
    if(![self.bill.taxInDollars boolValue])
        self.tax = self.bill.tax;
    else
        self.taxInDollars = self.bill.tax;
    
    if(![self.bill.tipInDollars boolValue])
        self.tip = self.bill.tip;
    else
        self.tipInDollars = self.bill.tip;
        
    switch ([self.bill.rounding integerValue]) {
        case 0:
            self.roundingAmount = 0;
            break;
        case 1:
            self.roundingAmount = 5;
            break;
        case 2:
            self.roundingAmount = 10;
            break;
        case 3:
            self.roundingAmount = 25;
            break;
        case 4:
            self.roundingAmount = 50;
            break;
        case 5:
            self.roundingAmount = 100;
            break;
            
        default:
            break;
    }
    
    return self;
}

//data model
@synthesize bill = _bill;
@synthesize managedContext = _managedContext;

@synthesize userAmounts = _userAmounts;
@synthesize userSubtotals = _userSubtotals;
@synthesize userValuesCalculated = _userValuesCalculated;
@synthesize myItems = _myItems;
@synthesize userTax = _userTax;
@synthesize roundingAmount = _roundingAmount;
- (NSInteger) roundingAmount {
    return _roundingAmount;
}
- (void)setRoundingAmount:(NSInteger)roundingAmount 
{
    self.userValuesCalculated = NO;
    _roundingAmount = roundingAmount;
    
    //convert between 0,5,10,25,50,100 to 0,1,2,3,4,5
    NSInteger keyVal = 0;
    switch (roundingAmount) {
        case 5:
            keyVal = 1;
            break;
        case 10:
            keyVal = 2;
            break;
        case 25:
            keyVal = 3;
            break;
        case 50:
            keyVal = 4;
            break;
        case 100:
            keyVal = 5;
            break;
        default:
            break;
    }
    
    self.bill.rounding = [NSNumber numberWithLong:keyVal];
    NSError *error;
    if(![self.managedContext save:&error]) {
        
    }
    
    return;
}

@synthesize internalTax = _internalTax;
@synthesize internalTip = _internalTip;
@synthesize internalItemTotal = _internalItemTotal;
@synthesize internalSubtotal = _internalSubtotal;
@synthesize internalTotal = _internalTotal;
@synthesize internalRawTotal = _internalRawTotal;
@synthesize internalRawTip = _internalRawTip;
- (NSMutableArray *)myItems {
    if(!_myItems) _myItems = [NSMutableArray array];
    return _myItems;
}
@synthesize discountsPreTax = _discountsPreTax;

// calculateAllValues
// we need to calculate all our values at once, to insure rounding is accurate
// anytime a value is looked up, code should call this function to make sure
// the data is accurate
- (void) calculateAllValues {
    //check if any values have been modified, if not we can use our cached ones
    //and skip out on this
    bool shouldContinue = !self.userValuesCalculated;
    if(!shouldContinue) {    
        for(BillLogicItem *item in self.items) {
            if(item.hasChanged) {
                item.hasChanged = NO; //set back to null again
                shouldContinue = YES;
            }
        }
    }
    if(!shouldContinue) return; //nothing has changed on us
    
    //deteremine our raw values
    NSInteger discountInCents = 0;
    NSInteger totalInCents = 0;
    NSInteger discountPreTaxInCents = 0;
    NSInteger discountPostTaxInCents = 0;
    for(BillLogicItem *item in self.items) {
        if(!item.isDiscount) {
            totalInCents += item.cost;
        } else {
            if(item.preTax)
                discountPreTaxInCents += item.cost;
            else
                discountPostTaxInCents += item.cost;
        }
    }
    discountInCents = discountPostTaxInCents + discountPreTaxInCents;
    
    //calculate the tax owed now...
    NSDecimalNumber *total = [NSDecimalNumber decimalNumberWithMantissa:(totalInCents - discountPreTaxInCents) exponent:-2 isNegative:NO];
    if(_taxInDollars) {  //tax was manually specified
        self.internalTax = [[_taxInDollars decimalNumberByMultiplyingByPowerOf10:2] integerValue];
    } else {
        self.internalTax = [[[total decimalNumberByMultiplyingBy:self.tax withBehavior:self] decimalNumberByMultiplyingByPowerOf10:2] integerValue];
    }
    
    //calculate the tip amount now
    total = [NSDecimalNumber decimalNumberWithMantissa:totalInCents exponent:-2 isNegative:NO];
    if(_tipInDollars) { //again if tip manually specified, use that
        self.internalTip = [[_tipInDollars decimalNumberByMultiplyingByPowerOf10:2] integerValue];
    } else {
        self.internalTip = [[[total decimalNumberByMultiplyingBy:self.tip withBehavior:self] decimalNumberByMultiplyingByPowerOf10:2] integerValue];
    }
    
    //now adjust the overall total to handle rounding behaviors
    self.internalItemTotal = totalInCents; //cache raw item total
    self.internalSubtotal = totalInCents + self.internalTax - discountInCents;
    if(self.internalSubtotal < 0)  //if discounts were greater than bill, make it zero
        self.internalSubtotal = 0;
    
    //add in the tip now
    self.internalTotal = self.internalSubtotal + self.internalTip;
    self.internalRawTotal = self.internalTotal;  //cache unrounded total
    
    //now handle rounding the value
    self.internalRawTip = self.internalTip;
    //only round if total is > zero, and tip is not 0
    if((self.roundingAmount > 0) && (self.internalTotal > 0) && (self.internalRawTip > 0)) {
        NSInteger temp = ((self.internalTotal - 1) / self.roundingAmount) * self.roundingAmount + self.roundingAmount;
        self.internalTip = temp - (self.internalSubtotal);
        self.internalTotal = temp;
    }
    
    //now that we have the rounded total, we need to figure out what each
    //users share will be
    [self calculateUserTallies];
}

// calculateUserTallies
// splits the bill up among all the users
// also handles distribution of uneven splits as fairly as possible)
- (void)calculateUserTallies {

    //initialize our data so each users amount owed is zero
    if(self.myItems.count == 0) {
        //set all to zero and return
        NSDecimalNumber *zero = [NSDecimalNumber zero];
        self.userAmounts = [NSMutableArray arrayWithCapacity:self.users.count];
        self.userSubtotals = [NSMutableArray arrayWithCapacity:self.users.count];
        for(NSInteger i=0;i<self.users.count; i++) {
            [self.userAmounts addObject:zero];
            [self.userSubtotals addObject:zero];
        }
        self.userTax = [NSDecimalNumber zero];
        self.userValuesCalculated = YES;
        return;
    }
    
    //initialize variables that wil be used in either set of calculations
    NSDecimalNumber *zero = [NSDecimalNumber zero];
    self.userAmounts = [NSMutableArray arrayWithCapacity:self.users.count];
    self.userSubtotals = [NSMutableArray arrayWithCapacity:self.users.count];
    
    NSMutableArray *roundedSubtotals = [NSMutableArray arrayWithCapacity:self.users.count];
    NSMutableArray *roundedAmounts = [NSMutableArray arrayWithCapacity:self.users.count];
    
    //if we only have 1 user, we are in "simple" mode, just compute user's total
    //and accept standard rounding
    if (self.users.count == 1) {
        
        //quick logic instead
        NSDecimalNumber *useritemtotal = zero;
        NSDecimalNumber *userdiscountsPreTax = zero;
        NSDecimalNumber *userdiscountsPostTax = zero;
        
        for(BillLogicItem *item in self.items) {
            if(!item.isDiscount) {
                useritemtotal = [useritemtotal decimalNumberByAdding:[item actualCostForUser:nil]];
            } else {
                if(item.preTax) {
                    userdiscountsPreTax = [userdiscountsPreTax decimalNumberByAdding:[item actualCostForUser:nil]];
                } else {
                    userdiscountsPostTax = [userdiscountsPostTax decimalNumberByAdding:[item actualCostForUser:nil]];
                }
            }
        }
        
        //tip regardless of discount value
        NSDecimalNumber *tip;
        if(_tipInDollars) {
            tip = _tipInDollars;
        } else {
            //item discount logic...
            tip = [useritemtotal decimalNumberByMultiplyingBy:self.tip withBehavior:self];
        }
        
        //add in pre tax discounts
        useritemtotal = [useritemtotal decimalNumberByAdding:userdiscountsPreTax];
        
        //we check _taxindollars as .taxindollars will call us again
        if(_taxInDollars) {
            self.userTax = _taxInDollars;
        } else {
            self.userTax = [useritemtotal decimalNumberByMultiplyingBy:self.tax withBehavior:self];
        }
        
        //add in post tax discounts, and then add the tax
        useritemtotal = [useritemtotal decimalNumberByAdding:userdiscountsPostTax withBehavior:self];
        useritemtotal = [useritemtotal decimalNumberByAdding:self.userTax];
        if([useritemtotal compare:zero] != NSOrderedDescending) {
            useritemtotal = zero;
        }
        
        //account for rounding setting now
        self.internalRawTip = [[tip decimalNumberByMultiplyingByPowerOf10:2] integerValue];
        
        [self.userSubtotals addObject:useritemtotal];
        if((self.roundingAmount > 0) && (![useritemtotal isEqualToNumber:zero])) {
            NSDecimalNumber *total = [useritemtotal decimalNumberByAdding:tip];
            //convert to cents
            NSInteger roundedTotal = [[total decimalNumberByMultiplyingByPowerOf10:2] integerValue];
            //divide by rounding factor and multiply by the result + 1 to get us to the rounded value (we subtract one in case we started on a rounded value, maybe not the most efficient method)
            roundedTotal = (((roundedTotal - 1) / self.roundingAmount) * self.roundingAmount) + self.roundingAmount;
            total = [NSDecimalNumber decimalNumberWithMantissa:roundedTotal exponent:-2 isNegative:NO];
            [self.userAmounts addObject:total];            
        } else {
            [self.userAmounts addObject:[useritemtotal decimalNumberByAdding:tip]];            
        }
        
        self.userValuesCalculated = YES;
        return;
    }
    
    //if here we are in complex mode, and we need totals for each user
    //get the raw numbers we need for our calculations
    NSDecimalNumber *itemtotal = [NSDecimalNumber decimalNumberWithMantissa:self.internalItemTotal exponent:-2 isNegative:NO];    
    NSDecimalNumber *itemtotalAndTax = [NSDecimalNumber decimalNumberWithMantissa:(self.internalItemTotal + self.internalTax) exponent:-2 isNegative:NO];
    NSDecimalNumber *totalAndTip = [NSDecimalNumber decimalNumberWithMantissa:(self.internalItemTotal + self.internalTax + self.internalTip) exponent:-2 isNegative:NO];
    
    for(BillUser *user in self.users) {
        NSDecimalNumber *useritemtotal = zero;
        NSDecimalNumber *userdiscounts = zero;
        for(BillLogicItem *item in self.items) {
            if(!item.isDiscount) {
                useritemtotal = [useritemtotal decimalNumberByAdding:[item actualCostForUser:user]];
            } else {
                userdiscounts = [userdiscounts decimalNumberByAdding:[item actualCostForUser:user]];
            }
        }
        
        //if the total is zero, they owe nothing
        if([itemtotal isEqualToNumber:zero]) {
            [self.userSubtotals addObject:zero];
            [self.userAmounts addObject:zero];
            continue;
        }
        
        //percent of bill they owe that tax & tip is caclulated upon
        useritemtotal = [useritemtotal decimalNumberByDividingBy:itemtotal]; 
        
        //they owe = (% owe * total (w/o discounts)) - their discounts
        NSDecimalNumber *rawValue = [[useritemtotal decimalNumberByMultiplyingBy:itemtotalAndTax] decimalNumberByAdding:userdiscounts];
        NSDecimalNumber *roundedValue = [[useritemtotal decimalNumberByMultiplyingBy:itemtotalAndTax] decimalNumberByAdding:userdiscounts withBehavior:self];
        [roundedSubtotals addObject:[NSNumber numberWithInteger:[[[rawValue decimalNumberBySubtracting:roundedValue] decimalNumberByMultiplyingByPowerOf10:4] integerValue]]];
        
        //for safety, if less than zero, make value zero (we assume users must owe something and bill is incompletly entered in this case)
        if([roundedValue compare:zero] != NSOrderedDescending) {
            roundedValue = zero;
        }
        [self.userSubtotals addObject:roundedValue];
        
        useritemtotal = [useritemtotal decimalNumberByMultiplyingBy:totalAndTip];
        rawValue = [useritemtotal decimalNumberByAdding:userdiscounts];
        roundedValue = [useritemtotal decimalNumberByAdding:userdiscounts withBehavior:self];
        //contains the remainder we rounded off to get to decimal places, so if total was 2.2345, this would end up at 45 (used in distribute pennies below)
        [roundedAmounts addObject:[NSNumber numberWithInteger:[[[rawValue decimalNumberBySubtracting:roundedValue] decimalNumberByMultiplyingByPowerOf10:4] integerValue]]];
        if([roundedValue compare:zero] != NSOrderedDescending) {
            roundedValue = zero;
        }        
        [self.userAmounts addObject:roundedValue];        
    }
    
    //at this point we know what each user owes, but the totals may not actually add
    //up to the right total due to rounding errors
    //so lets adjust the totals so we get the right results
    [self distributePenniesFromTotal:[NSDecimalNumber decimalNumberWithMantissa:self.internalSubtotal exponent:-2 isNegative:NO] toUsers:self.userSubtotals andRoundedBy:roundedSubtotals];
    
    [self distributePenniesFromTotal:[NSDecimalNumber decimalNumberWithMantissa:self.internalTotal exponent:-2 isNegative:NO] toUsers:self.userAmounts andRoundedBy:roundedAmounts];
    
    self.userValuesCalculated = YES;   
}

// distributePenniesFromTotal
// used to determine if an array of values adds up to the specified value
// it will then adjust totals up and down based on how much they were rounded
// -userCosts: unrounded values (more than 2 decimal places)
// -roundedAmounts: amount rounded off the user 
- (void)distributePenniesFromTotal:(NSDecimalNumber *)total toUsers:(NSMutableArray *)userCosts andRoundedBy:(NSMutableArray *)roundedAmounts 
{
    NSDecimalNumber *zero = [NSDecimalNumber zero];
    NSDecimalNumber *penny = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-2 isNegative:NO];
    
    //first determine the difference in total to user costs
    for(NSDecimalNumber *userOwes in userCosts) {
        total = [total decimalNumberBySubtracting:userOwes];
    }
    
    //sort rounded amounts
    NSInteger change = [[total decimalNumberByMultiplyingByPowerOf10:2] integerValue];    
    if(change == 0) return;  //all is good, no need to do any more work
    
    //sort the array now based on either who was rounded up the most or who was rounded down the most
    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:(change > 0)];
    NSArray *sorted = [roundedAmounts sortedArrayUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
    
    // go through our sorted array and add/remove penny in order until our total is
    // accurate again, ideally on ties we'd make it random
    for(NSInteger i=0; i <userCosts.count; i++) {
        if(change == 0)
            break;
        
        NSNumber *rounded = [sorted objectAtIndex:i];
        NSUInteger indexToUser = [roundedAmounts indexOfObject:rounded];
        
        NSDecimalNumber *current = [userCosts objectAtIndex:indexToUser];
        [roundedAmounts removeObjectAtIndex:indexToUser];
        
        if([current compare:zero] != NSOrderedDescending) //don't modify a total if a user owes nothing
            continue;
        
        if(change < 0) {
            if([current isEqualToNumber:zero])
                continue;  //don't remove a penny if a user owes no tip            
            current = [current decimalNumberBySubtracting:penny];
            change++;
        } else {
            current = [current decimalNumberByAdding:penny];
            change--;
        }
        
        [userCosts replaceObjectAtIndex:indexToUser withObject:current];        
    }
}

#pragma mark - Base Level (Tip, Tax, Totals logic)
@synthesize tax = _tax; //in percent
- (bool) setTax:(NSDecimalNumber *)tax andInDollars:(bool)inDollars {
    
    self.bill.tax = tax;
    self.bill.taxInDollars = [NSNumber numberWithBool:inDollars];
    
    //on tax set save to data model
    NSError *error;
    if(![self.managedContext save:&error]) {
        return NO;
    }

    return YES;    
}

- (void) setTax:(NSDecimalNumber *)tax {
    _tax = tax;
    self.taxInDollars = nil;
    self.userValuesCalculated = NO;
    
    [self setTax:tax andInDollars:NO];
}

@synthesize taxInDollars = _taxInDollars;
- (void) setTaxInDollars:(NSDecimalNumber *)taxInDollars {
    _taxInDollars = taxInDollars;
    self.userValuesCalculated = NO;
    [self setTax:taxInDollars andInDollars:YES];
}

- (NSDecimalNumber *) taxInDollars {
    [self calculateAllValues];
    
    if(self.users.count == 1) {
        return self.userTax;
    }
    return [NSDecimalNumber decimalNumberWithMantissa:self.internalTax exponent:-2 isNegative:NO];
}     
- (bool) isTaxInDollars {
    return (_taxInDollars != nil);
}

@synthesize tip = _tip;
- (bool) setTip:(NSDecimalNumber *)tip andInDollars:(bool)inDollars {
    
    self.bill.tip = tip;
    self.bill.tipInDollars = [NSNumber numberWithBool:inDollars];
    
    //on tax set save to data model
    NSError *error;
    if(![self.managedContext save:&error]) {
        return NO;
    }
    
    return YES;
}

- (void) setTip:(NSDecimalNumber *)tip {
    _tip = tip;
    self.tipInDollars = nil;
    self.userValuesCalculated = NO;
    
    [self setTip:tip andInDollars:NO];
}

- (NSDecimalNumber *)rawTip {
    return [NSDecimalNumber decimalNumberWithMantissa:self.internalRawTip exponent:-2 isNegative:NO];
}

@synthesize tipInDollars = _tipInDollars;
- (NSDecimalNumber *) tipInDollars {
    //if(_tipInDollars)
    //    return _tipInDollars;

    [self calculateAllValues];
    
    if(self.users.count == 1) {
        return [self tipForUser:[self.users objectAtIndex:0]];
    }
    return [NSDecimalNumber decimalNumberWithMantissa:self.internalTip exponent:-2 isNegative:NO];
}
- (void) setTipInDollars:(NSDecimalNumber *)tipInDollars {
    _tipInDollars = tipInDollars;
    self.userValuesCalculated = NO;
    [self setTip:tipInDollars andInDollars:YES];
}

- (bool) isTipInDollars {
    return (_tipInDollars != nil);
}

- (NSDecimalNumber *) subtotal {
    [self calculateAllValues];
    
    if(self.users.count == 1) {
        return [self.userSubtotals objectAtIndex:0];        
    }
    
    return [NSDecimalNumber decimalNumberWithMantissa:self.internalSubtotal exponent:-2 isNegative:NO];    
}

- (NSDecimalNumber *) total {
    [self calculateAllValues];    

    if(self.users.count == 1) {
        return [self.userAmounts objectAtIndex:0];        
    }
    
    return [NSDecimalNumber decimalNumberWithMantissa:self.internalTotal exponent:-2 isNegative:NO];        
}

- (NSDecimalNumber *) itemTotal {
    [self calculateAllValues];    
    return [NSDecimalNumber decimalNumberWithMantissa:self.internalItemTotal exponent:-2 isNegative:NO];    
}

// totalWhenRoundedTo
// -roundBy : integer value to round total to in cents (0, 5, 10, 25, etc expected)
- (NSDecimalNumber *) totalWhenRoundedTo:(NSInteger)roundBy
{
    if(self.internalRawTotal ==0)
        return [NSDecimalNumber zero];
    
    if(roundBy == 0)
        return [NSDecimalNumber decimalNumberWithMantissa:self.internalRawTotal exponent:-2 isNegative:NO];
        
    if(roundBy == self.roundingAmount)
        return [NSDecimalNumber decimalNumberWithMantissa:self.internalTotal exponent:-2 isNegative:NO];
    
    NSInteger roundedTotal = self.internalRawTotal;
    
    roundedTotal = (((roundedTotal - 1)/roundBy) * roundBy) + roundBy;
    
    return [NSDecimalNumber decimalNumberWithMantissa:roundedTotal exponent:-2 isNegative:NO];
}

#pragma mark - Purchases & Discounts (Coupons)
- (NSArray *)items {
    return [self.myItems copy];
}

- (bool) addItem:(BillLogicItem *)item {
    //add to internal bill
    [self.bill addItemsObject:item.item];
    
    //add to collection of item wrappers
    [self.myItems addObject:item];
    self.userValuesCalculated = NO;

    //if simple mode, add all users to the item
    if([self.bill.type integerValue] == 1) {
        for(BillUser *user in self.users) {
            [item addUser:user];
        }
    }
    
    //save changes
    NSError *error;
    if(![self.managedContext save:&error]) {
        return NO;
    }
    
    return YES;
}

- (bool) removeItem:(BillLogicItem *)item {
    //remove from logic
    [self.bill removeItemsObject:item.item];
    
    [self.myItems removeObject:item];
    self.userValuesCalculated = NO;
    
    //force delete of item object as well
    [self.managedContext deleteObject:item.item];
    item.item = nil;
    
    //save changes
    NSError *error;
    if(![self.managedContext save:&error]) {
        return NO;
    }
    
    return YES;
}

- (bool) saveChanges {
    //save data associated with the item
    NSError *error;
    if(![self.managedContext save:&error]) {
        return NO;
    }
    
    return YES;
}

- (bool) discardChanges {
    [self.managedContext rollback];
    return YES;
}

#pragma mark - User related logic
- (NSUInteger) userCount {
    return self.bill.people.count;
}

@synthesize users = _users;
- (NSArray *)users {
    if(!_users) {
        _users = [[NSMutableArray alloc] init];
    }
    return _users;
}

- (bool) addUser:(BillUser *)user {
    //if we are using a data model object, these become BillPersons...
    if(user.isSelf) {
        //verify no other user is flagged as self
        if([self getSelf])
            return NO;
    }
    
    if(!user.person) {
        //build person object & save model?
        user.person  = [NSEntityDescription insertNewObjectForEntityForName:@"BillPerson" inManagedObjectContext:self.managedContext];
        
        user.person.contact = user.contact;
        if(!user.contact) {
            //populate fields manually instead...
            user.person.name = user.name;
            user.person.initials = user.abbreviation;
            user.person.phone = user.phone;
            user.person.email = user.email;
        }
        
        user.person.isMe = [NSNumber numberWithBool:user.isSelf];
        
    } else if([self.bill.people containsObject:user.person]) {
            return NO;
    }
    
    //add person onto the bill
    [self.bill addPeopleObject:user.person];
    
    //if simple mode, users get added to each object when added
    if([self.bill.type integerValue] == 1) {
        if(self.items.count > 0) {
            BillLogicItem *item = [self.items objectAtIndex:0];
            [item addUser:user];
        
            self.userValuesCalculated = NO;
        }
    }
    
    //save off our changes
    NSError *error = nil;
    if(![self.managedContext save:&error]) {
        return NO;
    }
    
    [self.users addObject: user];    
    if(self.bill.people.count == 2) {
        //when we go from 1 to 2 users, we need to reset all splits
        for(BillLogicItem *item in self.items) {
            item.split = 1;
        }
    }
    
    self.userValuesCalculated = NO;
    return YES;
}

- (bool) removeUser:(BillUser *)user {
    [self.users removeObject:user];
    [self.bill removePeopleObject:user.person];
    for(BillLogicItem *item in self.items) {
        [item removeUser:user];
    }
    
    //save off our changes
    [self.managedContext deleteObject:user.person];

    NSError *error = nil;
    if(![self.managedContext save:&error]) {
        return NO;
    }
    
    //fix item splits if applicable
    if(self.bill.people.count == 0) {
        //when we go from 1 to 0 users, we need to reset all splits as well
        for(BillLogicItem *item in self.items) {
            item.split = 1;
        }        
    }
    
    //need to update all values now
    self.userValuesCalculated = NO;
    return YES;
}

-(bool) removeUserByContact:(Contact *)contact {
    BillUser *user;
    for(user in self.users) {
        if([contact isEqual:user.contact]) {
            break;
        }
    }

    if(!user) //no user exists, already removed?
        return YES;
    
    //now call normal remove user function...
    return [self removeUser:user];
}

- (bool) hasUserByContact:(Contact *)contact {
    for(BillPerson *person in self.bill.people) {
        if([person.contact isEqual:contact]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger) numberOfGenericUsers
{
    NSInteger count = 0;
    for(BillPerson *person in self.bill.people) {
        if(!person.contact && ![person.isMe boolValue]) {
            count++;
        }
    }
    return count;
}

- (BillUser *) getGenericUser:(NSInteger)index
{
    NSInteger count = 0;
    for(BillUser *user in self.users) {
        if(user.contact || user.isSelf)
            continue;
        
        if(count == index)
            return user;
        
        count++;
    }
    
    return nil;
}

- (BillUser *) getSelf {
    for(BillUser *user in self.users) {
        if(user.isSelf)
            return user;
    }
    return nil;
}

// returns an array on BillItems that a user is listed on
- (NSArray *) itemsForUser:(BillUser*)user {
    NSMutableArray *userItems = [NSMutableArray array];
    for(BillLogicItem *item in self.items) {
        if([item.users containsObject:user]) {
            [userItems addObject:item];
        }
    }
    return [userItems copy];
}

- (NSDecimalNumber *) tipForUser:(BillUser *)user {
    //actual tip is the difference between their total and subtotal
    return [[self totalForUser:user] decimalNumberBySubtracting:[self subtotalForUser:user]];
}

- (NSDecimalNumber *) taxForUser:(BillUser *)user {
    NSDecimalNumber *subtotal = [self subtotalForUser:user];
    NSDecimalNumber *items = [self itemtotalForUser:user];
    
    //tax is the difference between these numbers
    return [subtotal decimalNumberBySubtracting:items];
}

- (NSDecimalNumber *) itemtotalForUser:(BillUser *)user {
    //check user exists
    NSUInteger index = [self.users indexOfObject:user];
    if(index == NSNotFound) return [NSDecimalNumber zero];

    [self calculateAllValues];
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for(BillLogicItem *item in self.items) {
        if([item.users containsObject:user]) {
            total = [total decimalNumberByAdding:[item actualCostForUser:user]];
        }
    }
    
    //round this value
    total = [total decimalNumberByAdding:[NSDecimalNumber zero] withBehavior:self];
    //NSDecimalNumber *allTotal = [self itemtotalForUser:user];
    
    //if(total > allTotal) {
    //    total = allTotal; //can't go over this value
    //}
    return total;
}

- (NSDecimalNumber *) subtotalForUser:(BillUser *)user {
    [self calculateAllValues];
    NSUInteger index = [self.users indexOfObject:user];
    if(index == NSNotFound) return [NSDecimalNumber zero];
    return [self.userSubtotals objectAtIndex:index];
}

- (NSDecimalNumber *) totalForUser:(BillUser *)user {
    [self calculateAllValues];    
    NSUInteger index = [self.users indexOfObject:user];
    if(index == NSNotFound) return [NSDecimalNumber zero];
    return [self.userAmounts objectAtIndex:index];
}

/*
- (void) resetDataNewTip:(NSDecimalNumber *)tip newTax:(NSDecimalNumber *)tax
{
    self.myItems = nil;
    self.tax = tax;
    self.taxInDollars = nil;
    self.tip = tip;
    self.userValuesCalculated = NO;
    self.internalTax = 0;
    self.internalTip = 0;
    self.internalItemTotal = 0;
    self.internalSubtotal = 0;
    self.internalTotal = -32000; //means not calculated
    self.roundingAmount = 0;
}
*/

#pragma mark - Display Related Functions
//returns tip as percent: XX.X%
+ formatTip:(NSDecimalNumber *)tipPercent
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *tip = [formatter stringFromNumber:[tipPercent decimalNumberByMultiplyingByPowerOf10:2]];
    return [tip stringByAppendingString:@"%"];
}

//returns tip as percent, dollar value: XX.X%, $YY.YY
+ formatTip:(NSDecimalNumber *)tipPercent withActual:(NSDecimalNumber *)actual {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *tip = [formatter stringFromNumber:[tipPercent decimalNumberByMultiplyingByPowerOf10:2]];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    tip = [tip stringByAppendingFormat:@"%%, %@", [formatter stringFromNumber:actual]];
    return tip;
}

//returns the value formatted as money: $XX.XX
+ formatMoney:(NSDecimalNumber *)money {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    return [formatter stringFromNumber:money];
}
+ formatMoneyWithInt:(NSInteger)money {
    
    NSInteger moneyPositive = money;
    bool isNeg = NO;
    if(money < 0) {
        moneyPositive *= -1;
        isNeg = YES;
    }
    NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithMantissa:moneyPositive exponent:-2 isNegative:isNeg];
    
    return [self formatMoney:temp];
}
//returns the values formatted in dollar as sub+tip=total: $X.XX+$Y.YY=$Z.ZZ
+ formatUserSubtotal:(NSDecimalNumber *)subtotal
              andTip:(NSDecimalNumber *)tip
            andTotal:(NSDecimalNumber *)total 
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];

    if([subtotal isEqualToNumber:[NSDecimalNumber zero]])
        return @"$0.00";
    
    return [NSString stringWithFormat:@"%@+%@=%@", [formatter stringFromNumber:subtotal], [formatter stringFromNumber:tip], [formatter stringFromNumber:total]];
}

#pragma mark - NSDecimalNumberBehaviors
- (NSRoundingMode)roundingMode {
    return NSRoundPlain;
}

- (short)scale {
    return 2; //we use 2 digits $0.00
}

- (NSDecimalNumber *)exceptionDuringOperation:(SEL)method error:(NSCalculationError)error leftOperand:(NSDecimalNumber *)leftOperand rightOperand:(NSDecimalNumber *)rightOperand
{
    return nil;
}

@end
