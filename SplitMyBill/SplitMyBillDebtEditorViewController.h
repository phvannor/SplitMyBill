//
//  SplitMyBillDebtEditorViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/21/12.
//
//

#import <UIKit/UIKit.h>
#import "Debt.h"

@protocol DebtEditorDelegate
- (void) DebtEditor:(id)Editor Close:(bool)SaveChanges;
//- (void) DebtEditorDelete:(id)Editor;
@end

@interface SplitMyBillDebtEditorViewController : UIViewController
@property (nonatomic, weak) Debt *debt;
@property (nonatomic, weak) id delegate;
@end
