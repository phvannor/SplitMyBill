//
//  SplitMyBillDebtFromBillViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/22/12.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"

@protocol BillAddDebtDelegate
- (void) BillAddDebtDelegate:(id)Editor AndSave:(bool)Save;
@end

@interface SplitMyBillDebtFromBillViewController : UIViewController
@property (nonatomic, weak) BillLogic *billlogic;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSMutableArray *debtUsers;
@property (nonatomic, strong) NSMutableArray *debtAmounts;
- (NSString *) notes;
@end
