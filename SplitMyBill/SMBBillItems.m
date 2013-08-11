//
//  SMBBillItems.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/10/13.
//
//

#import "SMBBillItems.h"
#import "SMBBillController.h"
#import "SplitMyBillBillEditor.h"
#import "SplitMyBillItemEditorViewController.h"
#import "TaxViewController.h"
#import "TipViewController.h"
#import "Debt.h"
#import "Contact.h"
#import "ContactContactInfo.h"
#import "SplitMyBillDebtFromBillViewController.h"
#import "SplitMyBillMainScreenViewController.h"
#import "SMBBillTotalViewController.h"
#import "SplitMyBillContactEditorViewController.h"

@interface SMBBillItems () <BillEditorDataSource, BillEditorDelegate,
 BillEditorDelegate, SplitMyBillItemEditorViewControllerDelegate, TaxViewDataSource, TipViewDataSource>
@property (weak, nonatomic) IBOutlet UIView *billView;
@property (nonatomic, strong) BillLogicItem *editingItem;
@property (nonatomic, weak) BillUser *editUser;
@end

@implementation SMBBillItems

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    [(SplitMyBillBillEditor *)self.billView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    SplitMyBillBillEditor *editorWin = (SplitMyBillBillEditor *)self.billView;
    editorWin.dataSource = self;
    editorWin.delegate = self;
    [editorWin loadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"item editor"] || [segue.identifier isEqualToString:@"user item editor"]) {
        
        SplitMyBillItemEditorViewController *itemEditor = (SplitMyBillItemEditorViewController *)segue.destinationViewController;
        
        [itemEditor setItem:self.editingItem];
        [itemEditor setUserList:self.logic.users];
        [itemEditor setDelegate:self];
    /*
    } else if([segue.identifier isEqualToString:@"to totals"]) {
        //[segue.destinationViewController setBillLogic:self.logic];
    */
    } else if([segue.identifier isEqualToString:@"edit tax"]) {
        [(TaxViewController *) segue.destinationViewController setDataSource:self];
    } else if([segue.identifier isEqualToString:@"edit tip"]) {
        [(TipViewController *) segue.destinationViewController setDataSource:self];
    } else if([segue.identifier isEqualToString:@"view user details"]) {
        SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
        [segue.destinationViewController setLogic:billRoot.billlogic];
        [(SplitMyBillContactEditorViewController *)segue.destinationViewController setUser:self.editUser];
    } else if([segue.identifier isEqualToString:@"grand total"]) {
        SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
        [(SMBBillTotalViewController *)segue.destinationViewController setLogic:billRoot.billlogic];
    /*
    } else if([segue.identifier isEqualToString:@"add debts"]) {
        [segue.destinationViewController setBilllogic:self.logic];
        [segue.destinationViewController setDelegate:self];
    } else if([segue.identifier isEqualToString:@"view image"]) {
        [segue.destinationViewController setBill:self.bill];
    */
    }
}

#pragma mark BillEditorDataSource
- (BillLogic *)logic {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.billlogic;
}

- (bool) totalIsSimple {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.totalIsSimple;
}

- (bool) discountsPreTax {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.discountsPreTax;
}

#pragma mark BillEditorDelegate
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

- (bool) showController:(UIViewController *)controller {
    [self presentViewController:controller animated:YES completion:NULL];
    return YES;
}

- (void) popController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) dismissController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// helper functions
- (void) createNewItem {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    
    //create an item to be edited...
    BillItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"BillItem" inManagedObjectContext:billRoot.managedObjectContext];
    
    item.preTax = [NSNumber numberWithBool:self.discountsPreTax];
    self.editingItem = [[BillLogicItem alloc] initWithItem:item];
    self.editingItem.isNew = YES;
}


#pragma mark SplitMyBillItemEditorViewControllerDelegate
//action == 2 delete...
- (void) ItemEditor:(SplitMyBillItemEditorViewController *)sender userAction:(NSInteger)action
{
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;

    if(!self.editingItem) return;
    
    if(action == 2 || sender.item.cost == 0) { //delete the item
        //rollback all changes..
        if(self.editingItem.isNew)
            [billRoot.managedObjectContext rollback];
        else {
            [billRoot.billlogic removeItem:self.editingItem];
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
            [billRoot.billlogic addItem:self.editingItem];
        } else {
            [billRoot.billlogic saveChanges];
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
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.billlogic.tax;
}

- (void) setTaxPercent:(NSDecimalNumber *)taxPercent {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    billRoot.billlogic.tax = taxPercent;
}

- (NSDecimalNumber *) taxAmount {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    if(billRoot.billlogic.taxInDollars)
        return billRoot.billlogic.taxInDollars;
    
    return [NSDecimalNumber zero];
}

- (void) setTaxAmount:(NSDecimalNumber *)taxAmount {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    billRoot.billlogic.taxInDollars = taxAmount;
}

- (bool) inDollars {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return (billRoot.billlogic.isTaxInDollars);
}

#pragma mark TipViewDataSource
- (NSDecimalNumber *) tipPercent {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.billlogic.tip;
}
- (void) setTipPercent:(NSDecimalNumber *)tipPercent {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    billRoot.billlogic.tip = tipPercent;
}

- (NSDecimalNumber *) tipAmount {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    if(billRoot.billlogic.tipInDollars)
        return billRoot.billlogic.rawTip;
    
    return [NSDecimalNumber zero];
}

- (void) setTipAmount:(NSDecimalNumber *)tipAmount {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    billRoot.billlogic.tipInDollars = tipAmount;
}

- (bool) tipInDollars {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.billlogic.isTipInDollars;
}

- (NSDecimalNumber *) totalToTipOn {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.billlogic.itemTotal;
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
                //[(SplitMyBillPartySelection *)self.partyView reloadData];
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

@end
