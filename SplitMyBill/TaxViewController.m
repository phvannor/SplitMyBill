//
//  TaxViewController.m
//  SplitMyBill Free
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "TaxViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TaxViewController ()
@property (nonatomic) bool userIsEnteringNumber;
@property (weak, nonatomic) IBOutlet UIButton *buttonUseDollars;
@property (weak, nonatomic) IBOutlet UIButton *buttonDecimal;
@property (weak, nonatomic) IBOutlet UIButton *buttonZero;
@property (weak, nonatomic) IBOutlet UIButton *buttonDelete;
@property (nonatomic, strong) NSNumberFormatter *formatter;

- (IBAction)buttonNavigationBack:(id)sender;
- (IBAction)buttonSave:(id)sender;
@end

@implementation TaxViewController
@synthesize userIsEnteringNumber = _userIsEnteringNumber;
@synthesize buttonDecimal = _buttonDecimal;
@synthesize buttonZero = _buttonZero;
@synthesize buttonDelete = _buttonDelete;
@synthesize display = _display;
@synthesize dataSource = _dataSource;
@synthesize formatter = _formatter;

- (IBAction)buttonNavigationBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)buttonSave:(id)sender {
    if(self.buttonUseDollars.selected) {
        NSString *temp = [self.display.text stringByReplacingOccurrencesOfString:@"$" withString:@""];
        temp = [temp stringByReplacingOccurrencesOfString:@"," withString:@""];
        temp = [temp stringByReplacingOccurrencesOfString:@"." withString:@""];
        self.dataSource.taxAmount = [NSDecimalNumber decimalNumberWithMantissa:[temp intValue] exponent:-2 isNegative:NO];
    } else {
        NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithString:[self.display.text stringByReplacingOccurrencesOfString:@"%" withString:@""]];
        self.dataSource.taxPercent = [temp decimalNumberByMultiplyingByPowerOf10:-2];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setupForm:(bool)isPercent {
    //if percent, hide the decimal key
    if(isPercent) {
        [self.formatter setNumberStyle: NSNumberFormatterDecimalStyle];
        [UIView animateWithDuration:0.3 animations: ^{
            self.buttonZero.frame = CGRectMake(109, 279, 102, 55);
            self.buttonDecimal.alpha = 1;
        }];
        
        //self.display.text = [self.formatter stringFromNumber: self.dataSource.taxPercent];        
        self.display.text = [self.formatter stringFromNumber: [self.dataSource.taxPercent decimalNumberByMultiplyingByPowerOf10:2]];        
        self.display.text = [self.display.text stringByAppendingString:@"%"];
    } else {
        [self.formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [UIView animateWithDuration:0.3 animations: ^{
            self.buttonDecimal.alpha = 0;
            self.buttonZero.frame = CGRectMake(6, 279, 205, 55);
        }];
        
        self.display.text = [self.formatter stringFromNumber:self.dataSource.taxAmount];
    }
}

// called to switch form from % to $ mode and back again
- (IBAction)switchMode:(UISwitch *)sender {
    self.userIsEnteringNumber = NO;
    [self setupForm:!sender.on];
}

- (IBAction)switchDollars:(UIButton *)sender {
    self.userIsEnteringNumber = NO;
    
    bool temp = sender.selected;
    [self setupForm:temp];
    self.buttonUseDollars.selected = !temp;
}

// called when key is pressed on the keypad
- (IBAction)digitPress:(UIButton *)sender {
    
    if(self.buttonUseDollars.selected) {
        if(self.userIsEnteringNumber) {
            //we assume 4 digit values
            NSString *tempNewValue = [self.display.text stringByReplacingOccurrencesOfString:@"." withString:@""];
            tempNewValue = [tempNewValue stringByReplacingOccurrencesOfString:@"$" withString:@""];
            tempNewValue = [tempNewValue stringByReplacingOccurrencesOfString:@"," withString:@""];
            tempNewValue = [tempNewValue stringByAppendingString:sender.currentTitle];
        
            if([tempNewValue intValue] > 999999) {  //for sanity
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Number" message:@"Tax must be less than $10,000 " delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return;
            }
        
            NSDecimalNumber *newVal = [NSDecimalNumber decimalNumberWithMantissa:[tempNewValue intValue] exponent:-2 isNegative:NO];
        
            self.display.text = [self.formatter stringFromNumber: newVal];
        } else {
            self.display.text = [self.formatter stringFromNumber:[NSDecimalNumber decimalNumberWithMantissa:[sender.currentTitle intValue] exponent:-2 isNegative:NO]];
        }
        
        self.userIsEnteringNumber = YES;
        return;
    }
    
    if(self.userIsEnteringNumber) {
        NSString *tempNewValue = [self.display.text stringByReplacingOccurrencesOfString:@"%" withString:@""];
        
        if([tempNewValue isEqualToString:@"0"]) {
            tempNewValue = sender.currentTitle;
        } else {
            tempNewValue = [tempNewValue stringByAppendingString:sender.currentTitle];
        }
        
        //put a logical limit on the value
        if([tempNewValue doubleValue] >= 100) {
            return;  //max value of item
        }

        NSRange range = [self.display.text rangeOfString:@"."];
        if((range.length > 0) & ((self.display.text.length - range.location) > 4)) {
            return;
        }
        self.dataSource.inDollars = YES;
        self.display.text = [tempNewValue stringByAppendingString:@"%"];
    } else {
        self.dataSource.inDollars = NO;
        self.display.text = [NSString stringWithFormat:@"%@%%",sender.currentTitle];
        self.userIsEnteringNumber = YES;
    }
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

// remove the last character in the display, if non would be left, reset to 0
- (IBAction)pressUndo {
    self.userIsEnteringNumber = YES;    
    if(self.buttonUseDollars.selected) {
        self.display.text= [self.display.text substringToIndex:(self.display.text.length-1)];

        //slide decimal over one place now
        NSString *temp = [self.display.text stringByReplacingOccurrencesOfString:@"$" withString:@""];
        temp = [temp stringByReplacingOccurrencesOfString:@"." withString:@""];
        temp = [temp stringByReplacingOccurrencesOfString:@"," withString:@""];
        if(temp.length == 0) temp = @"0";
        NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithMantissa:[temp intValue] exponent:-2 isNegative:NO];
        self.display.text = [self.formatter stringFromNumber:number];
    } else {
        self.display.text= [self.display.text substringToIndex:(self.display.text.length-2)];
        
        if(self.display.text.length == 0) {
            self.display.text = @"0%";
            self.userIsEnteringNumber = NO;
        } else {
            self.display.text = [self.display.text stringByAppendingString:@"%"];
        }
    }        
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
    
    if(self.dataSource.inDollars) {
        [self setupForm:NO];
        self.buttonUseDollars.selected = YES;
    } else {
        [self setupForm:YES];
        self.buttonUseDollars.selected = NO;
    }
    
    self.buttonUseDollars.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.buttonUseDollars.layer.borderWidth = 1.0f;
}

- (void)viewDidUnload
{  
    [self setFormatter:nil];
    [self setDisplay:nil];
    [self setButtonDecimal:nil];
    [self setButtonZero:nil];
    [self setButtonDelete:nil];
    [self setButtonUseDollars:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
