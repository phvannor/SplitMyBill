///Users/pvannor/xcode/SplitTheBill/SplitMyBill/SplitMyBillEditorViewController.h
//  SplitMyBillEditorViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/17/13.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"
#import "Bill.h"

@interface SplitMyBillEditorViewController : UIViewController

@property (nonatomic, weak) BillLogic *billlogic;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) Bill *bill;

@end
