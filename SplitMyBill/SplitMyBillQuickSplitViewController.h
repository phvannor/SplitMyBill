//
//  SplitMyBillQuickSplitViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 10/4/12.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"
@interface SplitMyBillQuickSplitViewController : UIViewController
@property (nonatomic, weak) BillLogic *logic;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@end
