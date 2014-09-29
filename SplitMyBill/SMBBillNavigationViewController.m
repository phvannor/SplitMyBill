//
//  SMBBillNavigationViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/21/13.
//
//

#import "SMBBillNavigationViewController.h"
#import "SplitMyBillMainScreenViewController.h"
#import "SplitMyBillDebtFromBillViewController.h"
#import "Debt.h"
#import "Contact.h"
#import "ContactContactInfo.h"
#import <MessageUI/MessageUI.h>
#import "TestFlight.h"

@interface SMBBillNavigationViewController () <UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) bool settingTotalIsSimple;
@property (nonatomic) bool settingDiscountsPreTax;
@property (nonatomic) bool hasTexting;
@property (nonatomic) bool hasEmail;

@end


@implementation SMBBillNavigationViewController

-(void)viewWillDisappear:(BOOL)animated
{
    if (self.bill) {
        // Update bill total
        self.bill.total = [NSNumber numberWithInteger:[[self.billlogic.total decimalNumberByMultiplyingByPowerOf10:2] integerValue]];
        
        // If total is 0 and bill is new, don't save
        if(self.bill.items.count == 0) {
            [self.managedObjectContext deleteObject:self.bill];
        } else {
            [self.managedObjectContext save:nil];
        }
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    
    //load up defaults for the bill
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.settingTotalIsSimple = [defaults boolForKey:@"UserTotalSimple"];
    self.settingDiscountsPreTax = [defaults boolForKey:@"DiscountsPreTax"];
    
    Class classToTest = (NSClassFromString(@"MFMailComposeViewController"));
    if (classToTest != nil) {
        self.hasEmail = [classToTest canSendMail];
    }
    
    classToTest = (NSClassFromString(@"MFMessageComposeViewController"));
    if (classToTest != nil) {
        self.hasTexting = [classToTest canSendText];
    }
}

- (void) addDebt {
    [self performSegueWithIdentifier:@"add debts" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"add debts"])
    {
        SplitMyBillDebtFromBillViewController *vc = segue.destinationViewController;
        vc.billlogic = self.billlogic;
        vc.delegate = self;
    }
}

#pragma mark public setting data
- (bool) totalIsSimple {
    return self.settingTotalIsSimple;
}

- (bool) discountsPreTax {
    return self.settingDiscountsPreTax;
}

#pragma mark actionsheet delegate
- (void) showBillActionsInView:(UIView *)view
{
    UIActionSheet *shareOptions = [[UIActionSheet alloc] initWithTitle:@"Share Bill"
                                                              delegate:self
                                                     cancelButtonTitle:nil
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:nil];
    
    if(self.hasTexting) [shareOptions addButtonWithTitle:@"Text"];
    if(self.hasEmail) [shareOptions addButtonWithTitle:@"Email"];
    
    //check if self present and user count >X;
    NSInteger max = 0;
    if([self.billlogic getSelf]) max = 1;
    if((self.billlogic.userCount > max) && ![self.billlogic.total isEqual:[NSDecimalNumber zero]])
        [shareOptions addButtonWithTitle:@"Add To Debts"];
    
    [shareOptions addButtonWithTitle:@"Cancel"];
    [shareOptions setCancelButtonIndex:(shareOptions.numberOfButtons - 1)];
    
    [shareOptions showInView:view];
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger offset = 0;
    if(self.hasTexting) {
        if (buttonIndex == 0) {
            [self displaySMSComposerSheet];
            return;
        }
    } else {
        offset--;
    }
    
    if(self.hasEmail) {
        if(buttonIndex == 1 + offset) {
            [self displayEmailComposerSheet];
            return;
        }
    } else {
        offset--;
    }
    
    NSInteger max = 0;
    if([self.billlogic getSelf]) max = 1;
    if((self.billlogic.userCount > max) && ![self.billlogic.total isEqual:[NSDecimalNumber zero]]) {
        if(buttonIndex == 2 + offset) {
            [self addDebt];
        }
    } else {
        offset--;
    }
}

- (NSString *)composeMessageShort:(bool)brief {
    NSString *message = @"";
    if(brief) {
        for(BillUser *user in self.billlogic.users) {
            message = [message stringByAppendingFormat:@"%@:%@\n",user.abbreviation, [BillLogic formatMoney:[self.billlogic totalForUser:user]]];
        }
        return message;
    }
    //compex message
    message = @"Our bill:\n";
    NSUInteger count;
    
    for(BillUser *user in self.billlogic.users) {
        message = [message stringByAppendingFormat:@"%@\n",user.name];
        count = 0;
        for(BillLogicItem *item in [self.billlogic itemsForUser:user])
        {
            count++;
            message = [message stringByAppendingFormat:@"   %lu.%@ %@\n", (unsigned long)count,item.name, [item costDisplayForUser:user]];
        }
        message = [message stringByAppendingFormat:@"   owes: %@ + %@ = %@\n",[BillLogic formatMoney:[self.billlogic subtotalForUser:user]],  [BillLogic formatMoney:[self.billlogic tipForUser:user]],  [BillLogic formatMoney:[self.billlogic totalForUser:user]]];
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
    for(BillUser *user in self.billlogic.users) {
        if(user.phone) [recipients addObject:user.phone];
    }
    picker.recipients = [recipients copy];
    
    [self presentViewController:picker animated:YES completion:nil];
}

// Displays an email composition interface inside the application.
-(void)displayEmailComposerSheet
{
    //show a loading icon...
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    NSMutableArray *recipients = [NSMutableArray array];
    for(BillUser *user in self.billlogic.users) {
        if(user.email) [recipients addObject:user.email];
    }
    [picker setToRecipients:[recipients copy]];
    [picker setSubject:@"Bill"];
    [picker setMessageBody:[self composeMessageShort:NO] isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:nil];
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

#pragma mark - Bill Add Debt Delegate
- (void) BillAddDebtDelegate:(id)Editor AndSave:(bool)Save
{
    if(Save) {
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
                
                //blank name and initials
                ContactContactInfo *cinfo = [NSEntityDescription insertNewObjectForEntityForName:@"ContactContactInfo" inManagedObjectContext:self.managedObjectContext];
                contact.contactinfo = cinfo;
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
            debt.amount = [NSNumber numberWithInteger:[amount integerValue]];
            
            //add amount to the corresponding contact
            user.contact.owes = [NSNumber numberWithInteger:([user.contact.owes integerValue] + [amount integerValue])];
        }
        
        NSError *error;
        if(![self.managedObjectContext save:&error]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debt Creation Error" message:@"An error occured while attempting to create debts from this bill" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
            //revert changes
            [self.managedObjectContext rollback];
            return;
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)deleteBill:(id)sender {
    //delete a bill
    [self.managedObjectContext deleteObject:self.bill];
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error - bill deletion %@", [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Deleting Bill" message:@"An error occurred while attempting to delete the bill" delegate:nil cancelButtonTitle:NULL otherButtonTitles:@"OK", nil];
        [alert show];
    }
    self.bill = nil;
}

@end
