//
//  SplitMyBillAllBillsViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/14/13.
//
//

#import <UIKit/UIKit.h>
#import "Bill.h"

@protocol BillListDelegate
- (Bill *) BillListCreateBill:(id)ListController;
@end

@interface SplitMyBillAllBillsViewController : UIViewController
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id<BillListDelegate> delegate;

@end
