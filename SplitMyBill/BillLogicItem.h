//
//  BillLogicItem.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//
//  Represents a single item on a bill, the item can be either a charge or a discount
//  note: all discounts are assumed to be post-tax at the moment

#import <Foundation/Foundation.h>
#import "BillUser.h"
#import "BillPerson.h"
#import "BillItem.h"

@interface BillLogicItem : NSObject
@property (nonatomic, strong) BillItem *item;
//designated initializer
- (id) initWithItem:(BillItem *)item;

@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger cost; //in cents (>= 0 only)
@property (nonatomic) bool hasChanged; //set when any property has been modified (must be manually cleared)
@property (nonatomic) bool isDiscount; //true is cost should be treated as negative
@property (nonatomic) bool preTax;
@property (nonatomic) bool isNew;

//simple mode (not used if the users array is populated)
- (NSDecimalNumber *) actualCost;  //returns user's share (cost/split)
@property (nonatomic) NSInteger split; //how many ppl item was split among

//complex mode (multiple users sharing)
- (NSDecimalNumber *) actualCostForUser:(BillUser *)user;  //cost/#of users if user is in array, else 0
@property (nonatomic, strong) NSArray *users; //array of BillUsers
- (void) removeUser:(BillUser *)user;
- (void) addUser:(BillUser *)user;

//format friendly summary of the item for display ($xx.xx)
- (NSString *)costDisplay;
- (NSString *)costActualDisplay; //use only if simple mode
- (NSString *)costDisplayForUser:(BillUser *)user; //complex mode
@end
