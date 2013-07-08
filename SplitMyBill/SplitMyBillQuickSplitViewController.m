//
//  SplitMyBillQuickSplitViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 10/4/12.
//
//

#import "SplitMyBillQuickSplitViewController.h"
#import "BillLogic.h"
#import "Contact.h"
#import "ContactContactInfo.h"
#import "SplitMyBillDebtFromBillViewController.h"
#import "Debt.h"
#import <AddressBookUI/AddressBookUI.h>
#import "SplitMyBillContactEditorViewController.h"
#import <MessageUI/MessageUI.h>
#import "TestFlight.h"
#import <QuartzCore/QuartzCore.h>
#import "SplitMyBillPartySelection.h"

const NSInteger EDITING_SUBTOTAL = 1;
const NSInteger EDITING_TAX = 2;
const NSInteger EDITING_TIP = 3;

const NSInteger SECTION_SELF = 0;
const NSInteger SECTION_CONTACTS = 1;
const NSInteger SECTION_GENERICS = 2;

@interface SplitMyBillQuickSplitViewController () <NSDecimalNumberBehaviors, UIActionSheetDelegate, BillAddDebtDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, PartySelectionDataSource, PartySelectionDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonActions;
@property (weak, nonatomic) IBOutlet UIButton *buttonSubtotal;
@property (weak, nonatomic) IBOutlet UIButton *buttonTax;
@property (weak, nonatomic) IBOutlet UIButton *buttonTip;
@property (nonatomic) NSInteger editing;
@property (weak, nonatomic) IBOutlet UIView *keyboard;
@property (weak, nonatomic) IBOutlet UILabel *price;

@property (nonatomic) NSDecimalNumber *tax;
- (IBAction)buttonPress:(UIButton *)sender;
- (IBAction)quickPick:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;
@property (nonatomic) bool isTyping;
@property (nonatomic, strong) NSIndexPath *editPath;
@property (nonatomic, strong) BillUser *editUser;
@property (nonatomic, strong) Contact *editContact;
@property (nonatomic) bool hasTexting;
@property (nonatomic) bool hasEmail;
@property (weak, nonatomic) IBOutlet UILabel *labelTotal;
@property (nonatomic, weak) IBOutlet UIView *partyWin;
- (IBAction)pressAction:(id)sender;

//rounding logic
//if tip is explicitly set to 0 rounding should be disabled
//Else round to default.
//Rounding options:
//-all users equal
//-all user totals rounded
//-final total rounded
@property (nonatomic) NSString *tipMode;

//menu related properties
@property (weak, nonatomic) IBOutlet UIView *billView;
@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIButton *buttonHideRight;
- (IBAction)showMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *buttonCamera;
@property (weak, nonatomic) IBOutlet UILabel *creationDate;
@property (weak, nonatomic) IBOutlet UITextView *memo;
@property (weak, nonatomic) IBOutlet UIImageView *billImage;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;

@end

@implementation SplitMyBillQuickSplitViewController
@synthesize logic = _logic;
@synthesize editing = _editing;
@synthesize tax = _tax;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize isTyping = _isTyping;
@synthesize editPath = _editPath;
@synthesize editUser = _editUser;
@synthesize editContact = _editContact;
@synthesize hasEmail = _hasEmail;
@synthesize tipMode = _tipMode;
@synthesize hasTexting = _hasTexting;

- (IBAction)buttonNavigationBack {
    [self showMenu:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"add debts"]) {
        [segue.destinationViewController setBilllogic:self.logic];
        [segue.destinationViewController setDelegate:self];
    } else if([segue.identifier isEqualToString:@"edit user"]) {
        if(self.editContact) {
            [segue.destinationViewController setContact:self.editContact];
            [segue.destinationViewController setDelegate: self.partyWin];
        } else {
            [(SplitMyBillContactEditorViewController *)segue.destinationViewController setUser:self.editUser];
            [segue.destinationViewController setDelegate: self.partyWin];
        }
    }
}

