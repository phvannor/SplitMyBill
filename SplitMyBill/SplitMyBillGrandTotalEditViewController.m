//
//  SplitMyBillGrandTotalEditViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 6/13/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "SplitMyBillGrandTotalEditViewController.h"
#import "BillLogic.h"

@interface SplitMyBillGrandTotalEditViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIPickerView *totalPicker;
@property (weak, nonatomic) BillLogic *logic;
@property (weak, nonatomic) IBOutlet UIButton *buttonActual;
@property (weak, nonatomic) IBOutlet UIButton *button5;
@property (weak, nonatomic) IBOutlet UIButton *button10;
@property (weak, nonatomic) IBOutlet UIButton *button25;
@property (weak, nonatomic) IBOutlet UIButton *button50;
@property (weak, nonatomic) IBOutlet UIButton *button100;
@end

@implementation SplitMyBillGrandTotalEditViewController
@synthesize label = _label;
@synthesize totalPicker = _totalPicker;
@synthesize logic = _logic;
@synthesize buttonActual = _buttonActual;
@synthesize button5 = _button5;
@synthesize button10 = _button10;
@synthesize button25 = _button25;
@synthesize button50 = _button50;
@synthesize button100 = _button100;

- (IBAction)buttonNavigationBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view
    [self.buttonActual setTitle:[BillLogic formatMoney:[self.logic totalWhenRoundedTo:0]] forState:UIControlStateNormal];
    
    if(![self.logic.total isEqualToNumber:[NSDecimalNumber zero]]) {
        if((self.logic.isTipInDollars && [self.logic.tipInDollars isEqualToNumber:[NSDecimalNumber zero]]) || [self.logic.tip isEqualToNumber:[NSDecimalNumber zero]])
        {
            self.label.text = @"*rounding is disabled when tip is set to 0";
            self.button5.hidden = YES;
            self.button10.hidden = YES;
            self.button25.hidden = YES;
            self.button50.hidden = YES;
            self.button100.hidden = YES;
            return;
        }        
    }

    [TestFlight passCheckpoint:@"TotalRoundOptions"];

    if(self.logic.roundingAmount == 0) [self.buttonActual setHighlighted:YES];
        
    [self.button5 setTitle:[BillLogic formatMoney:[self.logic totalWhenRoundedTo:5]] forState:UIControlStateNormal];    
    if(self.logic.roundingAmount == 5) [self.button5 setHighlighted:YES];

    [self.button10 setTitle:[BillLogic formatMoney:[self.logic totalWhenRoundedTo:10]] forState:UIControlStateNormal];
    if(self.logic.roundingAmount == 10) [self.button10 setHighlighted:YES];

    [self.button25 setTitle:[BillLogic formatMoney:[self.logic totalWhenRoundedTo:25]] forState:UIControlStateNormal];
    if(self.logic.roundingAmount == 25) [self.button25 setHighlighted:YES];

    [self.button50 setTitle:[BillLogic formatMoney:[self.logic totalWhenRoundedTo:50]]forState:UIControlStateNormal];
    if(self.logic.roundingAmount == 50) [self.button50 setHighlighted:YES];

    [self.button100 setTitle:[BillLogic formatMoney:[self.logic totalWhenRoundedTo:100]]forState:UIControlStateNormal];
    if(self.logic.roundingAmount == 100) [self.button100 setHighlighted:YES];    
}

- (void)viewDidUnload
{
    [self setTotalPicker:nil];
    [self setButton5:nil];
    [self setButton10:nil];
    [self setButton25:nil];
    [self setButton50:nil];
    [self setButton100:nil];
    [self setButtonActual:nil];
    [self setLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)buttonPressActual:(id)sender {
    [self closeAndSetRounding:0];    
}
- (IBAction)buttonPress5:(id)sender {
    [self closeAndSetRounding:5];    
}
- (IBAction)buttonPress10:(id)sender {
    [self closeAndSetRounding:10];    
}
- (IBAction)buttonPress25:(id)sender {
    [self closeAndSetRounding:25];    
}
- (IBAction)buttonPress50:(id)sender {
    [self closeAndSetRounding:50];    
}
- (IBAction)buttonPress100:(id)sender {
    [self closeAndSetRounding:100];    
}

- (void)closeAndSetRounding:(NSInteger)roundingAmount {
    [TestFlight passCheckpoint:@"Bill - Set Rounding"];

    self.logic.roundingAmount = roundingAmount;
    [self.navigationController popViewControllerAnimated:YES];
}
@end
