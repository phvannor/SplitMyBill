//
//  SplitMyBillUserDetailViewController.m
//  SplitTheBill
//
//  Created by Phillip Van Nortwick on 5/5/12.
//  Copyright (c) 2012. All rights reserved.
//
//  

#import "SplitMyBillUserDetailViewController.h"
#import "SplitMyBillContactEditorViewController.h"
#import "SMBMainScreenViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SplitMyBillUserDetailViewController () <UITableViewDataSource, UITableViewDelegate, ContactEditorDelegate>
@property (nonatomic, strong) BillUser *editUser;
- (IBAction)editUser:(id)sender;
@end

@implementation SplitMyBillUserDetailViewController
@synthesize user = _user;
@synthesize logic = _logic;
@synthesize userTotal = _userTotal;
@synthesize userSubtotal = _userSubtotal;
@synthesize userTip = _userTip;
@synthesize userTax = _userTax;
@synthesize editUser = _editUser;

//take user to the contact editor or the manual editor depending on the
//user currently active
- (IBAction)editUser:(id)sender {
    if(!self.user.contact) {
        self.editUser = [[BillUser alloc] initWithName:self.user.name andAbbreviation:self.user.abbreviation];
        self.editUser.email = self.user.email;
        self.editUser.phone = self.user.phone;
    }
    
    [self performSegueWithIdentifier:@"edit user" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"edit user"])
    {
        //we need to be this one's delegate...
        SplitMyBillContactEditorViewController *vc = (SplitMyBillContactEditorViewController *)segue.destinationViewController;
        
        vc.delegate = self;
        if(self.user.contact) {
            vc.contact = self.user.contact;
        } else {
            vc.user = self.editUser;
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //populate our fields text
    self.title = self.user.name;
    self.userSubtotal.text = [BillLogic formatMoney:[self.logic itemtotalForUser:self.user]];
    self.userTax.text = [BillLogic formatMoney:[self.logic taxForUser:self.user]];
    self.userTip.text = [BillLogic formatMoney:[self.logic tipForUser:self.user]];
    self.userTotal.text = [BillLogic formatMoney:[self.logic totalForUser:self.user]];
    
}

- (void)viewDidUnload
{
    [self setUserTotal:nil];
    [self setUserSubtotal:nil];
    [self setUserTip:nil];
    [self setUserTax:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITableViewDataSource
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
    label.text = @" Items";
    label.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    label.font = [UIFont fontWithName:@"Avenir-Medium" size:15];
    
    return label;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Items";
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.logic itemsForUser:self.user].count;
}

//each row in the table is one item the user is sharing on the bill
//items the user is not attached to will not be shown
//items they are sharing will show the amount they owe and the total of that item
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"item";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    BillLogicItem *item = [[self.logic itemsForUser:self.user] objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%d) %@", [@(indexPath.row) intValue] + 1, item.name];
    cell.detailTextLabel.text = [item costDisplayForUser:self.user];

    return cell;
}

#pragma mark UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
}

#pragma mark - ContactEditorDelegate
//- (void) formClose:(bool)SaveChanges {
- (void) ContactEditor:(id)Editor Close:(bool)SaveChanges
{
    if(self.user.contact) {
        SMBMainScreenViewController *cont = (SMBMainScreenViewController *)[self.navigationController.viewControllers objectAtIndex:0];
        
        if(SaveChanges) {
            NSError *error;
            if (![cont.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Person" message:@"An error occurred while attempting to save your changes" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alert show];
                
                //leave them where they are
                return;
            }
            
            //force update user data
            self.user.contact = self.user.contact;
            
        } else {
            [cont.managedObjectContext rollback];
        }
    } else if(SaveChanges) {
        if(self.editUser.name.length > 0)
            self.user.name = self.editUser.name;
        if(self.editUser.abbreviation.length > 0)
            self.user.abbreviation = self.editUser.abbreviation;
        self.user.phone = self.editUser.phone;
        self.user.email = self.editUser.email;
        
        if(self.editUser.isSelf) {
            //save back to user defaults...
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.editUser] forKey:@"default user"];
            [defaults synchronize];
        }
    }
    
    if(SaveChanges) {
        self.title = self.user.name;
    }
    
    self.editUser = nil;
}

- (void) ContactEditorDelete:(id)Editor {
    //?deletes are more complicated???
    
    SMBMainScreenViewController *cont = (SMBMainScreenViewController *)[self.navigationController.viewControllers objectAtIndex:0];
        
    //delete our object
    [cont.managedObjectContext deleteObject:self.user.contact.contactinfo];
    [cont.managedObjectContext deleteObject:self.user.contact];
    
    NSError *error;
    if (![cont.managedObjectContext save:&error]) {
        NSLog(@"Couldn't save: %@", [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Person" message:@"An error occurred while attempting to create a new person" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
    
    //dismiss the editor
    [self.navigationController popViewControllerAnimated:YES];
    
    //tell our delegate we have been deleted?
    
    self.user.contact = nil;
}

@end
