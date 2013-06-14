//
//  SplitMyBillDebtFromBillViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/22/12.
//
//

#import "SplitMyBillDebtFromBillViewController.h"

@interface SplitMyBillDebtFromBillViewController ()
@property (nonatomic, strong) BillUser *payingUser;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UITextField *activeField;

- (IBAction)buttonSave:(id)sender;
- (IBAction)buttonCancel:(id)sender;
@end

@implementation SplitMyBillDebtFromBillViewController
@synthesize activeField = _activeField;
@synthesize billlogic = _billlogic;
@synthesize payingUser = _payingUser;
@synthesize debtUsers = _debtUsers;
@synthesize debtAmounts = _debtAmounts;
- (NSString *) notes {
    //get cell from section 3
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    
    if(!cell) return @"";
    
    UITextField *text = (UITextField *)[cell viewWithTag:1];
    if(!text) return @"";
    
    return text.text;
}


- (IBAction)buttonSave:(id)sender {
    [self.delegate BillAddDebtDelegate:self CloseForUser:nil AndSave:YES];
}

- (IBAction)buttonCancel:(id)sender {
    [self.delegate BillAddDebtDelegate:self CloseForUser:nil AndSave:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self registerForKeyboardNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if(!self.payingUser)
        return 1;
    else
        return 3;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Who paid the bill?";
        case 1:
            return @"Adding the following debts:";
        default:
            return @"With comment:";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        if(!self.payingUser)
            return self.billlogic.users.count;
        else
            return 1;        
    } else if(section == 1) {
        return self.debtUsers.count;
    } else if(section == 2) {
        return 1;
    }
    
    return 0;
}

- (void) configureCellForUser:(BillUser *)user withCell:(UITableViewCell *)cell
{
    cell.textLabel.text = user.name;
    cell.detailTextLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"user";
    static NSString *DebtCellIdentifier = @"debt cell";
    UITableViewCell *cell;
    
    if(indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(self.payingUser) {
            [self configureCellForUser:self.payingUser withCell:cell];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            // Configure the cell...
            BillUser *user = [self.billlogic.users objectAtIndex:indexPath.row];
            [self configureCellForUser:user withCell:cell];
        }
    } else if(indexPath.section == 1){
        cell = [tableView dequeueReusableCellWithIdentifier:DebtCellIdentifier];
        BillUser *user = [self.debtUsers objectAtIndex:indexPath.row];
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.text = user.name;
        label = (UILabel *)[cell viewWithTag:2];
        label.text = [BillLogic formatMoney:[self.billlogic totalForUser:user]];
        
        NSDecimalNumber *debt = [self.debtAmounts objectAtIndex:indexPath.row];
        label = (UILabel *)[cell viewWithTag:3];
        label.text = [BillLogic formatMoney:debt];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"comment"];
        //UITextField *text = (UITextField *) [cell viewWithTag:1];
        //text.text = @"debt from split bill";
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate
- (void) calculateOwedAmounts
{
    if(self.payingUser.isSelf) {
        self.debtUsers = [[NSMutableArray alloc] init];
        self.debtAmounts = [[NSMutableArray alloc] init];

        //everyone owes us the amount they owe
        for(BillUser *user in self.billlogic.users) {
            if(user.isSelf)
                continue;
                
            //ignore zero debts
            NSDecimalNumber *debt = [self.billlogic totalForUser:user];
            if([debt isEqualToNumber:[NSDecimalNumber zero]])
                continue;

            [self.debtUsers addObject:user];
            [self.debtAmounts addObject:debt];
        }
    } else {
        BillUser *user = [self.billlogic getSelf];
        NSDecimalNumber *debt = [self.billlogic totalForUser:user];

        //we owe the payer our debt only
        self.debtUsers = [[NSMutableArray alloc] initWithObjects:self.payingUser, nil];
        if([debt isEqualToNumber:[NSDecimalNumber zero]])
            return;
        
        debt = [[NSDecimalNumber zero] decimalNumberBySubtracting:debt];
        self.debtAmounts = [[NSMutableArray alloc] initWithObjects:debt, nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if(indexPath.section == 0) {
        if(!self.payingUser) {
            self.payingUser = [self.billlogic.users objectAtIndex:indexPath.row];
            [self calculateOwedAmounts];
        } else {
            self.payingUser = nil;
        }
        
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}

/* Keyboard Handling */

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    //CGRect aRect = self.tableView.frame;
    //aRect.size.height -= kbSize.height;
    
    //if (!CGRectContainsPoint(aRect, self.activeField.superview.frame.origin) ) {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    //}
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

@end
