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
@property (weak, nonatomic) IBOutlet UITextField *display2;
@property (weak, nonatomic) IBOutlet UIButton *buttonDecimal;
@property (weak, nonatomic) IBOutlet UIButton *buttonZero;
@property (weak, nonatomic) IBOutlet UIButton *button15;
@property (weak, nonatomic) IBOutlet UIButton *button18;
@property (weak, nonatomic) IBOutlet UIButton *button20;
@property (nonatomic, strong) NSNumberFormatter *formatter;
@property (nonatomic) NSInteger rawAmountValueInCents;
@property (weak, nonatomic) IBOutlet UILabel *labelWarning;
@property (weak, nonatomic) IBOutlet UIButton *buttonUseDollars;

- (IBAction)buttonSave:(id)sender;
- (IBAction)buttonNavigationBack:(id)sender;
@end

@implementation TipViewController
@synthesize userIsEnteringNumber = _userIsEnteringNumber;
@synthesize display2 = _display2;
@synthesize buttonDecimal = _buttonDecimal;
@synthesize buttonZero = _buttonZero;
@synthesize button15 = _button15;
@synthesize button18 = _button18;
@synthesize button20 = _button20;
@synthesize display = _display;
@synthesize dataSource = _dataSource;
@synthesize banner = _banner;
@synthesize formatter = _formatter;
@synthesize rawAmountValueInCents = _rawAmountValueInCents;
@synthesize labelWarning = _labelWarning;

- (IBAction)buttonNavigationBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)buttonSave:(id)sender {
    if(self.buttonUseDollars.selected) {
        NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithMantissa:self.rawAmountValueInCents exponent:-2 isNegative:NO];
        self.dataSource.tipAmount = temp;
    } else {
        NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithString:self.display.text];
        self.dataSource.tipPercent = [temp decimalNumberByMultiplyingByPowerOf10:-2];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setupForm:(bool)isPercent {
    self.userIsEnteringNumber = NO;
    
    if(isPercent) {
        [self.formatter setNumberStyle: NSNumberFormatterDecimalStyle];
        [UIView animateWithDuration:0.3 animations: ^{
            self.buttonZero.frame = CGRectMake(self.button18.frame.origin.x, 340, 102, 55);
            self.buttonDecimal.alpha = 1;
            [self.button15 setTitle:@"15%" forState:UIControlStateNormal];
            [self.button18 setTitle:@"18%" forState:UIControlStateNormal];
            [self.button20 setTitle:@"20%" forState:UIControlStateNormal];
        }];

        self.display.text = [self.formatter stringFromNumber: [self.dataSource.tipPercent decimalNumberByMultiplyingByPowerOf10:2]];
        self.display.text = [self.display.text stringByAppendingString:@"%"];
        
    } else {
        [self.formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [UIView animateWithDuration:0.3 animations: ^{        
            self.buttonDecimal.alpha = 0;
            self.buttonZero.frame = CGRectMake(self.button15.frame.origin.x, 340, 205, 55);
            //calculate 15, 18, and 20 percent of the total
            NSDecimalNumber *itemTotal = self.dataSource.totalToTipOn;
            [self.button15 setTitle:[self.formatter stringFromNumber:[itemTotal decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:15 exponent:-2 isNegative:NO]]] forState:UIControlStateNormal];
            [self.button18 setTitle:[self.formatter stringFromNumber:[itemTotal decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:18 exponent:-2 isNegative:NO]]] forState:UIControlStateNormal];
            [self.button20 setTitle:[self.formatter stringFromNumber:[itemTotal decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:20 exponent:-2 isNegative:NO]]] forState:UIControlStateNormal];
        }];
        
        NSDecimalNumber *tip = self.dataSource.tipAmount;
        self.display.text = [self.formatter stringFromNumber:tip];        
        //convert back to cents
        self.rawAmountValueInCents = [[tip decimalNumberByMultiplyingByPowerOf10:2] intValue];     
    }
}

- (IBAction)useDollars:(UIButton *)sender {
    bool temp = sender.selected;
    [self setupForm:temp];
    [sender setSelected:!temp];
}


- (IBAction)digitPress:(UIButton *)sender {
    if(self.buttonUseDollars.selected) {
        NSInteger newCents = self.rawAmountValueInCents;
        if(self.userIsEnteringNumber) {
            newCents *= 10;
            newCents += [sender.currentTitle intValue];            
        } else {
            newCents = [sender.currentTitle intValue];
        }
        
        if(newCents > 1000000) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Tip" message:@"Tip cannot exceed $10,000" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
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
    
    if(self.buttonUseDollars.selected) {
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
    if(self.buttonUseDollars.selected) {
        tip = [tip stringByReplacingOccurrencesOfString:@"$" withString:@""];
        tip = [tip stringByReplacingOccurrencesOfString:@"," withString:@""];
        tip = [tip stringByReplacingOccurrencesOfString:@"." withString:@""];
        self.rawAmountValueInCents = [tip intValue];
    } else {
        self.display.text = tip;
    }
    
    [self buttonSave:nil];
}

- (IBAction)quickPick15:(UIButton *)sender {
    if(self.buttonUseDollars.selected)
        [self setTipAndClose:sender.currentTitle];
    else
        [self setTipAndClose:@"15"];
}

- (IBAction)quickPick18:(UIButton *)sender {
    if(self.buttonUseDollars.selected)
        [self setTipAndClose:sender.currentTitle];
    else
        [self setTipAndClose:@"18"];
}

- (IBAction)quickPick20:(UIButton *)sender {
    if(self.buttonUseDollars.selected)
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
    self.buttonUseDollars.selected = self.dataSource.tipInDollars;
    
    [self setupForm:!self.dataSource.tipInDollars];
    
    self.buttonUseDollars.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.buttonUseDollars.layer.borderWidth = 1.0f;
}

- (void)viewDidUnload
{
    [self setFormatter:nil];
    [self setDisplay:nil];
    [self setBanner:nil];
    [self setButtonDecimal:nil];
    [self setButtonZero:nil];
    [self setButton15:nil];
    [self setButton18:nil];
    [self setButton20:nil];
    [self setLabelWarning:nil];
    [self setButtonUseDollars:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
