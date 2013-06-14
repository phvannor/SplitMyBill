//
//  TipViewController.h
//  SplitMyBill Free
//
//  Created by Phillip Van Nortwick on 4/29/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

@protocol TipViewDataSource
@property (nonatomic, weak) NSDecimalNumber *tipPercent;
@property (nonatomic, weak) NSDecimalNumber *tipAmount;
- (NSDecimalNumber *)totalToTipOn;
- (bool) tipInDollars;
@end

@interface TipViewController : UIViewController

@property (nonatomic, weak) ADBannerView *banner;
@property (weak, nonatomic) IBOutlet UILabel *display;
@property (weak, nonatomic) IBOutlet id <TipViewDataSource> dataSource;
@end
