//
//  SplitMyBillDebtEditorViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/21/12.
//
//

#import "SplitMyBillDebtEditorViewController.h"
#import "Contact.h"

@interface SplitMyBillDebtEditorViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UISegmentedControl *debtSwitch;
@property (weak, nonatomic) IBOutlet UITextField *textOwed;
@property (weak, nonatomic) IBOutlet UITextField *textNotes;

- (IBAction)buttonCancel:(id)sender;
- (IBAction)buttonSave:(id)sender;
@end

@implementation SplitMyBillDebtEditorViewController
@synthesize debt = _debt;
@synthesize delegate = _delegate;

- (void) closeForm:(bool)Save
{
    [self.view endEditing:YES];
    [self.delegate DebtEditor:self Close:Save];
}

- (IBAction)buttonSave:(id)sender {
    [self closeForm:YES];
}

- (IBAction)buttonCancel:(id)sender {
    [self closeForm:NO];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)pressSwitch:(id)sender {
    //flip value around...
    NSInteger myVal = [self.debt.amount integerValue];
    self.debt.amount = [NSNumber numberWithInt:(myVal*-1)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.labelName.text = self.debt.contact.name;
    if(self.debt.objectID.isTemporaryID) {
        self.navigationItem.title = @"New Debt";
    } else {
        self.navigationItem.title = @"Edit Dept";
        self.textNotes.text = self.debt.note;
        NSInteger amount = [self.debt.amount integerValue];
        if(amount >= 0) {
            [self.debtSwitch setSelectedSegmentIndex:0];
        } else {
            [self.debtSwitch setSelectedSegmentIndex:1];
            amount *= -1;
        }
        self.textOwed.text = [NSString stringWithFormat:@"%.2f",((double)amount)/100];
    }
    
    [self.textOwed becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.tag == 1) {
        //limit numbers to 99,999.99 or less
        NSInteger len = textField.text.length - range.length;
        if(len + string.length > 7) return NO;
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];
    if(textField.tag == 2) {
        //done closes form...
        [self buttonSave:nil];
    }
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
}

//positive -> owes me
//negative -> i owe
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField.tag == 1) {
        //if they deleted everything set debt to a value of 0
        if(textField.text.length == 0)
            textField.text = @"0";
        else if(textField.text.length > 7) {
            textField.text = [textField.text substringToIndex:7];
        }
        
        NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithString:textField.text];
        temp = [temp decimalNumberByMultiplyingByPowerOf10:2];
        
        NSInteger myValue = [temp integerValue];
        //if we owe someone, the value should be negative
        //so flip the sign around on the value they entered
        if([self.debtSwitch selectedSegmentIndex] == 1) {
            myValue *= -1;
        }
        //save the amount back to the server
        self.debt.amount = [NSNumber numberWithInt:myValue];
    } else {
        self.debt.note = textField.text;
    }
}

- (void)viewDidUnload {
    [self setLabelName:nil];
    [self setDebtSwitch:nil];
    [self setTextOwed:nil];
    [self setTextNotes:nil];
    [super viewDidUnload];
}
@end
