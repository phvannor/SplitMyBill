//
//  SplitMyBillEditorViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/17/13.
//
//

#import "SplitMyBillEditorViewController.h"
#import "SplitMyBillPartySelection.h"
#import "SplitMyBillContactEditorViewController.h"
#import "SplitMyBillBillEditor.h"
#import "SplitMyBillItemEditorViewController.h"
#import "TaxViewController.h"
#import "TipViewController.h"
#import "SplitMyBillDebtFromBillViewController.h"
#import "Debt.h"
#import "SplitMyBillMainScreenViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <QuartzCore/QuartzCore.h>

//#import "SplitMyBillUserDetailViewController.h"
//#import "SplitMyBillUserOwesTableCellCell.h"
//#import "BillUser.h"

@interface SplitMyBillEditorViewController () <PartySelectionDataSource, PartySelectionDelegate, BillEditorDataSource, BillEditorDelegate, SplitMyBillItemEditorViewControllerDelegate, TipViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate>

//menu related properties
@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIButton *buttonHideRight;
- (IBAction)showMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *buttonCamera;
@property (weak, nonatomic) IBOutlet UILabel *creationDate;
@property (weak, nonatomic) IBOutlet UITextView *memo;
@property (weak, nonatomic) IBOutlet UIImageView *billImage;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
- (IBAction)imageButtonPress:(id)sender;


@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *partyView;
@property (weak, nonatomic) IBOutlet UIView *billView;

@property (nonatomic, weak) BillUser *editUser;
@property (nonatomic, weak) Contact *editContact;

@property (nonatomic) bool discountsPreTax;
@property (nonatomic, strong) BillLogicItem *editingItem;

@property (nonatomic) bool setting_totalIsSimple;
@property (nonatomic) bool setting_discountsPreTax;

@end

@implementation SplitMyBillEditorViewController
@synthesize menuView = _menuView;
@synthesize scrollView = _scrollView;
@synthesize editUser = _editUser;
@synthesize editContact = _editContact;
@synthesize discountsPreTax = _discountsPreTax;
@synthesize editingItem = _editingItem;
@synthesize setting_totalIsSimple = _setting_totalIsSimple;
@synthesize setting_discountsPreTax = _setting_discountsPreTax;

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [(SplitMyBillBillEditor *)self.billView reloadData];
    [(SplitMyBillPartySelection *)self.partyView reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"edit user"]) {
        if(self.editContact) {
            [segue.destinationViewController setContact:self.editContact];
            [segue.destinationViewController setDelegate: self.partyView];
        } else {
            [(SplitMyBillContactEditorViewController *)segue.destinationViewController setUser:self.editUser];
            [segue.destinationViewController setDelegate: self.partyView];
        }
    } else if([segue.identifier isEqualToString:@"item editor"] || [segue.identifier isEqualToString:@"user item editor"]) {

        SplitMyBillItemEditorViewController *itemEditor = (SplitMyBillItemEditorViewController *)segue.destinationViewController;
        
        [itemEditor setItem:self.editingItem];
        [itemEditor setUserList:self.logic.users];
        [itemEditor setDelegate:self];
    } else if([segue.identifier isEqualToString:@"to totals"]) {
        //[segue.destinationViewController setBillLogic:self.logic];
    } else if([segue.identifier isEqualToString:@"edit tax"]) {
        [(TaxViewController *)segue.destinationViewController setDataSource:self];
    } else if([segue.identifier isEqualToString:@"edit tip"]) {
        [(TipViewController *)segue.destinationViewController setDataSource:self];
    } else if([segue.identifier isEqualToString:@"view user details"]) {
        //[segue.destinationViewController setLogic:self.logic];
        //[(SplitMyBillContactEditorViewController *)segue.destinationViewController setUser:self.editUser];
    } else if([segue.identifier isEqualToString:@"grand total"]) {
        //[segue.destinationViewController setLogic:self.logic];
    } else if([segue.identifier isEqualToString:@"add debts"]) {
        [segue.destinationViewController setBilllogic:self.logic];
        [segue.destinationViewController setDelegate:self];
    } else if([segue.identifier isEqualToString:@"view image"]) {
        [segue.destinationViewController setBill:self.bill];
    }
}

