//
//  BillLogic.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//
//  Guts of splitting a bill among users based upon the % of the bill each user owes
//  

#import <Foundation/Foundation.h>
#import "BillLogicItem.h"
#import "BillUser.h"

//proper data model transition
#import "Bill.h"

@interface BillLogic : NSObject

//data model object code
@property (nonatomic, strong) Bill *bill; //represents the bill
@property (nonatomic, weak) NSManagedObjectContext *managedContext;
- (id) initWithBill:(Bill *)bill andContext:(NSManagedObjectContext *)context;

//values applying to the bill as a whole
@property (nonatomic, strong) NSDecimalNumber *tax; //decimal representation of percent (.2 = 20%)
@property (nonatomic, strong) NSDecimalNumber *taxInDollars;
- (bool) isTaxInDollars; //return true is tax is set using taxInDollars
@property (nonatomic, strong) NSDecimalNumber *tip; //decimal representation of percent (.2 = 20%)
@property (nonatomic, strong) NSDecimalNumber *tipInDollars;
- (NSDecimalNumber *) rawTip; //tip value without rounding
- (bool) isTipInDollars; //returns true if top is set using tipInDollars

- (NSDecimalNumber *) subtotal;
- (NSDecimalNumber *) total;
//for now all rounding logic is only up (not nearest)
@property NSInteger roundingAmount;  //how to round the total, 0 exaxt, 5 to nickel, etc
- (NSDecimalNumber *) totalWhenRoundedTo:(NSInteger)roundBy; //returns total as if rounded by te given value

// represents the items on the bill
- (NSArray *)items; //array of BillItems
- (bool) addItem:(BillLogicItem *)item;
- (bool) removeItem:(BillLogicItem *)item;
- (bool) saveChanges;
- (bool) discardChanges;

- (NSDecimalNumber *)itemTotal; //no tax, coupons, or tip
@property (nonatomic) bool discountsPreTax;

// represents the users who are splitting the bill
@property (nonatomic, strong) NSMutableArray *users; //array of BillUsers
- (NSUInteger) userCount;
- (bool) addUser:(BillUser *)user;
- (bool) removeUser:(BillUser *)user;
- (bool) removeUserByContact:(Contact *) contact;
- (bool) hasUserByContact:(Contact *) contact;
- (NSInteger) numberOfGenericUsers;
- (BillUser *) getGenericUser:(NSInteger)index;
- (BillUser *) getSelf;

- (NSDecimalNumber *) tipForUser:(BillUser *)user;
- (NSDecimalNumber *) taxForUser:(BillUser *)user;
- (NSDecimalNumber *) itemtotalForUser:(BillUser *)user;
- (NSDecimalNumber *) subtotalForUser:(BillUser *)user;  //item total + tax
- (NSDecimalNumber *) totalForUser:(BillUser *)user;  //sub + tip)
- (NSArray *) itemsForUser:(BillUser*)user;  //items user is listed on

//helper functions for display only
+ formatTip:(NSDecimalNumber *)tipPercent;  //xx.x%
+ formatTip:(NSDecimalNumber *)tipPercent withActual:(NSDecimalNumber *)actual; //xx%, $yy.yy
+ formatMoney:(NSDecimalNumber *)money;  //$xx.xx
+ formatMoneyWithInt:(NSInteger)money;
+ formatUserSubtotal:(NSDecimalNumber *)subtotal  //$xx.xx+$yy.yy=$zz.zz
              andTip:(NSDecimalNumber *)tip
            andTotal:(NSDecimalNumber *)total;

@end
