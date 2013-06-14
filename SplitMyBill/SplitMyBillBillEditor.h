//
//  SplitMyBillBillEditor.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/28/13.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"
#import "BillLogicItem.h"

@protocol BillEditorDataSource
@property (nonatomic, weak) BillLogic *logic;
- (bool) totalIsSimple;
- (bool) discountsPreTax;
@end

@protocol BillEditorDelegate
- (bool) showController:(UIViewController *)controller;
- (void) dismissController;
- (void) popController;

- (void) addDebt;
- (void) editItem:(BillLogicItem *)item;
- (void) addItem;
- (void) editTip;
- (void) editTax;
- (void) editTotal;
- (void) viewUser:(BillUser *)user;
@end

@interface SplitMyBillBillEditor : UIView
@property (nonatomic, weak) id<BillEditorDataSource> dataSource;
@property (nonatomic, weak) id<BillEditorDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)actionButtonPress:(id)sender;

- (void) loadData;
- (void) reloadData;
@end