- (void) keyboardHelper:(UIButton *)sender {
    self.buttonSubtotal.selected = NO;
    self.buttonTax.selected = NO;
    self.buttonTip.selected = NO;
    self.isTyping = NO;
    
    self.buttonTax.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:0.5f].CGColor;
    self.buttonTip.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:0.5f].CGColor;
    self.buttonSubtotal.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:0.5f].CGColor;
    
    if(sender) {
        sender.layer.borderColor = [UIColor colorWithRed:0.19f green:0.31f blue:0.9f alpha:0.62f].CGColor;
        
        [sender setSelected:YES];        
        // Fade out the view right away
        [UIView animateWithDuration:0.4
                              delay: 0.0
                            options: UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.keyboard.frame = CGRectMake(0, self.view.frame.size.height - 226, self.view.frame.size.width, 226);                        
                         }
                         completion:nil];
        UIButton *btn;
        switch (sender.tag) {
            case 1:
                [[self.keyboard viewWithTag:12] setHidden:YES];
                [[self.keyboard viewWithTag:13] setHidden:YES];
                [[self.keyboard viewWithTag:14] setHidden:YES];
                break;
                
            case 2:
                btn = (UIButton *)[self.keyboard viewWithTag:12];
                [btn setHidden:NO];
                [btn setTitle:[BillLogic formatTip:self.tax] forState:UIControlStateNormal];
                //use tax from settings
                [[self.keyboard viewWithTag:13] setHidden:YES];
                [[self.keyboard viewWithTag:14] setHidden:YES];
                break;
                
            case 3:
                btn = (UIButton *)[self.keyboard viewWithTag:12];
                btn.hidden = NO;
                [btn setTitle:@"15%" forState:UIControlStateNormal];
                
                [[self.keyboard viewWithTag:13] setHidden:NO];
                [[self.keyboard viewWithTag:14] setHidden:NO];
                break;
                
            default:
                break;
        }
    } else {
        [UIView animateWithDuration:0.4
                              delay: 0.0
                            options: UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.keyboard.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 0);
                             ///self.table.frame = CGRectMake(98,146,221,(self.view.frame.size.height - 146 - 46));
                         }
                         completion:nil];
        
        self.editing = 0;
    }
}

- (IBAction)quickPick:(UIButton *)sender {
    self.isTyping = NO;
    if(self.editing == EDITING_TAX) {
        self.logic.tax = self.tax;
        [self updateFields];
        return;
    }
    
    if(self.editing == EDITING_TIP) {
        switch (sender.tag) {
            case 12:
                self.logic.tip = [NSDecimalNumber decimalNumberWithString:@"0.15"];
                break;
            case 13:
                self.logic.tip = [NSDecimalNumber decimalNumberWithString:@"0.18"];
                break;
            case 14:
                self.logic.tip = [NSDecimalNumber decimalNumberWithString:@"0.20"];
                break;
                
            default:
                break;
        }
    }
    
    [self updateFields];
}

- (IBAction)pushSubtotal:(UIButton *)sender {
    self.editing = EDITING_SUBTOTAL;
    [self keyboardHelper:sender];
}
- (IBAction)pushTax:(UIButton *)sender {
    self.editing = EDITING_TAX;
    [self keyboardHelper:sender];
}
- (IBAction)pushTip:(UIButton *)sender {
    self.editing = EDITING_TIP;
    [self keyboardHelper:sender];
}
- (IBAction)pushTotal:(UIButton *)sender {
    self.editing = 0;
    [self keyboardHelper:sender];
}

- (void) updateFields
{
    [self.buttonSubtotal setTitle:[BillLogic formatMoney:[self.logic itemTotal]] forState:UIControlStateNormal];
    [self.buttonTax setTitle:[BillLogic formatMoney:self.logic.taxInDollars] forState:UIControlStateNormal];
    [self.buttonTip setTitle:[BillLogic formatMoney:self.logic.tipInDollars] forState:UIControlStateNormal];
    self.labelTotal.text = [BillLogic formatMoney:self.logic.total];
    
    //update user cost as well...
    if(self.logic.users.count == 0) {
        self.price.text = @"--";
        self.buttonActions.enabled = NO;
    } else {
        self.price.text = [BillLogic formatMoney:[self.logic totalForUser:[self.logic.users objectAtIndex:0]]];
        self.buttonActions.enabled = YES;
    }
}

