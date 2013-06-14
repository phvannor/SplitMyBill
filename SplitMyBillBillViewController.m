//
//  SplitMyBillTableViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SplitMyBillBillViewController.h"
#import "SplitMyBillItemEditorViewController.h"
#import "BillLogic.h"
#import "TaxViewController.h"
#import "TipViewController.h"
#import "BillUser.h"
#import "SplitMyBillUserDetailViewController.h"
#import "SplitMyBillUserOwesTableCellCell.h"

@interface SplitMyBillBillViewController () <SplitMyBillItemEditorViewControllerDelegate, TaxViewDataSource, TipViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, ADBannerViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (nonatomic, strong) NSIndexPath *editingItem;
@property (nonatomic) bool hasTexting;
@property (nonatomic) bool hasEmail;
@property (nonatomic) bool bannerIsVisible;
@end

@implementation SplitMyBillBillViewController
@synthesize tableView = _tableView;

- (IBAction)reset:(id)sender {
    self.billLogic = nil;
    [self.navigationController setToolbarHidden:NO];
    [self.tableView reloadData];
}

- (IBAction)actions:(id)sender {
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:@"Bill Actions" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Reset" otherButtonTitles:nil];
    
    if(self.hasTexting) [actions addButtonWithTitle:@"Text"];
    if(self.hasEmail) [actions addButtonWithTitle:@"Email"];
    [actions addButtonWithTitle:@"Cancel"];
    [actions setCancelButtonIndex:(actions.numberOfButtons - 1)];
    
    [actions showFromBarButtonItem:sender animated:YES];
    [actions showInView:self.view];
}

@synthesize billLogic = _billLogic;
- (BillLogic *)billLogic {
    if(!_billLogic) {
        //setup bill logic
        _billLogic = [[BillLogic alloc] init];
        
        //populate defaults into our model
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [_billLogic resetDataNewTip:[NSDecimalNumber zero] newTax:[NSDecimalNumber zero]];
        
        NSString *string = [defaults objectForKey:@"taxRate"];
        if(!string) string = @"0";
        _billLogic.tax = [NSDecimalNumber decimalNumberWithString:string];
        
        string = [defaults objectForKey:@"tipRate"];
        if(!string) string = @"0";
        _billLogic.tip = [NSDecimalNumber decimalNumberWithString:string];
        
        NSData *defaultUser = [defaults objectForKey:@"default user"];
        BillUser *user;
        if(!defaultUser) {
            user = [[BillUser alloc] initWithName:@"Me" andAbbreviation:@"ME"];
        } else {
            user = [NSKeyedUnarchiver unarchiveObjectWithData:defaultUser];
        }
        [_billLogic addUser:user];            
    }
    return _billLogic;
}
@synthesize shareButton = _shareButton;
@synthesize editingItem = _editingItem;
@synthesize hasEmail = _hasEmail;
@synthesize hasTexting = _hasTexting;
@synthesize bannerIsVisible = _bannerIsVisible;

