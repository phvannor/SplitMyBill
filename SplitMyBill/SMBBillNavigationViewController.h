//
//  SMBBillNavigationViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/21/13.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"
#import "Bill.h"

@interface SMBBillNavigationViewController : UINavigationController

@property (nonatomic, weak) BillLogic *billlogic;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) Bill *bill;

-(bool) totalIsSimple;
-(bool) discountsPreTax;

- (void) showBillActionsInView:(UIView *)view;

@end