- (NSDecimalNumber *) removeDigitTaxOrTip:(NSDecimalNumber *)rawValue
{
    //remove one digit and round to 2 decimal places
    rawValue = [rawValue decimalNumberByMultiplyingByPowerOf10:-1 withBehavior:self];
    
    return rawValue;
}

- (NSDecimalNumber *) editTaxOrTip:(NSDecimalNumber *)rawValue inDollars:(bool)inDollars addAmount:(NSInteger)amount
{
    if(self.isTyping) {
        rawValue = [rawValue decimalNumberByMultiplyingByPowerOf10:1];
    
        rawValue = [rawValue decimalNumberByAdding:[NSDecimalNumber decimalNumberWithMantissa:amount exponent:-2 isNegative:NO]];
    } else {
        rawValue = [NSDecimalNumber decimalNumberWithMantissa:amount exponent:-2 isNegative:NO];
    }
    self.isTyping = YES;
    return rawValue;
}

- (IBAction)pushNext:(id)sender {
    self.editing += 1;
    if(self.editing > EDITING_TIP)
    {
        self.editing = 0;
        [self keyboardHelper:nil];
    }
    
    switch (self.editing) {
        case EDITING_SUBTOTAL:
            [self keyboardHelper:self.buttonSubtotal];
            break;
        case EDITING_TAX:
            [self keyboardHelper:self.buttonTax];
            break;
        case EDITING_TIP:
            [self keyboardHelper:self.buttonTip];
            break;
            
        default:
            break;
    }
}

- (IBAction)buttonclose:(id)sender {
    [self keyboardHelper:nil];
}

- (IBAction)buttonBack:(id)sender {
    if(self.editing == EDITING_SUBTOTAL) {
        if(self.logic.items.count == 0)
            return;
        
        BillLogicItem *item = [self.logic.items objectAtIndex:0];
        item.cost /= 10;
    } else if(self.editing == EDITING_TAX){
        self.logic.taxInDollars = [self removeDigitTaxOrTip:self.logic.taxInDollars];
    } else if(self.editing == EDITING_TIP){
        self.logic.tipInDollars = [self removeDigitTaxOrTip:self.logic.tipInDollars];
    }
    self.isTyping = YES;
    [self updateFields];
}