- (NSArray *) getUsersForItem:(NSInteger)itemIndex {
    BillItem *item = [self.billLogic.items objectAtIndex:itemIndex];
    return item.users;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"item editor"] || [segue.identifier isEqualToString:@"user item editor"]) {        
        //save off which cell was clicked on for delegate/datasource logic
        self.editingItem = [self.tableView indexPathForCell:sender];
        
        BillItem *item;
        if(self.billLogic.items.count == self.editingItem.row) {
            //create the bill item
            item = [[BillItem alloc] initWithPrice:0];
            item.name = [NSString stringWithFormat:@"Item %d",self.billLogic.items.count + 1];
            [self.billLogic addItem:item];
        } else {
            item = [self.billLogic.items objectAtIndex:self.editingItem.row];
        }   
        [segue.destinationViewController setItem:item];
        [segue.destinationViewController setUserList:self.billLogic.users];    
        [segue.destinationViewController setDelegate:self];
    } else if([segue.identifier isEqualToString:@"to totals"]) {
        [segue.destinationViewController setBillLogic:self.billLogic];        
    } else if([segue.identifier isEqualToString:@"edit tax"]) {
        [segue.destinationViewController setDataSource:self];
    } else if([segue.identifier isEqualToString:@"edit tip"]) {
        [segue.destinationViewController setDataSource:self];
    } else if([segue.identifier isEqualToString:@"edit user"]) {
        self.editingItem = [self.tableView indexPathForCell:sender];
        [segue.destinationViewController setLogic:self.billLogic];
        [segue.destinationViewController setUser:[self.billLogic.users objectAtIndex:self.editingItem.row]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    [self.navigationController setToolbarHidden:YES];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    if(!self.hasTexting && !self.hasEmail) {
        //hide the share button
        self.shareButton.enabled = NO;
    }
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setShareButton:nil];
    [self setBillLogic:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //if there is only 1 user, we don't need user
    //specific data
    if(self.billLogic.users.count > 1) {
        return 3;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return (self.billLogic.items.count + 1);
            break;
        case 1:
            return 4;
            break;
        case 2:
            return (self.billLogic.users.count);
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
    if(indexPath.section == 2)
        CellIdentifier = @"person";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];            
    
    BillUser *user;
    switch (indexPath.section) {
        case 0:
            if(indexPath.row < self.billLogic.items.count) {
                BillItem *item = [self.billLogic.items objectAtIndex:indexPath.row];            
                cell.textLabel.text = item.name;
                if(self.billLogic.users.count == 1) {
                    cell.detailTextLabel.text = [item costDisplayForUser:user];
                } else {
                    cell.detailTextLabel.text = [item costActualDisplay];        
                    if(item.users.count == 0) {
                        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingString:@"*"];
                    }
                }
                
            } else {
                // Configure the cell...
                cell.textLabel.text = @"new item";
                cell.detailTextLabel.text = @"Click To Add";            
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"tax";
                    cell.detailTextLabel.text = [BillLogic formatTip:self.billLogic.tax withActual:self.billLogic.taxInDollars];
                    break;
                case 1:
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.textLabel.text = @"total";
                    cell.detailTextLabel.text = [BillLogic formatMoney:self.billLogic.subtotal];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];                            
                    break;
                    
                case 2:
                    cell.textLabel.text = @"tip";
                    cell.detailTextLabel.text = [BillLogic formatTip:self.billLogic.tip withActual:self.billLogic.tipInDollars];                
                    break;
                    
                case 3:
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.textLabel.text = @"total+tip";
                    cell.detailTextLabel.text = [BillLogic formatMoney:self.billLogic.total];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];            
                    break;
            }
            break;   
            
        case 2:
            if([cell isKindOfClass:[SplitMyBillUserOwesTableCellCell class]]) {
                usercell = (SplitMyBillUserOwesTableCellCell *)cell;
            }
            
            user = [self.billLogic.users objectAtIndex:indexPath.row];
            usercell.name.text = user.name;
            usercell.subtotal.text = [BillLogic formatMoney:[self.billLogic subtotalForUser:user]];
            usercell.tip.text = [BillLogic formatMoney:[self.billLogic tipForUser:user]];
            usercell.total.text = [BillLogic formatMoney:[self.billLogic totalForUser:user]];
            //cell.textLabel.text = user.name;
            //cell.detailTextLabel.text = [BillLogic formatUserSubtotal:[self.billLogic subtotalForUser:user] andTip:[self.billLogic tipForUser:user] andTotal:[self.billLogic totalForUser:user]];
            break;
            
        case 3:
            if(indexPath.row == 0) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.text = @"total";
                cell.detailTextLabel.text = [BillLogic formatMoney:self.billLogic.subtotal];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];                            
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.text = @"total + tip";
                cell.detailTextLabel.text = [BillLogic formatMoney:self.billLogic.total];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];            
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
    if(indexPath.section != 0) return NO;    
    return !(indexPath.row == self.billLogic.items.count) ;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        BillItem *item = [self.billLogic.items objectAtIndex:indexPath.row];
        [self.billLogic removeItem:item];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Purchases & Coupons";
            break;
        case 1:
            return @"Tip, Tax, & Totals";
            break;
        case 2:
            return @"People";
            break;
    }
    return @"Unknown";
}

