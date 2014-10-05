//
//  SMBBillItems.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/10/13.
//
//

#import "SMBBillItems.h"
#import "SplitMyBillItemEditorViewController.h"
#import "TaxViewController.h"
#import "TipViewController.h"
#import "Debt.h"
#import "Contact.h"
#import "ContactContactInfo.h"
#import "SplitMyBillDebtFromBillViewController.h"
#import "SMBMainScreenViewController.h"
#import "SplitMyBillContactEditorViewController.h"
#import "SplitMyBillUserOwesTableCellCell.h"
#import "SMBBillWhoViewController.h"
#import "SMBBillNavigationViewController.h"
#import "SMBBillTotalViewController.h"
#import "SMBBillNavigationViewController.h"

@interface SMBBillItems () <SplitMyBillItemEditorViewControllerDelegate, TaxViewDataSource, TipViewDataSource, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) BillLogicItem *editingItem;
@property (nonatomic, weak) BillUser *editUser;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (BillLogic *) logic;

@end

@implementation SMBBillItems

- (IBAction)actions:(id)sender {
    SMBBillNavigationViewController *controller = (SMBBillNavigationViewController *)self.navigationController;
    
    [controller showBillActionsInView:self.view];
}

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
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // If we have items, we already exist so flip to step 2
    if(self.logic.bill.items.count == 0)
    {
        [self performSegueWithIdentifier:@"partyselection" sender:self];
    }
}

- (IBAction)finishBill:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;

    if([segue.identifier isEqualToString:@"partyselection"]) {
        
        //SMBBillWhoViewController *controller = segue.destinationViewController;
        
    } else if([segue.identifier isEqualToString:@"item editor"] || [segue.identifier isEqualToString:@"user item editor"]) {
        
        SplitMyBillItemEditorViewController *itemEditor = (SplitMyBillItemEditorViewController *)segue.destinationViewController;
        
        [itemEditor setItem:self.editingItem];
        [itemEditor setUserList:self.logic.users];
        [itemEditor setDelegate:self];
        
    } else if([segue.identifier isEqualToString:@"edit tax"]) {
        [(TaxViewController *) segue.destinationViewController setDataSource:self];
        
    } else if([segue.identifier isEqualToString:@"edit tip"]) {
        [(TipViewController *) segue.destinationViewController setDataSource:self];
        
    } else if([segue.identifier isEqualToString:@"view user details"]) {
        [segue.destinationViewController setLogic:billRoot.billlogic];
        [(SplitMyBillContactEditorViewController *)segue.destinationViewController setUser:self.editUser];
        
    } else if([segue.identifier isEqualToString:@"grand total"]) {
        [(SMBBillTotalViewController *)segue.destinationViewController setLogic:billRoot.billlogic];
    }
}

#pragma mark BillEditorDataSource
- (BillLogic *)logic {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    
    return billRoot.billlogic;
}

- (bool) totalIsSimple {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.totalIsSimple;
}

- (bool) discountsPreTax {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.discountsPreTax;
}

#pragma mark BillEditorDelegate
- (void) addDebt {
    [self performSegueWithIdentifier:@"add debts" sender:self];
}

- (void) editItem:(BillLogicItem *)item
{
    self.editingItem = item;
    [self performSegueWithIdentifier:@"item editor" sender:self];
}

- (void) addItem {
    [self createNewItem];
    [self performSegueWithIdentifier:@"item editor" sender:self];
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

// helper functions
- (void) createNewItem {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    
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
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;

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
    
    [self.tableView reloadData];
}

#pragma mark TaxViewDataSource
- (void) showError:(NSString *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error delegate:NULL cancelButtonTitle:NULL otherButtonTitles:@"OK", nil];
    
    [alert show];
}

- (NSDecimalNumber *) taxPercent {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.billlogic.tax;
}

- (void) setTaxPercent:(NSDecimalNumber *)taxPercent {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    billRoot.billlogic.tax = taxPercent;
}

- (NSDecimalNumber *) taxAmount {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    if(billRoot.billlogic.taxInDollars)
        return billRoot.billlogic.taxInDollars;
    
    return [NSDecimalNumber zero];
}