- (IBAction)showMenu:(id)sender {
    
    if(self.menuView.frame.origin.x < 0) {
        [UIView animateWithDuration:0.25
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.menuView.frame = CGRectMake(0, 0, self.menuView.frame.size.width, self.menuView.frame.size.height);
                         
                         self.scrollView.frame = CGRectMake(270,0,self.scrollView.frame.size.width, self.scrollView.frame.size.height);
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
                             
                             self.scrollView.frame = CGRectMake(0,0,self.scrollView.frame.size.width, self.scrollView.frame.size.height);
                            
                         }
                         completion:nil];
    }
}

- (IBAction)addImage:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        return;
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;

    // Displays a control that allows the user to choose picture or
    // movie capture, if both are available:
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    //store the file
    UIImage *originalImage; //, *editedImage, *imageToSave;
    originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];

    // Save the new image (original or edited) to the Camera Roll
    //UIImageWriteToSavedPhotosAlbum (imageToSave, nil, nil , nil);
    self.bill.image = UIImageJPEGRepresentation(originalImage, 1.0f);
    NSError *error; 
    if(![self.managedObjectContext save:&error]) {
        //throw error...
        
    }
    
    //store image as visible...
    self.billImage.image = originalImage;
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)exitBill:(id)sender {
    if(self.bill) {
        //close UI
        self.bill.total = [NSNumber numberWithInteger:[[self.billlogic.total decimalNumberByMultiplyingByPowerOf10:2] integerValue]];
    
        NSError *error;
        [self.managedObjectContext save:&error];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
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
    
    [self exitBill:sender];
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
    
    //load up defaults for the bill
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.setting_totalIsSimple = [defaults boolForKey:@"UserTotalSimple"];
    self.setting_discountsPreTax = [defaults boolForKey:@"DiscountsPreTax"];

	// Do any additional setup after loading the view.
    self.menuView.frame = CGRectMake(-270, 0, 270, self.view.frame.size.height);
    
    //load in the party selection...
    SplitMyBillPartySelection *partyWin = (SplitMyBillPartySelection *)self.partyView;
    partyWin.dataSource = self;
    partyWin.delegate = self;
    if(!partyWin.loadData) {
        //throw error of some kind...?
    }

    SplitMyBillBillEditor *editorWin = (SplitMyBillBillEditor *)self.billView;
    editorWin.dataSource = self;
    editorWin.delegate = self;
    [editorWin loadData];
    
    self.buttonHideRight.hidden = YES;
    
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * 2, self.scrollView.frame.size.height)];

    //if(self.billlogic.items.count == 0 && self.billlogic.users.count == 0)
    //    [self setupData];
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    self.creationDate.text = [NSString stringWithFormat:@"Created: %@",[dateFormatter stringFromDate:self.bill.created]];
    
    if(self.bill.title) {
        self.memo.text = self.bill.title;
    }
    
    if(self.bill.image) {
        UIImage *image = [UIImage imageWithData:self.bill.image];
        [self.billImage setImage:image];
    }
    
    if(self.bill.items.count > 0) {
        //show the items
        [self nextScreen];
    }
    
    
    [self.billImage.layer addSublayer:[self addDashedBorder]];
    
    //[myImageView.layer addSublayer:[myImageView.image addDashedBorderWithColor:[[UIColor whiteColor] CGColor]]];
    
    //self.billImage.layer draw
    //_tableView.layer.borderWidth = 1.0f;
    //_tableView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.5f].CGColor;

    
    //self.imageButton.frame.border
    
    //cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(yourstuff:)];
	//cameraButton.style=UIBarButtonItemStyleBordered;
}

- (CAShapeLayer *) addDashedBorder { //WithColor: (CGColorRef) color {
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    CGColorRef color = [UIColor whiteColor].CGColor;
    
    CGSize frameSize = self.billImage.frame.size;
    
    CGRect shapeRect = CGRectMake(0.0f, 0.0f, frameSize.width, frameSize.height);
    [shapeLayer setBounds:shapeRect];
    [shapeLayer setPosition:CGPointMake( frameSize.width/2,frameSize.height/2)];
    
    [shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
    [shapeLayer setStrokeColor:color];
    [shapeLayer setLineWidth:3.0f];
    [shapeLayer setLineJoin:kCALineJoinRound];
    [shapeLayer setLineDashPattern:
     [NSArray arrayWithObjects:[NSNumber numberWithInt:5],
      [NSNumber numberWithInt:5],
      nil]];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:shapeRect cornerRadius:15.0];
    [shapeLayer setPath:path.CGPath];
    
    return shapeLayer;
}

