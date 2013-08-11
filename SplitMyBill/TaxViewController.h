//
//  TaxViewController.h
//  SplitMyBill Free
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//
//  Shows the tax editor
//  User can edit the tax as either a percent or in dollars

#import <UIKit/UIKit.h>

@protocol TaxViewDataSource
@property (nonatomic, weak) NSDecimalNumber *taxPercent;
@property (nonatomic, weak) NSDecimalNumber *taxAmount;
- (bool) inDollars;
@end

@interface TaxViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *display;
@property (weak, nonatomic) IBOutlet id <TaxViewDataSource> dataSource;
@end
