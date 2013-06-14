//
//  SplitMyBillUserOwesTableCellCell.m
//  SplitTheBill
//
//  Created by Phillip Van Nortwick on 5/10/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "SplitMyBillUserOwesTableCellCell.h"

@implementation SplitMyBillUserOwesTableCellCell
@synthesize name = _name;
@synthesize subtotal = _subtotal;
@synthesize tip = _tip;
@synthesize total = _total;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