/*
- (void) setupData {
    //populate defaults into our model
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *string = [defaults objectForKey:@"taxRate"];
    if(!string) string = @"0";
    self.billlogic.tax = [NSDecimalNumber decimalNumberWithString:string];
    
    string = [defaults objectForKey:@"tipRate"];
    if(!string) string = @"0";
    self.billlogic.tip = [NSDecimalNumber decimalNumberWithString:string];
    
    [self.billlogic addUser:[self makeUserSelfwithDefaults:defaults]];
    
    self.billlogic.roundingAmount = [defaults integerForKey:@"roundValue"];
}
 */

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setMenuView:nil];
    [self setScrollView:nil];
    [self setPartyView:nil];
    [self setCreationDate:nil];
    [self setMemo:nil];
    [self setBillImage:nil];
    [self setImageButton:nil];
    [self setButtonCamera:nil];
    [self setButtonHideRight:nil];
    [super viewDidUnload];
}


#pragma mark - PartySelectionDataSource
- (BillLogic *)logic {
    return self.billlogic;
}

/*
@property (nonatomic, weak) BillLogic *logic;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
*/

- (bool) totalIsSimple {
    return self.setting_totalIsSimple;
}

- (bool) discountsPreTax {
    return self.setting_discountsPreTax;
}

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

- (void) nextScreen {
    //need to update table view in billView...?
    [(SplitMyBillBillEditor *)self.billView reloadData];
    
    [self.scrollView scrollRectToVisible:CGRectMake(320, 0, 320, self.scrollView.frame.size.height) animated:YES];
}

- (void) addDebt {
    [self performSegueWithIdentifier:@"add debts" sender:self];
}

- (void) editItem:(BillLogicItem *)item
{
    NSString *segueID;
    if(self.logic.users.count == 1) {
        segueID = @"user item editor";
    } else {
        segueID = @"item editor";
    }
    
    self.editingItem = item;
    [self performSegueWithIdentifier:segueID sender:self];    
}

- (void) createNewItem {
    //create an item to be edited...
    BillItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"BillItem" inManagedObjectContext:self.managedObjectContext];
    item.preTax = [NSNumber numberWithBool:self.discountsPreTax];
    self.editingItem = [[BillLogicItem alloc] initWithItem:item];
    self.editingItem.isNew = YES;
}

- (void) addItem {
    NSString *segueID;
    if(self.logic.users.count == 1) {
        segueID = @"user item editor";
    } else {
        segueID = @"item editor";
    }
    
    [self createNewItem];
    [self performSegueWithIdentifier:segueID sender:self];
}

- (void) editTip {
    [self performSegueWithIdentifier:@"edit tip" sender:self];
}

- (void) editTax {
    [self performSegueWithIdentifier:@"edit tax" sender:self];
}

- (void) editTotal {
    [self performSegueWithIdentifier:@"grand total" sender:self];
}

- (void) viewUser:(BillUser *)user {
    self.editUser = user;
    [self performSegueWithIdentifier:@"view user details" sender:self];
}

#pragma mark - navigation buttons
- (IBAction)gotoWho:(id)sender {
    [self hideMenuControls];

    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height) animated:NO];
}

- (IBAction)gotoBill:(id)sender {
    [self hideMenuControls];
    
    [(SplitMyBillBillEditor *)self.billView reloadData];
    [self.scrollView scrollRectToVisible:CGRectMake(self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height) animated:NO];
}

- (void) hideMenuControls {
    self.buttonHideRight.hidden = YES;
    [UIView animateWithDuration:0.25
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.menuView.frame = CGRectMake(-1 * self.menuView.frame.size.width, 0, self.menuView.frame.size.width, self.menuView.frame.size.height);
                         self.scrollView.frame = CGRectMake(0,2,self.scrollView.frame.size.width, self.scrollView.frame.size.height);
                         self.scrollView.alpha = 1.0f;
                         self.view.backgroundColor = [UIColor whiteColor];
                     }
                     completion:nil];
}

#pragma mark SplitMyBillItemEditorViewControllerDelegate
//action == 2 delete...
- (void) ItemEditor:(SplitMyBillItemEditorViewController *)sender userAction:(NSInteger)action
{
    if(!self.editingItem) return;
    
    if(action == 2 || sender.item.cost == 0) { //delete the item
        //rollback all changes..
        if(self.editingItem.isNew)
            [self.managedObjectContext rollback];
        else {
            [self.billlogic removeItem:self.editingItem];
        }
        self.editingItem = nil;
    } else {
        //if there are no selected users, default in a split with everyone
        if(self.editingItem.users.count == 0) {
            sender.item.users = self.logic.users;
        }
        
        //if we reach here we save our current object
        if(self.editingItem.isNew) {
            self.editingItem.isNew = NO;
            [self.billlogic addItem:self.editingItem];
        } else {
            [self.billlogic saveChanges];
        }
        self.editingItem = nil;
    }
    
    if(action == 3) {  //adding a new item
        [self createNewItem];
        sender.item = self.editingItem;
        
    }
    /* else {  //remove the item editor
        if(action != 1) { //only manually close if this was an invalid item or other issue
            [self.navigationController popViewControllerAnimated:YES];
        }
    }*/
        
    [(SplitMyBillBillEditor *)self.billView reloadData];
}

