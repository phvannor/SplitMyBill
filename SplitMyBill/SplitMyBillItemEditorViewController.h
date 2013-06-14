//
//  SplitMyBillItemEditorViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BillLogicItem.h"

@class SplitMyBillItemEditorViewController;

@protocol SplitMyBillItemEditorViewControllerDelegate
- (void) ItemEditor:(SplitMyBillItemEditorViewController *)sender userAction:(NSInteger)action;
@end

@interface SplitMyBillItemEditorViewController : UIViewController
@property (nonatomic, weak) IBOutlet id <SplitMyBillItemEditorViewControllerDelegate> delegate;
@property (nonatomic, weak) BillLogicItem *item;
@property (nonatomic, strong) NSArray *userList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak)IBOutlet UILabel *cost;
@end