#pragma mark Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //manually trigger segue based on section we are in
    NSString *segueID;
    switch (indexPath.section) {
        case 0:
            if(self.billLogic.users.count == 1) {
                segueID = @"user item editor";
            } else {
                segueID = @"item editor";
            }
            break;
        case 1:
            if(indexPath.row == 0) {
                segueID = @"edit tax";
            } else if(indexPath.row == 2) {
                segueID = @"edit tip";                
            } else {
                return;  //do nothing
            }
            break;
        case 2:
            segueID = @"edit user";
            break;
        default:
            return;
            break;
    }
    [self performSegueWithIdentifier:segueID sender:[self.tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark SplitMyBillItemEditorViewControllerDelegate
- (void) ItemEditor:(SplitMyBillItemEditorViewController *)sender userAction:(NSInteger)action 
{
    if(action == 2 || sender.item.cost == 0) { //delete the item
        [self.billLogic removeItem:sender.item];         
    }
    
    //if there are no selected users, default in a split with everyone
    if(sender.item.users.count == 0) {
        sender.item.users = self.billLogic.users;
    }
    
    //remove the item editor    
    if(action == 3) {
        //make a new item
        BillItem *item = [[BillItem alloc] initWithPrice:0];        
        item.name = [NSString stringWithFormat:@"Item %d", self.billLogic.items.count + 1];
        [self.billLogic addItem:item];
        sender.item = item;
        [self.tableView reloadData];
        
    } else {
        if(action != 1) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        //refresh the row
        [self.tableView reloadData];
    }
}

#pragma mark TaxViewDataSource
- (NSDecimalNumber *) taxPercent {
    return self.billLogic.tax;
}
- (void) setTaxPercent:(NSDecimalNumber *)taxPercent {
    self.billLogic.tax = taxPercent;
}

#pragma mark TipViewDataSource
- (NSDecimalNumber *) tipPercent {
    return self.billLogic.tip;
}
- (void) setTipPercent:(NSDecimalNumber *)tipPercent {
    self.billLogic.tip = tipPercent;
}

#pragma mark actionsheet delegate
- (IBAction)sharePress:(UIBarButtonItem *)sender {
    UIActionSheet *shareOptions = [[UIActionSheet alloc] initWithTitle:@"Share Bill" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if(self.hasTexting) [shareOptions addButtonWithTitle:@"Text"];
    if(self.hasEmail) [shareOptions addButtonWithTitle:@"Email"];
    
    [shareOptions addButtonWithTitle:@"Cancel"];
    [shareOptions setCancelButtonIndex:(shareOptions.numberOfButtons - 1)];
    
    [self.navigationController setToolbarHidden:YES animated:NO];
    [shareOptions showInView:self.view];
}

- (NSString *)composeMessageShort:(bool)brief {
    NSString *message = @"";    
    if(brief) {
        for(BillUser *user in self.billLogic.users) {
            message = [message stringByAppendingFormat:@"%@:%@\n",user.abbreviation, [BillLogic formatMoney:[self.billLogic totalForUser:user]]];                            
        }
        return message;
    }
    //compex message
    
    for(BillUser *user in self.billLogic.users) {
        message = [message stringByAppendingFormat:@"%@\n",user.name];
        for(BillItem *item in [self.billLogic itemsForUser:user]) 
        {
            message = [message stringByAppendingFormat:@"   %@: %@\n",item.name, [item costDisplayForUser:user]];
        }
        message = [message stringByAppendingFormat:@"   owes: %@ + %@ = %@\n",[BillLogic formatMoney:[self.billLogic subtotalForUser:user]],  [BillLogic formatMoney:[self.billLogic tipForUser:user]],  [BillLogic formatMoney:[self.billLogic totalForUser:user]]];        
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
    for(BillUser *user in self.billLogic.users) {
        if(user.phone) [recipients addObject:user.phone];
    }
    picker.recipients = [recipients copy];
    [self presentModalViewController:picker animated:YES];
}

// Displays an email composition interface inside the application.
-(void)displayEmailComposerSheet 
{
    //show a loading icon...
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    NSMutableArray *recipients = [NSMutableArray array];
    for(BillUser *user in self.billLogic.users) {
        if(user.email) [recipients addObject:user.email];
    }
    [picker setToRecipients:[recipients copy]];
    [picker setSubject:@"The Bill"];
    [picker setMessageBody:[self composeMessageShort:NO] isHTML:NO];
    [self presentModalViewController:picker animated:YES];
}

#pragma mark MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger offset = 0;
    if(buttonIndex == 0) {
        [self reset:nil];
        return;
    }
    
    if(self.hasTexting) {
        if (buttonIndex == 1) {
            [self displaySMSComposerSheet];
            return;
        }
    } else {
        offset--;
    }
    
    if(self.hasEmail && buttonIndex == 2 + offset) { 
        [self displayEmailComposerSheet];
        return;
    }
}

#pragma mark - Banner
//Ad Banner
- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
        // Assumes the banner view is just off the bottom of the screen.
        
        self.tableView.frame = CGRectMake(0, 44, 320, 372-banner.frame.size.height);
        banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height);
        
        [UIView commitAnimations];
        self.bannerIsVisible = YES;
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        // Assumes the banner view is placed at the bottom of the screen.
        banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
        [UIView commitAnimations];
        self.bannerIsVisible = NO;
    }
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    
}
- (void)motionEnded:(UIEventSubtype)motion
          withEvent:(UIEvent *)event

{
    [self reset:nil];
}
@end
