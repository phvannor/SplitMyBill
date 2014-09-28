//
//  SplitMyBillFreeSettingsTableViewController.m
//  SplitMyBill Free
//
//  Created by Phillip Van Nortwick on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define TAX_SETTING @"taxRate"
#define TIP_SETTING @"tipRate"
#define ROUND_SETTING @"roundValue"

#define NUM_SECTIONS 6
#define SECTION_TIPTAX 0
#define SECTION_ROUNDING 1
#define SECTION_DISCOUNTS 2
#define SECTION_DISPLAY 3
#define SECTION_USER 4
#define SECTION_LINKS 5

#import "SplitMyBillFreeSettingsTableViewController.h"
#import "TipViewController.h"
#import "TaxViewController.h"
#import "SplitMyBillRoundingSettingsViewController.h"
#import "TestFlight.h"
#import "SplitMyBillContactEditorViewController.h"
#import "TaxViewController.h"
#import "TipViewController.h"

@interface SplitMyBillFreeSettingsTableViewController () <TipViewDataSource, TaxViewDataSource, RoundingViewDataSource, ContactEditorDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) BillUser *user;

- (IBAction)sendFeedback:(id)sender;
@end

@implementation SplitMyBillFreeSettingsTableViewController
@synthesize user = _user;

- (IBAction)sendFeedback:(id)sender
{
    
}

- (bool) getDiscountsPreTax
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    bool isPretax = [settings boolForKey:@"DiscountsPreTax"];
    return isPretax;
}

- (void) changeDiscounts:(bool)toPreTax {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:toPreTax forKey:@"DiscountsPreTax"];
    [settings synchronize];
}

- (bool) getUserTotalOptionSelected:(NSUInteger)row {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    bool simpleMode = [settings boolForKey:@"UserTotalSimple"];
    
    if(row == 0)
        return simpleMode;
    else
        return !simpleMode;
}