- (IBAction)buttonPress:(UIButton *)sender
{
    NSInteger value = (sender.tag - 1);
    if(self.editing == EDITING_SUBTOTAL) {
        BillLogicItem *item = [[self.logic items] objectAtIndex:0];
        
        if(self.isTyping) {
            NSInteger newCost = item.cost * 10 + value;
            if(newCost >= 100000)
                return;
            
            item.cost = newCost;
        }
        else
            item.cost = value;
        
    } else if(self.editing == EDITING_TAX) {
        self.logic.taxInDollars = [self editTaxOrTip:[self.logic taxInDollars] inDollars:NO addAmount:value];
        
    } else if(self.editing == EDITING_TIP) {
        
        self.logic.tipInDollars = [self editTaxOrTip:[self.logic tipInDollars] inDollars:NO addAmount:value];
    }
    
    self.isTyping = YES;
    [self updateFields];
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
    
    //begin loading up our saved contacts
    
    //determine if they can send text and/or mail
    Class classToTest = (NSClassFromString(@"MFMailComposeViewController"));
    if (classToTest != nil) {
        self.hasEmail = [classToTest canSendMail];
    }
    classToTest = (NSClassFromString(@"MFMessageComposeViewController"));
    if (classToTest != nil) {
        // Check whether the current device is configured for sending SMS messages
        self.hasTexting = [classToTest canSendText];
    }

    //load in the party selection...
    SplitMyBillPartySelection *partyWin = (SplitMyBillPartySelection *)self.partyWin;
    partyWin.dataSource = self;
    partyWin.delegate = self;
    if(!partyWin.loadData) {
        //throw error of some kind...?
    }
    
    self.buttonTip.layer.borderWidth = 1.0f;
    self.buttonTip.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:0.5f].CGColor;
    //self.buttonTip.layer.cornerRadius = 8.0f;

    self.buttonTax.layer.borderWidth = 1.0f;
    self.buttonTax.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:0.5f].CGColor;
    //self.buttonTax.layer.cornerRadius = 8.0f;
    
    self.buttonSubtotal.layer.borderWidth = 1.0f;
    self.buttonSubtotal.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:0.5f].CGColor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *string = [defaults objectForKey:@"taxRate"];
    if(!string) string = @"0";
    self.tax = [NSDecimalNumber decimalNumberWithString:string];
    self.editing = EDITING_SUBTOTAL;
    //self.tipMode = [defaults objectForKey:@"round"];
    
    NSNumber *current = self.logic.bill.rounding;
    if([current isEqualToNumber:[NSNumber numberWithInt:0]])
    {
        current = [NSNumber numberWithInt:1];
    }
    [self updateFields];
    
    if([self.logic.bill.total integerValue] != 0) {
        [self keyboardHelper:nil];
    } else {
        [self keyboardHelper:self.buttonSubtotal];
    }

    if(self.logic.bill.image) {
        UIImage *image = [UIImage imageWithData:self.logic.bill.image];
        [self.billImage setImage:image];
    }
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    self.creationDate.text = [NSString stringWithFormat:@"Created: %@",[dateFormatter stringFromDate:self.logic.bill.created]];
    
    if(self.logic.bill.title) {
        self.memo.text = self.logic.bill.title;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [(SplitMyBillPartySelection *)self.partyWin reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)viewDidUnload {
    [self setButtonSubtotal:nil];
    [self setButtonTax:nil];
    [self setButtonTip:nil];
    [self setKeyboard:nil];
    [self setPrice:nil];
    [self setButtonNext:nil];
    [self setButtonActions:nil];
    [self setLabelTotal:nil];
    [super viewDidUnload];
}


- (BillUser *)makeUserSelfwithDefaults:(NSUserDefaults *)defaults
{
    if(!defaults)
        defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *defaultUser = [defaults objectForKey:@"default user"];
    BillUser *user;
    if(!defaultUser) {
        user = [[BillUser alloc] initWithName:@"Me" andAbbreviation:@"ME"];
    } else {
        user = [NSKeyedUnarchiver unarchiveObjectWithData:defaultUser];
    }
    user.isSelf = YES;
    
    return user;
}

#pragma mark - NSDecimalNumbers
- (NSRoundingMode)roundingMode
{
    return NSRoundDown;
}

- (short)scale
{
    return 2;
}

- (NSDecimalNumber *)exceptionDuringOperation:(SEL)method error:(NSCalculationError)error leftOperand:(NSDecimalNumber *)leftOperand rightOperand:(NSDecimalNumber *)rightOperand
{
    return nil;
}

#pragma mark - Actions
- (IBAction)pressAction:(id)sender {
    [self keyboardHelper:nil];
    
    //show action sheet (email, text, add to debts)
    UIActionSheet *shareOptions = [[UIActionSheet alloc] initWithTitle:@"Share Bill" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if(self.hasTexting) [shareOptions addButtonWithTitle:@"Text"];
    if(self.hasEmail) [shareOptions addButtonWithTitle:@"Email"];
    
    //check if self present and user count >X;
    if([self showAddToDebts])
        [shareOptions addButtonWithTitle:@"Add To Debts"];
    
    [shareOptions addButtonWithTitle:@"Cancel"];
    [shareOptions setCancelButtonIndex:(shareOptions.numberOfButtons - 1)];

    [shareOptions showInView:self.view];
}

#pragma mark UIActionSheetDelegate
- (bool) showAddToDebts
{
    NSInteger max = 0;
    if([self.logic getSelf]) max = 1;
    if(self.logic.users.count <= max)
        return NO;
    
    if([self.logic.total isEqual:[NSDecimalNumber zero]])
        return NO;
    
    return YES;
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger offset = 0;
    if(!self.hasEmail) offset--;
    if(buttonIndex == 0 + offset) {
        [self displayEmailComposerSheet];
        return;
    }
    
    if(!self.hasTexting) offset--;
    if(buttonIndex == 1 + offset) {
        [self displaySMSComposerSheet];
        return;
    }
    
    if(![self showAddToDebts])
        offset--;
    if(buttonIndex == 2 + offset) {
        [self performSegueWithIdentifier:@"add debts" sender:self];
        return;
    }
}

#pragma mark - AddDebtDelegate
- (void) BillAddDebtDelegate:(id)Editor CloseForUser:(BillUser *)user AndSave:(bool)Save
{
    if(Save) {
        bool hadGenerics = (self.logic.numberOfGenericUsers > 0);
        
        //create debts for each option
        SplitMyBillDebtFromBillViewController *debtScreen = (SplitMyBillDebtFromBillViewController *)Editor;
        
        BillUser *user;
        for(NSUInteger i=0; i<debtScreen.debtUsers.count;i++)
        {
            user = [debtScreen.debtUsers objectAtIndex:i];
            if (!user.contact) {
                //create a contact record for this user
                Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.managedObjectContext];
                
                contact.name = user.name;
                contact.initials = user.abbreviation;
                ContactContactInfo *contactinfo = [NSEntityDescription insertNewObjectForEntityForName:@"ContactContactInfo" inManagedObjectContext:self.managedObjectContext];
                contact.contactinfo = contactinfo;
                contact.contactinfo.email = user.email;
                contact.contactinfo.phone = user.phone;
                user.contact = contact;
            }
            Debt *debt = [NSEntityDescription insertNewObjectForEntityForName:@"Debt" inManagedObjectContext:self.managedObjectContext];
            
            debt.created = [[NSDate alloc] init];
            debt.contact = user.contact;
            debt.note = debtScreen.notes;
            NSDecimalNumber *amount = [debtScreen.debtAmounts objectAtIndex:i];
            amount = [amount decimalNumberByMultiplyingByPowerOf10:2];
            debt.amount = [NSNumber numberWithInt:[amount integerValue]];
            
            //add amount to the corresponding contact
            user.contact.owes = [NSNumber numberWithInt:([user.contact.owes integerValue] + [amount integerValue])];
        }
        if(hadGenerics) {
            ///if(self.logic.numberOfGenericUsers == 0)
                ///[self.table deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:NO];
        }
        
        NSError *error;
        if(![self.managedObjectContext save:&error]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debt Creation Error" message:@"An error occured while attempting to create debts from this bill" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
            //revert changes
            [self.managedObjectContext rollback];
            return;
        }
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Email and Text
- (NSString *)composeMessageShort:(bool)brief {
    NSString *message = @"";
    if(brief) {
        for(BillUser *user in self.logic.users) {
            message = [message stringByAppendingFormat:@"%@: %@\n",user.abbreviation, [BillLogic formatMoney:[self.logic  totalForUser:user]]];
        }
        return message;
    }
    
    //complex message
    message = @"Our Bill:\n";
    for(BillUser *user in self.logic.users) {
        message = [message stringByAppendingFormat:@"%@: %@\n",user.name, [BillLogic formatMoney:[self.logic  totalForUser:user]]];
    }
    
    return message;
}

// Displays an SMS composition interface inside the application.
-(void)displaySMSComposerSheet
{
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
    picker.body = [self composeMessageShort:YES];
    NSMutableArray *recipients = [NSMutableArray array];
    for(BillUser *user in self.logic.users) {
        if(user.phone) [recipients addObject:user.phone];
    }
    picker.recipients = [recipients copy];
    [self presentViewController:picker animated:YES completion:NULL];
    //[self presentModalViewController:picker animated:YES];
}

// Displays an email composition interface inside the application.
-(void)displayEmailComposerSheet
{
    //show a loading icon...
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    NSMutableArray *recipients = [NSMutableArray array];
    for(BillUser *user in self.logic.users) {
        if(user.email) [recipients addObject:user.email];
    }
    [picker setToRecipients:[recipients copy]];
    [picker setSubject:@"Bill"];
    [picker setMessageBody:[self composeMessageShort:NO] isHTML:NO];
    
    //[self presentModalViewController:picker animated:YES];
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    if(result == MessageComposeResultSent)
        [TestFlight passCheckpoint:@"Share - Email Sent"];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if(result == MFMailComposeResultSent)
        [TestFlight passCheckpoint:@"Share - SMS Sent"];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - PartySelectionDataSource
/*
 @property (nonatomic, weak) BillLogic *logic;
 @property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
 */
//@property (nonatomic, weak) BillLogic *logic;
//@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext

#pragma mark - PartySelectionDelegate
- (bool) editUser:(BillUser *)user {
    self.editContact = nil;
    self.editUser = user;
    [self performSegueWithIdentifier:@"edit user" sender:self];
    return YES;
}

- (bool) editContact:(Contact *)contact {
    self.editUser = nil;
    self.editContact = contact;
    [self performSegueWithIdentifier:@"edit user" sender:self];
    return YES;
}

- (bool) showController:(UIViewController *)controller {
    [self presentViewController:controller animated:YES completion:NULL];
    return YES;
}

- (void) removeController
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) popController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) dismissController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) usersChanged:(bool)added {
    [self keyboardHelper:nil];
    [self updateFields];
}

//menu controls...
- (IBAction)showMenu:(id)sender {
    
    if(self.menuView.frame.origin.x < 0) {
        self.menuView.hidden = NO;
        [UIView animateWithDuration:0.25
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.menuView.frame = CGRectMake(0, 0, self.menuView.frame.size.width, self.menuView.frame.size.height);
                             
                             self.billView.frame = CGRectMake(270,0,self.billView.frame.size.width, self.billView.frame.size.height);
                         }
                         completion:^(BOOL finished) {
                             self.buttonHideRight.hidden = NO;
                         }];
        
    } else {
        self.buttonHideRight.hidden = YES;
        [UIView animateWithDuration:0.25
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.menuView.frame = CGRectMake(-1 *self.menuView.frame.size.width, 0, self.menuView.frame.size.width, self.menuView.frame.size.height);
                             
                             self.billView.frame = CGRectMake(0,0,self.billView.frame.size.width, self.billView.frame.size.height);
                             
                         }
                         completion:^(BOOL finished) {
                             self.menuView.hidden = YES;
                         }];
    }
}

