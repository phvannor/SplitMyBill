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

@interface SplitMyBillItemEditorViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *coupon;
@property (weak, nonatomic) IBOutlet UIButton *buttonSelectAll;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollSplit;
@property (weak, nonatomic) IBOutlet UITextField *nameEdit;
@property (nonatomic) bool dataSaved;
@property (nonatomic) bool drillingIn;
@property (nonatomic) NSInteger valueInCents;

- (IBAction)buttonNavigationBack;
- (IBAction)deleteClose:(id)sender;
- (IBAction)accept:(id)sender;
- (IBAction)addNewPress:(id)sender;

@end

@implementation SplitMyBillItemEditorViewController

@synthesize cost = _cost;
@synthesize coupon = _coupon;
@synthesize buttonSelectAll = _buttonSelectAll;
@synthesize scrollSplit = _scrollSplit;
@synthesize delegate = _delegate;
@synthesize userList = _userList;
@synthesize nameEdit = _nameEdit;
@synthesize tableView = _tableView;
@synthesize dataSaved = _dataSaved;
@synthesize item = _item;
@synthesize drillingIn = _drillingIn;
@synthesize valueInCents = _valueInCents;

- (IBAction)buttonNavigationBack {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.drillingIn = YES;
    if([segue.identifier isEqualToString:@"edit name"]) {
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setName:self.item.name];
    }
}

- (IBAction) nameChanged:(UITextField *)sender {
    self.item.name = sender.text;
    self.dataSaved = NO;
}

- (IBAction)accept:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
    
    if(self.scrollSplit)
        self.scrollSplit.contentOffset = CGPointMake((self.item.split - 1) * 72, 0);    
    
    if(self.userList.count > 1) {
        if(reload)
            [self.tableView reloadData];
    }
    
    self.dataSaved = NO;    
    [self.coupon setOn:self.item.isDiscount];
}

- (void)saveData {
    //save data & close the form    
    self.item.cost = self.valueInCents;
    self.item.name = self.nameEdit.text;
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

- (IBAction)couponOn:(UISwitch *)sender {
    self.item.isDiscount = sender.isOn;
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
    
    //[self performSegueWithIdentifier:@"edit name" sender:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if(self.userList.count == 1) {
        self.scrollSplit.frame = CGRectMake(2, 350, 316, 63);
        
        self.scrollSplit.contentSize = CGSizeMake(965, 63);
         for(NSInteger i = 0; i < 10; i++) {
             UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(72*i, 0, 72, 63)];
             label.textAlignment = UITextAlignmentCenter;
             label.opaque = NO;
             label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
             label.textColor = [UIColor whiteColor];
             label.font = [UIFont systemFontOfSize:20];
             label.text = [NSString stringWithFormat:@"%d", i+1];

             [self.scrollSplit addSubview:label];
        }
    }
    
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
    [self setCoupon:nil];
    [self setButtonSelectAll:nil];
    [self setScrollSplit:nil];
    [self setNameEdit:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"user name";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
    BillUser *user =[self.userList objectAtIndex:indexPath.row];
    
    UILabel *label = (UILabel *) [cell viewWithTag:2];
    label.text = user.abbreviation;

    UIImageView *check = (UIImageView *)[cell viewWithTag:1];
    check.hidden = ![self.item.users containsObject:user];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.userList.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 20)];
    label.text = @" Shared";
    label.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0f];
    
    return label;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //add user to list
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIImageView *check = (UIImageView *)[cell viewWithTag:1];
    BillUser *user = [self.userList objectAtIndex:indexPath.row];
    if([self.item.users containsObject:user]) {
        check.hidden = YES;
        [self.item removeUser:user];
    } else {
        check.hidden = NO;
        [self.item addUser:user];
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

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate && self.item) {
        CGPoint offset = scrollView.contentOffset;
        NSUInteger step = (offset.x + 36) / 72;
        self.item.split = step + 1;        
        offset.x = step * 72;   
        [self.scrollSplit setContentOffset:offset animated:YES];
        //self.scrollSplit.contentOffset = offset;        
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(self.item) {
        CGPoint offset = scrollView.contentOffset;
        NSUInteger step = (offset.x + 36) / 72;
        self.item.split = step + 1;    
        offset.x = step * 72;   
        [self.scrollSplit setContentOffset:offset animated:YES];
        //self.scrollSplit.contentOffset = offset;    
    }
}
@end
