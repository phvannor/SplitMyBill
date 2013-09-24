//
//  TipViewController.m
//  SplitMyBill Free
//
//  Created by Phillip Van Nortwick on 4/29/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "TipViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TipViewController ()
@property (nonatomic) bool userIsEnteringNumber;
@property (weak, nonatomic) IBOutlet UIButton *buttonDecimal;
@property (weak, nonatomic) IBOutlet UIButton *button15;
@property (weak, nonatomic) IBOutlet UIButton *button18;
@property (weak, nonatomic) IBOutlet UIButton *button20;
@property (nonatomic, strong) NSNumberFormatter *formatter;
@property (nonatomic) NSInteger rawAmountValueInCents;

@property (weak, nonatomic) IBOutlet UILabel *labelWarning;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchDollarPercent;
@property (nonatomic) bool inDollars;
@end

@implementation TipViewController
@synthesize userIsEnteringNumber = _userIsEnteringNumber;
@synthesize buttonDecimal = _buttonDecimal;
@synthesize button15 = _button15;
@synthesize button18 = _button18;
@synthesize button20 = _button20;
@synthesize display = _display;
@synthesize dataSource = _dataSource;
@synthesize banner = _banner;
@synthesize formatter = _formatter;
@synthesize rawAmountValueInCents = _rawAmountValueInCents;
@synthesize labelWarning = _labelWarning;
@synthesize inDollars = _inDollars;

- (void) viewWillDisappear:(BOOL)animated
{
    if(self.inDollars) {
        NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithMantissa:self.rawAmountValueInCents exponent:-2 isNegative:NO];
        self.dataSource.tipAmount = temp;
    } else {
        NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithString:self.display.text];
        self.dataSource.tipPercent = [temp decimalNumberByMultiplyingByPowerOf10:-2];
    }
}

/*
 * Configures form for editing the tip in either dollars or as a percentage
 */
- (void) setupForm:(bool)isPercent {
    self.userIsEnteringNumber = NO;
    
    self.inDollars = !isPercent;
    if(isPercent) {
        [self.switchDollarPercent setSelectedSegmentIndex:1];
        [self.formatter setNumberStyle: NSNumberFormatterDecimalStyle];
        self.buttonDecimal.hidden = NO;
        NSDecimalNumber *value = self.dataSource.tipPercent;
        if(!value) {
            value = [NSDecimalNumber zero];
        }        
        self.display.text = [self.formatter stringFromNumber: [value decimalNumberByMultiplyingByPowerOf10:2]];
        self.display.text = [self.display.text stringByAppendingString:@"%"];
        
        [self.button15 setTitle:@"15%" forState:UIControlStateNormal];
        [self.button18 setTitle:@"18%" forState:UIControlStateNormal];
        [self.button20 setTitle:@"20%" forState:UIControlStateNormal];
        
    } else {
        [self.switchDollarPercent setSelectedSegmentIndex:0];
        [self.formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        self.buttonDecimal.hidden = YES;
        
        //calculate 15, 18, and 20 percent of the total
        NSDecimalNumber *itemTotal = self.dataSource.totalToTipOn;
        [self.button15 setTitle:[self.formatter stringFromNumber:[itemTotal decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:15 exponent:-2 isNegative:NO]]] forState:UIControlStateNormal];
        [self.button18 setTitle:[self.formatter stringFromNumber:[itemTotal decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:18 exponent:-2 isNegative:NO]]] forState:UIControlStateNormal];
        [self.button20 setTitle:[self.formatter stringFromNumber:[itemTotal decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:20 exponent:-2 isNegative:NO]]] forState:UIControlStateNormal];
        
        NSDecimalNumber *tip = self.dataSource.tipAmount;
        self.display.text = [self.formatter stringFromNumber:tip];
        
        //convert back to cents
        self.rawAmountValueInCents = [[tip decimalNumberByMultiplyingByPowerOf10:2] intValue];     
    }
}

- (IBAction)switchMode:(UISegmentedControl *)sender {
    [self setupForm:sender.selectedSegmentIndex == 1];
}

