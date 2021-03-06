//
//  SplitMyBillItemEditorViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "SplitMyBillItemEditorViewController.h"
#import "BillUser.h"
#import "BillLogic.h"
#import <QuartzCore/QuartzCore.h>
#import "TestFlight.h"

@interface SplitMyBillItemEditorViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIButton *buttonSelectAll;
@property (weak, nonatomic) IBOutlet UITextField *nameEdit;
@property (nonatomic) bool dataSaved;
@property (nonatomic) bool drillingIn;
@property (nonatomic) NSInteger valueInCents;

- (IBAction)deleteClose:(id)sender;
- (IBAction)addNewPress:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchPurchaseCoupon;
@end

@implementation SplitMyBillItemEditorViewController

@synthesize cost = _cost;
@synthesize switchPurchaseCoupon = _switchPurchaseCoupon;
@synthesize buttonSelectAll = _buttonSelectAll;
@synthesize delegate = _delegate;
@synthesize userList = _userList;
@synthesize nameEdit = _nameEdit;
@synthesize tableView = _tableView;
@synthesize dataSaved = _dataSaved;
@synthesize item = _item;
@synthesize drillingIn = _drillingIn;
@synthesize valueInCents = _valueInCents;

- (IBAction) nameChanged:(UITextField *)sender {
    self.item.name = sender.text;
    self.dataSaved = NO;
}

- (IBAction)selectAll:(id)sender {
    bool removeUsers = (self.item.users.count == self.userList.count); //we should unselect all instead
    
    for(NSInteger i=0;i<self.userList.count;i++) {        
        BillUser *user = [self.userList objectAtIndex:i];
        if(removeUsers)
            [self.item removeUser:user];
        else
            [self.item addUser:user];
    }
    
    [self.tableView reloadData];
}

- (void) setupFormAndReload:(bool)reload {
    // Do any additional setup after loading the view. 
    self.valueInCents = self.item.cost;    
    self.cost.text = self.item.costDisplay;
    self.nameEdit.text = self.item.name;
    
    if(self.userList.count > 1) {
        if(reload)
            [self.tableView reloadData];
    } else {
        self.buttonSelectAll.hidden = YES;
    }
    
    self.dataSaved = NO;
    self.switchPurchaseCoupon.selectedSegmentIndex = self.item.isDiscount ? 1 : 0;
}

- (void)saveData {
    //save data & close the form    
    self.item.cost = self.valueInCents;
    self.item.name = self.nameEdit.text;
    self.item.isDiscount = (self.switchPurchaseCoupon.selectedSegmentIndex == 1);
    
    self.dataSaved = YES;
}

- (IBAction)addNewPress:(id)sender {
    [self saveData];
    [self.delegate ItemEditor:self userAction:3];    
    [self setupFormAndReload:YES];
}

- (IBAction)deleteClose:(id)sender {
    //delete the item & close the form
    [self.delegate ItemEditor:self userAction:2];
    [self.navigationController popViewControllerAnimated:YES];    
}

- (IBAction)digitPress:(UIButton *)sender {
    
    if(self.valueInCents > 1000000) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Cost" message:@"Cost must be less than $10,000" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];                                                                                                                                                
        return;
    }
    
    self.valueInCents *= 10;
    self.valueInCents += [sender.currentTitle intValue];
    self.cost.text = [BillLogic formatMoney:[NSDecimalNumber decimalNumberWithMantissa:self.valueInCents exponent:-2 isNegative:NO]];
}

- (IBAction)pressUndo {
    //remove last digit or set back to 0
    self.valueInCents /= 10;
    self.cost.text = [BillLogic formatMoney:[NSDecimalNumber decimalNumberWithMantissa:self.valueInCents exponent:-2 isNegative:NO]];
}

- (IBAction)switchPurchaseCoupon:(UISegmentedControl *)sender {
    self.dataSaved = NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.drillingIn = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if(self.drillingIn) return;
    
    //if they leave not through us, save data
    if(!self.dataSaved) {
        [self saveData];
        [self.delegate ItemEditor:self userAction:1];
    }
}

- (void)nameQuickPicks
{
    [TestFlight passCheckpoint:@"ItemNameQuickPicks"];
    
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:@"Quick Names" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Drink", @"Appetizer", @"Entree", @"Dessert", @"Coupon", nil];
    [actions showInView:self.view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 18, 18)];
    [leftBtn setImage:[UIImage imageNamed:@"list.png"] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(nameQuickPicks) forControlEvents:UIControlEventTouchDown];
    self.nameEdit.rightView = leftBtn;
    self.nameEdit.rightViewMode = UITextFieldViewModeUnlessEditing;
    
    if(self.tableView) {
        self.tableView.layer.borderWidth = 1.0f;
        self.tableView.layer.borderColor = [UIColor colorWithWhite:0.7f alpha:1.0f].CGColor;
    }
    [self setupFormAndReload:NO];        

}

- (void)viewDidUnload
{
    [self setCost:nil];
    [self setTableView:nil];
    [self setButtonSelectAll:nil];
    [self setNameEdit:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"user name";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if(self.userList.count == 1) {
        cell.textLabel.text = [NSString stringWithFormat:@"%d", @(indexPath.row).intValue + 2];
        return cell;
    }
    
    // Configure the cell...
    BillUser *user =[self.userList objectAtIndex:indexPath.row];
    
    cell.textLabel.text = user.abbreviation;
    
    if([self.item.users containsObject:user]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
        
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.userList.count == 1) {
        return 9;
    } else {
        return self.userList.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.userList.count == 1) {
        return @"Split In";
    } else {
        return @"Shared";
    }
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //add user to list
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Single user mode vs multiple
    if(self.userList.count == 1) {
        NSInteger currentSplit = self.item.split - 2;
        
        if(indexPath.row == currentSplit) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.item.split = 1;
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.item.split = indexPath.row + 2;
            
            if(currentSplit >= 0) {
                UITableViewCell *oldCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentSplit inSection:indexPath.section]];
                oldCell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    } else {
        BillUser *user = [self.userList objectAtIndex:indexPath.row];
    
        if([self.item.users containsObject:user]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.item removeUser:user];
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.item addUser:user];
        }
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark NameEditorDelegate
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            self.item.name = @"Drink";
            break;
        case 1:
            self.item.name= @"Appetizer";
            break;            
        case 2:
           self.item.name = @"Entree";
            break;            
        case 3:
            self.item.name= @"Dessert";
            break;            
        case 4:
            self.item.name = @"Coupon";
            break;            
        default:
            return;
    }
    
    self.nameEdit.text = self.item.name;
    self.dataSaved = NO;
}

@end
