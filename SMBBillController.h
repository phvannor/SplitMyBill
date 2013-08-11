//
//  SMBBillController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/9/13.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"
#import "Bill.h"

@interface SMBBillController : UITabBarController

@property (nonatomic, weak) BillLogic *billlogic;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) Bill *bill;

-(bool) totalIsSimple;
-(bool) discountsPreTax;

@end

