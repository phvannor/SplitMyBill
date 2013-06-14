//
//  SplitMyBillRoundingSettingsViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RoundingViewDataSource
@property NSInteger roundingAmount;
@end

@interface SplitMyBillRoundingSettingsViewController : UIViewController
@property id <RoundingViewDataSource> roundingDataSource;
@end
