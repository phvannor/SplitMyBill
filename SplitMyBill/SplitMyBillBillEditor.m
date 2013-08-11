//
//  SplitMyBillBillEditor.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/28/13.
//
//

#import "SplitMyBillBillEditor.h"
#import <MessageUI/MessageUI.h>
#import "SplitMyBillMainScreenViewController.h"
#import "SplitMyBillDebtFromBillViewController.h"
#import "SplitMyBillItemEditorViewController.h"
#import "Contact.h"
#import "ContactContactInfo.h"
#import "Debt.h"
#import "SplitMyBillUserOwesTableCellCell.h"
#import <QuartzCore/QuartzCore.h>

@interface SplitMyBillBillEditor() <UIActionSheetDelegate,MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) bool hasTexting;
@property (nonatomic) bool hasEmail;
@end

@implementation SplitMyBillBillEditor
@synthesize hasEmail = _hasEmail;
@synthesize hasTexting = _hasTexting;
@synthesize dataSource = _dataSource;
@synthesize tableView = _tableView;
- (void) setTableView:(UITableView *)tableView {
    _tableView = tableView;
    _tableView.layer.borderWidth = 1.0f;
    _tableView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.5f].CGColor;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) reloadData {
    if(self.tableView)
      [self.tableView reloadData];    
}