#pragma mark TaxViewDataSource
- (void) showError:(NSString *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error delegate:NULL cancelButtonTitle:NULL otherButtonTitles:@"OK", nil];
    
    [alert show];
}

- (NSDecimalNumber *) taxPercent {
    return self.logic.tax;
}

- (void) setTaxPercent:(NSDecimalNumber *)taxPercent {
    self.logic.tax = taxPercent;
}


- (NSDecimalNumber *) taxAmount {
    if(self.logic.taxInDollars)
        return self.logic.taxInDollars;
    return [NSDecimalNumber zero];
}
- (void) setTaxAmount:(NSDecimalNumber *)taxAmount {
    self.logic.taxInDollars = taxAmount;
}
- (bool) inDollars {
    return (self.logic.isTaxInDollars);
}

#pragma mark TipViewDataSource
- (NSDecimalNumber *) tipPercent {
    return self.logic.tip;
}
- (void) setTipPercent:(NSDecimalNumber *)tipPercent {
    self.logic.tip = tipPercent;
}
- (NSDecimalNumber *) tipAmount {
    if(self.logic.tipInDollars)
        return self.logic.rawTip;
    //return self.billLogic.tipInDollars;
    
    return [NSDecimalNumber zero];
}
- (void) setTipAmount:(NSDecimalNumber *)tipAmount {
    self.logic.tipInDollars = tipAmount;
}
- (bool) tipInDollars {
    return (self.logic.isTipInDollars);
}
- (NSDecimalNumber *) totalToTipOn {
    return self.logic.itemTotal;
}


#pragma mark - Bill Add Debt Delegate
- (void) BillAddDebtDelegate:(id)Editor CloseForUser:(BillUser *)user AndSave:(bool)Save
{
    if(Save) {
        bool hadGenerics = (self.logic.numberOfGenericUsers > 0);
        
        //create debts for each option
        SplitMyBillMainScreenViewController *cont = (SplitMyBillMainScreenViewController *)[self.navigationController.viewControllers objectAtIndex:0];
        
        SplitMyBillDebtFromBillViewController *debtScreen = (SplitMyBillDebtFromBillViewController *)Editor;
 
        BillUser *user;
        for(NSUInteger i=0; i<debtScreen.debtUsers.count;i++)
        {
            user = [debtScreen.debtUsers objectAtIndex:i];
            if (!user.contact) {
                //create a contact record for this user
                Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:cont.managedObjectContext];

                contact.name = user.name;
                contact.initials = user.abbreviation;
                
                //blank name and initials
                ContactContactInfo *cinfo = [NSEntityDescription insertNewObjectForEntityForName:@"ContactContactInfo" inManagedObjectContext:cont.managedObjectContext];
                contact.contactinfo = cinfo;
                contact.contactinfo.email = user.email;
                contact.contactinfo.phone = user.phone;
                
                user.contact = contact;
            }
            
            Debt *debt = [NSEntityDescription insertNewObjectForEntityForName:@"Debt" inManagedObjectContext:cont.managedObjectContext];
            
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
            if(self.logic.numberOfGenericUsers == 0) {
                [(SplitMyBillPartySelection *)self.partyView reloadData];
                
                //[self.parentTable deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:NO];
            }
        }
    
        NSError *error;
        if(![cont.managedObjectContext save:&error]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debt Creation Error" message:@"An error occured while attempting to create debts from this bill" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
 
            //revert changes
            [cont.managedObjectContext rollback];
            return;
        }
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) textViewDidEndEditing:(UITextView *)textView {
    //clean up text at all here...
    
    self.bill.title = self.memo.text;
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]){
        [textView resignFirstResponder];
        return NO;
    }else{
        return YES;
    }
}

- (IBAction)imageButtonPress:(id)sender {
    if(self.bill.image) {
        [self performSegueWithIdentifier:@"view image" sender:self];
    } else {
        [self addImage:sender];
    }
}

@end