- (IBAction)buttonMenuClose:(id)sender {
    if(self.logic.bill) {
        //close UI
        self.logic.bill.total = [NSNumber numberWithInteger:[[self.logic.total decimalNumberByMultiplyingByPowerOf10:2] integerValue]];
        
        NSError *error;
        if(![self.managedObjectContext save:&error]) {
            NSLog(@"Error - bill close %@", [error localizedDescription]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Closing Bill" message:@"An error occurred while attempting to update the bill's total" delegate:nil cancelButtonTitle:NULL otherButtonTitles:@"OK", nil];
            [alert show];
            
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)buttonMenuDelete:(id)sender {
    //delete a bill
    [self.managedObjectContext deleteObject:self.logic.bill];
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error - bill deletion %@", [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Deleting Bill" message:@"An error occurred while attempting to delete the bill" delegate:nil cancelButtonTitle:NULL otherButtonTitles:@"OK", nil];
        [alert show];
    }

    [self.navigationController popViewControllerAnimated:YES];    
}

- (IBAction)buttonMenuCamera:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        return;
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Displays a control that allows the user to choose picture or
    // movie capture, if both are available:
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = self;
    
    [self presentModalViewController:cameraUI animated:YES];
    
    return;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissModalViewControllerAnimated:YES];
    
    //store the file
    UIImage *originalImage; //, *editedImage, *imageToSave;
    originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Save the new image (original or edited) to the Camera Roll
    //UIImageWriteToSavedPhotosAlbum (imageToSave, nil, nil , nil);
    self.logic.bill.image = UIImageJPEGRepresentation(originalImage, 1.0f);
    NSError *error;
    if(![self.managedObjectContext save:&error]) {
        //throw error...
        
    }
    
    //store image as visible...
    self.billImage.image = originalImage;
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

//text view...
- (void) textViewDidEndEditing:(UITextView *)textView {
    //clean up text at all here...
    self.logic.bill.title = self.memo.text;
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]){
        [textView resignFirstResponder];
        return NO;
    }else{
        return YES;
    }
}
@end
