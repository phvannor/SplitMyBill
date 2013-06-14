//
//  SplitMyBillUserDetailViewController.h
//  SplitTheBill
//
//  Created by Phillip Van Nortwick on 5/5/12.
//  Copyright (c) 2012. All rights reserved.
//
//  Displays a detailed listing of what a user owes on the bill
//  Including an item by item breakdown

#import <UIKit/UIKit.h>
#import "BillUser.h"
#import "BillLogic.h"

@interface SplitMyBillUserDetailViewController : UIViewController
@property (nonatomic, weak) BillUser *user;
@property (nonatomic, weak) BillLogic *logic;
@property (weak, nonatomic) IBOutlet UILabel *userTotal;
@property (weak, nonatomic) IBOutlet UILabel *userSubtotal;
@property (weak, nonatomic) IBOutlet UILabel *userTip;
@property (weak, nonatomic) IBOutlet UILabel *userTax;
@end