- (IBAction)digitPress:(UIButton *)sender {
    if(self.inDollars) {
        NSInteger newCents = self.rawAmountValueInCents;
        if(self.userIsEnteringNumber) {
            newCents *= 10;
            newCents += [sender.currentTitle intValue];            
        } else {
            newCents = [sender.currentTitle intValue];
        }
        
        // Don't accept if it puts us over max value
        if(newCents > 1000000) {
            return;
        }

        self.rawAmountValueInCents = newCents;        
        NSDecimalNumber *tip = [NSDecimalNumber decimalNumberWithMantissa:self.rawAmountValueInCents exponent:-2 isNegative:NO];
        self.display.text = [self.formatter stringFromNumber:tip];
        self.userIsEnteringNumber = YES;        
        return;
    }
    
    if(self.userIsEnteringNumber) {
        //remove the % and add back in
        NSString *temp = [self.display.text stringByReplacingOccurrencesOfString:@"%" withString:@""];

        if([temp isEqualToString:@"0"]) {
            temp = sender.currentTitle;
        } else {
            temp = [temp stringByAppendingString:sender.currentTitle];
        }

        //check max value
        if([temp doubleValue] >= 1000) {
            return;  //max value of item
        }

        //we only allow up to 3 decimal places
        NSRange range = [temp rangeOfString:@"."];
        if((range.length > 0) & ((self.display.text.length - range.location) > 2)) {
            return;
        }
        
        //less than 3 decimal places, accept number
        self.display.text = [temp stringByAppendingString:@"%"];
    } else {
        self.display.text = [sender.currentTitle stringByAppendingString:@"%"];
    }
    self.userIsEnteringNumber = YES;
}

- (IBAction)decimalPress:(UIButton *)sender {
    NSRange range = [self.display.text rangeOfString:@"."];
    
    if(!self.userIsEnteringNumber) {
        //put 0. into the display
        self.display.text = @"0.%";
        self.userIsEnteringNumber = YES;
    } else if(range.location == NSNotFound) {
        //append a 0
        [self digitPress:sender];        
    }
}

- (IBAction)pressUndo {
    //remove last digit or set back to 0    
    self.userIsEnteringNumber = YES;
    
    if(self.inDollars) {
        self.rawAmountValueInCents /= 10;
        NSDecimalNumber *tip = [NSDecimalNumber decimalNumberWithMantissa:self.rawAmountValueInCents exponent:-2 isNegative:NO];
        self.display.text = [self.formatter stringFromNumber:tip];
        return;
    }
    
    self.display.text= [self.display.text substringToIndex:(self.display.text.length-2)];    
    if([self.display.text doubleValue] == 0) {
        self.display.text = @"0%";
        self.userIsEnteringNumber = NO;
    } else {
        self.display.text = [self.display.text stringByAppendingString:@"%"];
    }
}

- (void) setTipAndClose:(NSString *)tip {
    if(self.inDollars) {
        tip = [tip stringByReplacingOccurrencesOfString:@"$" withString:@""];
        tip = [tip stringByReplacingOccurrencesOfString:@"," withString:@""];
        tip = [tip stringByReplacingOccurrencesOfString:@"." withString:@""];
        self.rawAmountValueInCents = [tip intValue];
    } else {
        self.display.text = tip;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)quickPick15:(UIButton *)sender {
    if(self.inDollars)
        [self setTipAndClose:sender.currentTitle];
    else
        [self setTipAndClose:@"15"];
}

- (IBAction)quickPick18:(UIButton *)sender {
    if(self.inDollars)
        [self setTipAndClose:sender.currentTitle];
    else
        [self setTipAndClose:@"18"];
}

- (IBAction)quickPick20:(UIButton *)sender {
    if(self.inDollars)
        [self setTipAndClose:sender.currentTitle];
    else
        [self setTipAndClose:@"20"];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.formatter = [[NSNumberFormatter alloc] init];
    [self setupForm:!self.dataSource.tipInDollars];
}

- (void)viewDidUnload
{
    [self setFormatter:nil];
    [self setDisplay:nil];
    [self setBanner:nil];
    [self setButtonDecimal:nil];
    [self setButton15:nil];
    [self setButton18:nil];
    [self setButton20:nil];
    [self setLabelWarning:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