- (void) setTaxAmount:(NSDecimalNumber *)taxAmount {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    billRoot.billlogic.taxInDollars = taxAmount;
}

- (bool) inDollars {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return (billRoot.billlogic.isTaxInDollars);
}

#pragma mark TipViewDataSource
- (NSDecimalNumber *) tipPercent {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.billlogic.tip;
}
- (void) setTipPercent:(NSDecimalNumber *)tipPercent {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    billRoot.billlogic.tip = tipPercent;
}

- (NSDecimalNumber *) tipAmount {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    if(billRoot.billlogic.tipInDollars)
        return billRoot.billlogic.rawTip;
    
    return [NSDecimalNumber zero];
}

- (void) setTipAmount:(NSDecimalNumber *)tipAmount {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    billRoot.billlogic.tipInDollars = tipAmount;
}

- (bool) tipInDollars {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.billlogic.isTipInDollars;
}

- (NSDecimalNumber *) totalToTipOn {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.billlogic.itemTotal;
}

#pragma mark - Bill Add Debt Delegate
- (void) BillAddDebtDelegate:(id)Editor CloseForUser:(BillUser *)user AndSave:(bool)Save
{
    if(Save) {
        //create debts for each option
        SMBMainScreenViewController *cont = (SMBMainScreenViewController *)[self.navigationController.viewControllers objectAtIndex:0];
        
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
            debt.amount = [NSNumber numberWithInteger:[amount integerValue]];
            
            //add amount to the corresponding contact
            user.contact.owes = [NSNumber numberWithInteger:([user.contact.owes integerValue] + [amount integerValue])];
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


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // If there is only 1 user, we don't need user specific data
    NSUInteger userCnt = self.logic.userCount;
    if(userCnt > 1) {
        return 3; //4;
    } else {
        return 2; //3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        if(self.logic.items.count < 100)
            return self.logic.items.count + 1;
        else
            return self.logic.items.count;
    }
    
    if(section == 1) {
        return 4;
    }
    
    bool isSimpleBill = (self.logic.userCount == 1);
    NSInteger offset = isSimpleBill ? 1 : 0;
    if(section + offset == 2) {
        if(isSimpleBill) {
            return 1;
        } else {
            return (self.logic.userCount + 1);
        }
    }
    
    if(section + offset == 3) {
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Skip users section if only 1 user on the bill
    
    NSInteger section = indexPath.section;
    if(section >= 2) {
        section = (self.logic.userCount > 1) ? indexPath.section : indexPath.section + 1;
    }
    
    SplitMyBillUserOwesTableCellCell *usercell;
    NSString *CellIdentifier = @"item information";
    if(section == 2) {
        if(self.logic.userCount == indexPath.row)
        {
            CellIdentifier = @"item information";
        } else {
            CellIdentifier = @"person";
        }
    } else if(section == 3) {
        CellIdentifier = @"cell basic";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    BillUser *user;
    switch (section) {
        case 0:
            if(indexPath.row < self.logic.items.count) {
                BillLogicItem *item = [self.logic.items objectAtIndex:indexPath.row];
                cell.textLabel.text = [NSString stringWithFormat:@"%d) %@",[@(indexPath.row) intValue] + 1,item.name];
                
                if(self.logic.userCount == 1) {
                    cell.detailTextLabel.text = [item costDisplayForUser:user];
                } else {
                    cell.detailTextLabel.text = [item costActualDisplay];
                    if(item.users.count == 0) {
                        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingString:@"*"];
                    }
                }
                
            } else {
                // Configure the cell...
                cell.textLabel.text = @" ";
                cell.detailTextLabel.text = @"Add Item";
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    if(self.logic.isTaxInDollars) {
                        cell.textLabel.text = @"Tax";
                        cell.detailTextLabel.text = [BillLogic formatMoney:self.logic.taxInDollars];
                    } else {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ Tax", [BillLogic formatTip:self.logic.tax]];
                        cell.detailTextLabel.text = [BillLogic formatMoney:self.logic.taxInDollars];
                    }
                    break;
                    
                case 1:
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.textLabel.text = @"Subtotal";
                    cell.detailTextLabel.text = [BillLogic formatMoney:self.logic.subtotal];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    break;
                    
                case 2:
                    if(self.logic.isTipInDollars) {
                        cell.textLabel.text = @"Tip";
                        cell.detailTextLabel.text = [BillLogic formatMoney:self.logic.tipInDollars];
                    } else {
                        cell.textLabel.text =  [NSString stringWithFormat:@"%@ Tip", [BillLogic formatTip:self.logic.tip]];
                        cell.detailTextLabel.text = [BillLogic formatMoney: self.logic.tipInDollars];
                    }
                    
                    if(self.logic.roundingAmount > 0) {
                        if(![self.logic.tipInDollars isEqualToNumber:self.logic.rawTip]) {
                            cell.textLabel.text = @"Tip (adjusted)";
                            cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" (was %@)",[BillLogic formatMoney:self.logic.rawTip]];
                        }
                    }
                    break;
                    
                case 3:
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = @"Total";
                    cell.detailTextLabel.text = [BillLogic formatMoney:self.logic.total];
                    break;
            }
            break;
            
        case 2:
            if(self.logic.users.count == indexPath.row)
            {
                // Show modify party option
                cell.detailTextLabel.text = @"Modify Party";
                cell.textLabel.text = @" ";
            } else {
                user = [self.logic.users objectAtIndex:indexPath.row];
                
                if([self totalIsSimple]) {
                    cell.textLabel.text = user.name;
                    cell.detailTextLabel.text = [BillLogic formatMoney:[self.logic totalForUser:user]];
                } else {
                    if([cell isKindOfClass:[SplitMyBillUserOwesTableCellCell class]]) {
                        usercell = (SplitMyBillUserOwesTableCellCell *)cell;
                    }
                    usercell.name.text = user.name;
                    usercell.subtotal.text = [BillLogic formatMoney:[self.logic subtotalForUser:user]];
                    usercell.tip.text = [BillLogic formatMoney:[self.logic tipForUser:user]];
                    usercell.total.text = [BillLogic formatMoney:[self.logic totalForUser:user]];
                }
            }
            break;
            
        case 3: // Notes
            cell.textLabel.text = @"Test Notes";
            break;
            
        default:
            break;
    }
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 2) return YES;
    if(indexPath.section != 0) return NO;
    return !(indexPath.row == self.logic.items.count) ;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if(indexPath.section == 0) {
            // Delete the row from the data source
            BillLogicItem *item = [self.logic.items objectAtIndex:indexPath.row];
            [self.logic removeItem:item];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else if(indexPath.section == 2) {
            BillUser *user = [self.logic.users objectAtIndex:indexPath.row];
            [self.logic removeUser:user];
            
            if(self.logic.userCount > 1)
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [tableView reloadData];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Purchases & Coupons";
        case 1:
            return @"Tip, Tax, & Totals";
        case 2:
            return @"People";
        case 3:
            return @"Notes";
    }
    
    return @"";
}
/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 30)];
    switch (section) {
        case 0:
            label.text = @"Purchases & Coupons";
            break;
        case 1:
            label.text = @"Tip, Tax, & Totals";
            break;
        case 2:
            label.text = @"People";
            break;
        case 3:
            label.text = @"Notes";
            break;
    }
    
    label.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    label.font = [UIFont fontWithName:@"Avenir-Medium" size:15];
    return label;
}
*/

#pragma mark Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //manually trigger segue based on section we are in
    switch (indexPath.section) {
        case 0:
            if(indexPath.row == self.logic.items.count)
                [self addItem];
            else {
                BillLogicItem *item = [self.logic.items objectAtIndex:indexPath.row];
                [self editItem:item];
            }
            break;
            
        case 1:
            if(indexPath.row == 0) {
                [self editTax];
            } else if(indexPath.row == 2) {
                [self editTip];
            } else if(indexPath.row == 3) {
                [self editTotal];
            } else {
                return; //do nothing
            }
            break;
        case 2:
            if(self.logic.users.count == indexPath.row) {
                [self buttonBack:nil];
            } else {
                [self viewUser:[self.logic.users objectAtIndex:indexPath.row]];
            }
            break;
        default:
            return;
            break;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (IBAction)buttonBack:(id)sender {
    [self performSegueWithIdentifier:@"partyselection" sender:self];
}

@end