- (IBAction)buttonNavigationBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) changeUserTotalDisplayToSimple:(bool)simple {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:simple forKey:@"UserTotalSimple"];
    [settings synchronize];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"edit user"]) {
        self.user.isSelf = YES;
        SplitMyBillContactEditorViewController *vc = (SplitMyBillContactEditorViewController *)segue.destinationViewController;
        vc.delegate = self;
        vc.user = self.user;
        
    } else if([segue.identifier isEqualToString:@"rounding"]) {
        SplitMyBillRoundingSettingsViewController *vc = (SplitMyBillRoundingSettingsViewController *)segue.destinationViewController;
        vc.roundingDataSource = self;
    } else if([segue.identifier isEqualToString:@"edit tip"]){
        [(TipViewController *)segue.destinationViewController setDataSource:self];
    } else if([segue.identifier isEqualToString:@"edit tax"]) {
        [(TaxViewController *)segue.destinationViewController setDataSource:self];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    if(self.user.isDirty) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.user] forKey:@"default user"];    
        [defaults synchronize];
        
        NSArray *rows = @[[NSIndexPath indexPathForRow:0 inSection:3]];
        [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:NO];        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *defaultUser = [defaults objectForKey:@"default user"];
    
    if(!defaultUser) {
        self.user = [[BillUser alloc] initWithName:@"Me" andAbbreviation:@"Me"];
        self.user.isDirty = NO;
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.user] forKey:@"default user"];
        [defaults synchronize];
    } else {
        self.user = [NSKeyedUnarchiver unarchiveObjectWithData:defaultUser];
    }
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //two rows, tip & tax
    switch (section) {
        case SECTION_TIPTAX:
            return 2;
            
        case SECTION_ROUNDING:
            return 1;
        
        case SECTION_DISCOUNTS:
            return 2;
            
        case SECTION_DISPLAY:
            return 2;

        case SECTION_USER:
            return 1;
        
        case SECTION_LINKS:
            return 1;
            
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_TIPTAX:
            return @"Tip & Tax";
            break;
        case SECTION_ROUNDING:
            return @"Rounding Method";
            break;            
        case SECTION_DISPLAY:
            return @"User Total Display:";
        case SECTION_LINKS:
            return @"Links";
        case SECTION_DISCOUNTS:
            return @"Discounts:";
        default:
            return @"Default User";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];

    static NSString *CellIdentifier = @"setting info";
    UITableViewCell *cell;
    
    // Configure the cell...
    switch (indexPath.section) {
        case SECTION_TIPTAX:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if(indexPath.row == 1) {
                cell.textLabel.text = @"Tip";
                NSDecimalNumber *tip = [self.tipPercent decimalNumberByMultiplyingByPowerOf10:2];
                cell.detailTextLabel.text = [[formatter stringFromNumber: tip] stringByAppendingString:@"%"];
            } else if(indexPath.row == 0) {
                cell.textLabel.text = @"Tax";
                NSDecimalNumber *tax = [self.taxPercent decimalNumberByMultiplyingByPowerOf10:2];
                cell.detailTextLabel.text = [[formatter stringFromNumber: tax] stringByAppendingString:@"%"];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;            
            break;
        case SECTION_ROUNDING:
            cell = [tableView dequeueReusableCellWithIdentifier:@"setting simple"];
            
            if(self.roundingAmount > 0) {
                if(self.roundingAmount == 100) {
                    cell.textLabel.text = @"Round Up ($1.00)";
                } else if(self.roundingAmount == 5) {
                    cell.textLabel.text = @"Round Up ($0.05)";
                } else {
                    cell.textLabel.text = [@"Round Up (" stringByAppendingFormat:@"$0.%ld)", (long)self.roundingAmount];
                }
            } else {
                cell.textLabel.text = @"Exact";                
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case SECTION_DISCOUNTS:
            cell = [tableView dequeueReusableCellWithIdentifier:@"setting simple"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(indexPath.row == 0) {
                cell.textLabel.text = @"Apply before tax";
                if([self getDiscountsPreTax])
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.textLabel.text = @"Apply after tax";
                if(![self getDiscountsPreTax])
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
            
        case SECTION_DISPLAY:
            cell = [tableView dequeueReusableCellWithIdentifier:@"setting simple"];
            if(indexPath.row == 0)
                cell.textLabel.text = @"Tip+Total";
            else
                cell.textLabel.text = @"Total, Tip, and Tip+Total";
            
            if([self getUserTotalOptionSelected:indexPath.row])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
            
        case SECTION_USER:
            cell = [tableView dequeueReusableCellWithIdentifier:@"setting simple"];
            cell.textLabel.text = [self.user.name stringByAppendingFormat:@" (%@)",self.user.abbreviation];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;            
            break;
            
        case SECTION_LINKS:
            cell = [tableView dequeueReusableCellWithIdentifier:@"setting simple"];
            cell.textLabel.text = @"Rate on iTunes";
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    //trigger segue setup in xcode
    switch (indexPath.section) {
        case SECTION_TIPTAX:
            if(indexPath.row == 1) {
                [self performSegueWithIdentifier:@"edit tip" sender:self];
            } else if (indexPath.row == 0) {
                [self performSegueWithIdentifier:@"edit tax" sender:self];
            }
            break;
        case SECTION_ROUNDING:
            [self performSegueWithIdentifier:@"rounding" sender:self];
            break;
        case SECTION_DISPLAY:
            //change which one is checked
            //UITableViewCell *cell = nil;
            cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.selected = NO;
            if(indexPath.row == 0) {
                [self changeUserTotalDisplayToSimple:YES];
                cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:indexPath.section]];
            } else {
                [self changeUserTotalDisplayToSimple:NO];
                cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
            
        case SECTION_USER:
            [self performSegueWithIdentifier:@"edit user" sender:self];
            break;
            
        case SECTION_DISCOUNTS:
            cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.selected = NO;
            [self changeDiscounts:(indexPath.row == 0)];
            cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:((indexPath.row + 1)%2) inSection:indexPath.section]];
            cell.accessoryType =UITableViewCellAccessoryNone;
            break;
            
        case SECTION_LINKS:
            cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.selected = NO;
            //launch user to itunes rating screen?
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=551859216"]];
            break;
        default:
            break;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - TipViewDataSource
@synthesize tipAmount = _tipAmount;
- (NSDecimalNumber *) tipPercent {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *tip = (NSString *)[settings objectForKey:TIP_SETTING];    
    if(!tip) return [NSDecimalNumber zero];    
    return [NSDecimalNumber decimalNumberWithString:tip];
}

- (void) setTipPercent:(NSDecimalNumber *)tipPercent {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[tipPercent stringValue] forKey:TIP_SETTING];
    [settings synchronize];

    [self.tableView reloadData];
}
- (bool) tipInDollars {
    return NO;
}
- (NSDecimalNumber *)totalToTipOn {
    return nil;
}

#pragma mark - TaxViewDataSource
- (bool) inDollars {
    return NO;
}
- (void) setInDollars:(bool)inDollars {
    return;
}

@synthesize taxAmount = _taxAmount;
- (NSDecimalNumber *) taxPercent {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *tax = (NSString *)[settings objectForKey:TAX_SETTING];    
    if(!tax) return [NSDecimalNumber zero];
    return [NSDecimalNumber decimalNumberWithString:tax];
}

- (void) setTaxPercent:(NSDecimalNumber *)taxPercent {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[taxPercent stringValue] forKey:TAX_SETTING];
    [settings synchronize];
    
    [self.tableView reloadData];
}

@synthesize roundingAmount = _roundingAmount;
- (NSInteger) roundingAmount {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    _roundingAmount = [settings integerForKey:ROUND_SETTING];
    return _roundingAmount;
}

- (void) setRoundingAmount:(NSInteger)roundingAmount {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setInteger:roundingAmount forKey:ROUND_SETTING];
    [settings synchronize];
    
    [self.tableView reloadData];    
}

#pragma mark - ContactEditorDelegate
//- (void) formClose:(bool)SaveChanges {
- (void) ContactEditor:(id)Editor Close:(bool)SaveChanges
{
    if(SaveChanges) {
        self.user.isDirty = YES;
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *defaultUser = [defaults objectForKey:@"default user"];
        if(!defaultUser) {
            self.user = [[BillUser alloc] initWithName:@"Me" andAbbreviation:@"ME"];
        } else {
            self.user = [NSKeyedUnarchiver unarchiveObjectWithData:defaultUser];
        }
    }
}

- (void) ContactEditorDelete:(id)Editor {
    //restore back to defaults
    [self.navigationController popViewControllerAnimated:YES];
}

@end