- (void) loadData {
    Class classToTest = (NSClassFromString(@"MFMailComposeViewController"));
    if (classToTest != nil) {
        self.hasEmail = [classToTest canSendMail];
    }
    classToTest = (NSClassFromString(@"MFMessageComposeViewController"));
    if (classToTest != nil) {
        // Check whether the current device is configured for sending SMS messages
        self.hasTexting = [classToTest canSendText];
    }    
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //if there is only 1 user, we don't need user
    //specific data
    NSUInteger userCnt = self.dataSource.logic.userCount;
    if(userCnt > 1) {
        return 3;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            if(self.dataSource.logic.items.count < 100)
                return (self.dataSource.logic.items.count + 1);
            else
                return (self.dataSource.logic.items.count);
            break;
        case 1:
            return 4;
            break;
        case 2:
            return (self.dataSource.logic.userCount);
        case 3:
            return 2;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SplitMyBillUserOwesTableCellCell *usercell;
    NSString *CellIdentifier = @"item information";
    if(indexPath.section == 2) {
        if(!self.dataSource.totalIsSimple)
            CellIdentifier = @"person";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    BillUser *user;
    switch (indexPath.section) {
        case 0:
            if(indexPath.row < self.dataSource.logic.items.count) {
                BillLogicItem *item = [self.dataSource.logic.items objectAtIndex:indexPath.row];
                cell.textLabel.text = [NSString stringWithFormat:@"%d) %@",(indexPath.row + 1),item.name];
                
                if(self.dataSource.logic.userCount == 1) {
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
                    if(self.dataSource.logic.isTaxInDollars) {
                        cell.textLabel.text = @"Tax";
                        cell.detailTextLabel.text = [BillLogic formatMoney:self.dataSource.logic.taxInDollars];
                    } else {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ Tax", [BillLogic formatTip:self.dataSource.logic.tax]];
                        cell.detailTextLabel.text = [BillLogic formatMoney:self.dataSource.logic.taxInDollars];
                    }
                    break;
                    
                case 1:
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.textLabel.text = @"Subtotal";
                    cell.detailTextLabel.text = [BillLogic formatMoney:self.dataSource.logic.subtotal];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    break;
                    
                case 2:
                    if(self.dataSource.logic.isTipInDollars) {
                        cell.textLabel.text = @"Tip";
                        cell.detailTextLabel.text = [BillLogic formatMoney:self.dataSource.logic.tipInDollars];
                    } else {
                        cell.textLabel.text =  [NSString stringWithFormat:@"%@ Tip", [BillLogic formatTip:self.dataSource.logic.tip]];
                        cell.detailTextLabel.text = [BillLogic formatMoney: self.dataSource.logic.tipInDollars];
                    }
                    
                    if(self.dataSource.logic.roundingAmount > 0) {
                        if(![self.dataSource.logic.tipInDollars isEqualToNumber:self.dataSource.logic.rawTip]) {
                            //cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingString:@"*"];
                            cell.textLabel.text = @"Tip (adjusted)";
                            cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" (was %@)",[BillLogic formatMoney:self.dataSource.logic.rawTip]];
                        }
                    }
                    break;
                    
                case 3:
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = @"Total";
                    cell.detailTextLabel.text = [BillLogic formatMoney:self.dataSource.logic.total];
                    break;
            }
            break;
            
        case 2:
            user = [self.dataSource.logic.users objectAtIndex:indexPath.row];
            
            if(self.dataSource.totalIsSimple) {
                cell.textLabel.text = user.name;
                cell.detailTextLabel.text = [BillLogic formatMoney:[self.dataSource.logic totalForUser:user]];
            } else {
                if([cell isKindOfClass:[SplitMyBillUserOwesTableCellCell class]]) {
                    usercell = (SplitMyBillUserOwesTableCellCell *)cell;
                }
                usercell.name.text = user.name;
                usercell.subtotal.text = [BillLogic formatMoney:[self.dataSource.logic subtotalForUser:user]];
                usercell.tip.text = [BillLogic formatMoney:[self.dataSource.logic tipForUser:user]];
                usercell.total.text = [BillLogic formatMoney:[self.dataSource.logic totalForUser:user]];
            }
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
    return !(indexPath.row == self.dataSource.logic.items.count) ;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if(indexPath.section == 0) {
            // Delete the row from the data source
            BillLogicItem *item = [self.dataSource.logic.items objectAtIndex:indexPath.row];
            [self.dataSource.logic removeItem:item];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else if(indexPath.section == 2) {
            BillUser *user = [self.dataSource.logic.users objectAtIndex:indexPath.row];
            [self.dataSource.logic removeUser:user];
            
            if(self.dataSource.logic.userCount > 1)
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [tableView reloadData];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 30)];
    switch (section) {
        case 0:
            label.text = @" Purchases & Coupons";
            break;
        case 1:
            label.text = @" Tip, Tax, & Totals";
            break;
        case 2:
            label.text = @" People";
            break;
    }
    label.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    label.font = [UIFont fontWithName:@"Avenir-Medium" size:15];
    return label;
}

#pragma mark Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //manually trigger segue based on section we are in
    switch (indexPath.section) {
        case 0:
            if(indexPath.row == self.dataSource.logic.items.count)
                [self.delegate addItem];
            else {
                BillLogicItem *item = [self.dataSource.logic.items objectAtIndex:indexPath.row];
                [self.delegate editItem:item];
            }
            break;
            
        case 1:
            if(indexPath.row == 0) {
                [self.delegate editTax];
            } else if(indexPath.row == 2) {
                [self.delegate editTip];
            } else if(indexPath.row == 3) {
                [self.delegate editTotal];
            } else {
                return; //do nothing
            }
            break;
        case 2:
            [self.delegate viewUser:[self.dataSource.logic.users objectAtIndex:indexPath.row]];
            break;
        default:
            return;
            break;
    }
    
    //[self performSegueWithIdentifier:segueID sender:[self.tableView cellForRowAtIndexPath:indexPath]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark actionsheet delegate
- (IBAction)actionButtonPress:(id)sender {
    UIActionSheet *shareOptions = [[UIActionSheet alloc] initWithTitle:@"Share Bill" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if(self.hasTexting) [shareOptions addButtonWithTitle:@"Text"];
    if(self.hasEmail) [shareOptions addButtonWithTitle:@"Email"];
    
    //check if self present and user count >X;
    NSInteger max = 0;
    if([self.dataSource.logic getSelf]) max = 1;
    if((self.dataSource.logic.userCount > max) && ![self.dataSource.logic.total isEqual:[NSDecimalNumber zero]])
        [shareOptions addButtonWithTitle:@"Add To Debts"];
    
    [shareOptions addButtonWithTitle:@"Cancel"];
    [shareOptions setCancelButtonIndex:(shareOptions.numberOfButtons - 1)];
    
    //?//[self.navigationController setToolbarHidden:YES animated:NO];
    [shareOptions showInView:self];
}

- (NSString *)composeMessageShort:(bool)brief {
    NSString *message = @"";
    if(brief) {
        for(BillUser *user in self.dataSource.logic.users) {
            message = [message stringByAppendingFormat:@"%@:%@\n",user.abbreviation, [BillLogic formatMoney:[self.dataSource.logic totalForUser:user]]];
        }
        return message;
    }
    //compex message
    message = @"Our bill:\n";
    NSUInteger count;
    
    for(BillUser *user in self.dataSource.logic.users) {
        message = [message stringByAppendingFormat:@"%@\n",user.name];
        count = 0;
        for(BillLogicItem *item in [self.dataSource.logic itemsForUser:user])
        {
            count++;
            message = [message stringByAppendingFormat:@"   %d.%@ %@\n",count,item.name, [item costDisplayForUser:user]];
        }
        message = [message stringByAppendingFormat:@"   owes: %@ + %@ = %@\n",[BillLogic formatMoney:[self.dataSource.logic subtotalForUser:user]],  [BillLogic formatMoney:[self.dataSource.logic tipForUser:user]],  [BillLogic formatMoney:[self.dataSource.logic totalForUser:user]]];
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
    for(BillUser *user in self.dataSource.logic.users) {
        if(user.phone) [recipients addObject:user.phone];
    }
    picker.recipients = [recipients copy];
    
    [self.delegate showController:picker];
    //[self presentViewController:picker animated:YES completion:NULL];
}

// Displays an email composition interface inside the application.
-(void)displayEmailComposerSheet
{
    //show a loading icon...
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    NSMutableArray *recipients = [NSMutableArray array];
    for(BillUser *user in self.dataSource.logic.users) {
        if(user.email) [recipients addObject:user.email];
    }
    [picker setToRecipients:[recipients copy]];
    [picker setSubject:@"Bill"];
    [picker setMessageBody:[self composeMessageShort:NO] isHTML:NO];
    
    [self.delegate showController:picker];
    //[self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    if(result == MessageComposeResultSent)
        [TestFlight passCheckpoint:@"Share - Email Sent"];
    
    [self.delegate dismissController];
    //[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if(result == MFMailComposeResultSent)
        [TestFlight passCheckpoint:@"Share - SMS Sent"];
    
    [self.delegate dismissController];
    //[self dismissViewControllerAnimated:YES completion:NULL];
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
    if([self.dataSource.logic getSelf]) max = 1;
    if((self.dataSource.logic.userCount > max) && ![self.dataSource.logic.total isEqual:[NSDecimalNumber zero]]) {
        if(buttonIndex == 2 + offset) {
           [self.delegate addDebt];
        }
    } else {
        offset--;
    }
}

@end
