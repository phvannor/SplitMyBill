//
//  SplitMyBillUserOwesTableCellCell.h
//  SplitTheBill
//
//  Created by Phillip Van Nortwick on 5/10/12.
//  Copyright (c) 2012. All rights reserved.
//
//  Table cell for displaying what a user owes as part of the bill
//  Contains spaces for showing the name of a user, his subtotal (including tax), tip,
//  and overall total

#import <UIKit/UIKit.h>

@interface SplitMyBillUserOwesTableCellCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UILabel *subtotal;
@property (nonatomic, weak) IBOutlet UILabel *tip;
@property (nonatomic, weak) IBOutlet UILabel *total;
@end
