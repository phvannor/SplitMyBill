//
//  BillItem.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "BillLogicItem.h"
#import "BillLogic.h"

@interface BillLogicItem() <NSDecimalNumberBehaviors>
@property (nonatomic, strong) NSArray *userTotals;
@end

@implementation BillLogicItem
@synthesize item = _item;
- (id) initWithItem:(BillItem *)item
{
    self = [super init];
    self.item = item;
    self.isNew = NO;
    
    NSMutableArray *newUsers = [[NSMutableArray alloc] init];
    for(BillPerson *person in item.people) {
        [newUsers addObject:[[BillUser alloc] initWithPerson:person]];
    }
    _users = [newUsers copy];
    
    return self;
}
@synthesize isNew = _isNew;

- (NSString *) name {
    if(!self.item.name)
        return @"";
    
    return self.item.name;
}
- (void) setName:(NSString *)name {
    self.item.name = name;
}

//only return positive values from this function
- (NSInteger) cost {
    NSInteger cost = [self.item.price integerValue];
    if(cost < 0) cost *= -1;
    
    return cost;
}
- (void) setCost:(NSInteger)cost {
    if(self.isDiscount) {
        if(cost > 0) cost *= -1;
    }
    
    self.item.price = [NSNumber numberWithInt:cost];
    self.userTotals = nil; //will need to recalculate this value
    self.hasChanged = YES;
}

@synthesize isDiscount = _isDiscount;
- (bool) isDiscount {
    return ([self.item.price integerValue] < 0);
}
- (void) setIsDiscount:(bool)isDiscount {
    NSInteger price = [self.item.price integerValue];
    if((price > 0 && isDiscount) || (price < 0 && !isDiscount)) {
        price *= -1;
        self.item.price = [NSNumber numberWithInteger:price];
    }
}

//only applies if isDiscount
- (bool) preTax {
    return [self.item.preTax boolValue];
}
- (void) setPreTax:(bool)preTax {
    self.item.preTax = [NSNumber numberWithBool:preTax];
}

@synthesize userTotals = _userTotals;
@synthesize hasChanged = _hasChanged;

//Simple mode parameters
- (NSInteger) split {
    return [self.item.split integerValue];
}
- (void) setSplit:(NSInteger)split {
    self.item.split = [NSNumber numberWithInt:split];
    self.hasChanged = YES;
}

// actualCost
// return the cost/split back
- (NSDecimalNumber *) actualCost {
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithMantissa:self.cost exponent:-2 isNegative:self.isDiscount];
    NSDecimalNumber *split = [NSDecimalNumber decimalNumberWithMantissa:self.split exponent:0 isNegative:NO];
    NSDecimalNumber *result = [price decimalNumberByDividingBy:split withBehavior:self];
    return result;
}

// any change to users should reset userTotals array
@synthesize users = _users;
- (void) setUsers:(NSArray *)users {
    if(self.item.people.count > 0)
        return; //not allowed if users are on item already...
    
    _users = users;
    for(BillUser *user in self.users) {
        [self.item addPeopleObject:user.person];
    }
    
    self.userTotals = nil;
    self.hasChanged = YES;
}
- (NSArray *)users {
    if(!_users) _users = [NSArray array];
    return _users;
}

- (void) removeUser:(BillUser *)user {
    if(![self.users containsObject:user])
        return;
    
    NSMutableArray *editUsers = [self.users mutableCopy];
    [editUsers removeObject:user];
    _users = [editUsers copy];
    
    [self.item removePeopleObject:user.person];
    self.hasChanged = YES;
}

- (void) addUser:(BillUser *)user {
    if([self.users containsObject:user])
        return;
    
    NSMutableArray *editUsers = [self.users mutableCopy];
    [editUsers addObject:user];
    _users = [editUsers copy];
    
    [self.item addPeopleObject:user.person];
    self.hasChanged = YES;
}

// actualCostForUser
// return cost for a specified user (cost/# of users)
// if user is not on the item return 0
- (NSDecimalNumber *) actualCostForUser:(BillUser *)user {
    NSInteger theSplit = 1;
    if(self.users.count > 1) {
        theSplit = self.users.count;    
    } else {
        theSplit = self.split;
    }
    
    if(theSplit == 0) return [NSDecimalNumber zero];  //for safety
    if(user) {
        //double check the user is associated with this product
        if(![self.users containsObject:user])
            return [NSDecimalNumber zero];
    }
    
    //calculate the cost now
    NSDecimalNumber *cost = [NSDecimalNumber decimalNumberWithMantissa:self.cost exponent:-2 isNegative:self.isDiscount];
    NSDecimalNumber *split = [NSDecimalNumber decimalNumberWithMantissa:theSplit exponent:0 isNegative:NO];
    return [cost decimalNumberByDividingBy:split];
}

- (NSString *)costDisplay {
    NSDecimalNumber *decCost = [NSDecimalNumber decimalNumberWithMantissa:self.cost exponent:-2 isNegative:NO];    
    return [BillLogic formatMoney:decCost];
}

- (NSString *)costActualDisplay {
    return [BillLogic formatMoney:self.actualCost];    
}

- (NSString *)costDisplayForUser:(BillUser *)user {
    NSDecimalNumber *total = [NSDecimalNumber decimalNumberWithMantissa:self.cost exponent:-2 isNegative:self.isDiscount];
    NSDecimalNumber *userCost = [self actualCostForUser:user];
    
    //for now we are not worrying about uneven divides (ie 3.33, 3.33, 3.34 we will just show 3.33 or 3.34 for all depending on rounding)
    //eventually we should update this to be accurate, but for now bill logic handles this issue
    if((self.users.count > 1) || (self.split > 1)) {
        return [NSString stringWithFormat:@"%@ of %@", [BillLogic formatMoney:userCost], [BillLogic formatMoney:total]];                    
    }
    
    return [BillLogic formatMoney:total];
}



#pragma mark - NSDecimalNumberBehaviors
- (NSRoundingMode)roundingMode {
    return NSRoundPlain;
}

- (short)scale {
    return 2; //we want 2 digits $0.00
}

- (NSDecimalNumber *)exceptionDuringOperation:(SEL)method error:(NSCalculationError)error leftOperand:(NSDecimalNumber *)leftOperand rightOperand:(NSDecimalNumber *)rightOperand
{
    return nil;
}
@end
