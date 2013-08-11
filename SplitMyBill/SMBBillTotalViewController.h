//
//  SMBBillTotalViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/10/13.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"

@interface SMBBillTotalViewController : UITableViewController
@property (nonatomic, weak) BillLogic *logic;
@end
