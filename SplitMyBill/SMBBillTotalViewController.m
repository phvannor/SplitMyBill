//
//  SMBBillTotalViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/10/13.
//
//

#import "SMBBillTotalViewController.h"

@interface SMBBillTotalViewController ()

@end

@implementation SMBBillTotalViewController
@synthesize logic = _logic;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 1)
        return 5;
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSInteger amount = 0;
    if(indexPath.section == 0) {
        cell.textLabel.text = @"Actual";
        cell.detailTextLabel.text = [BillLogic formatMoney:[self.logic totalWhenRoundedTo:0]];
    } else {
        switch (indexPath.row) {
            case 0:
                amount = 5;
                break;
            case 1:
                amount = 10;
                break;
            case 2:
                amount = 25;
                break;
            case 3:
                amount = 50;
                break;
            case 4:
                amount = 100;
                break;
        }
        cell.textLabel.text = [BillLogic formatMoney:[NSDecimalNumber decimalNumberWithMantissa:amount exponent:-2 isNegative:NO]];
        cell.detailTextLabel.text = [BillLogic formatMoney:[self.logic totalWhenRoundedTo:amount]];
    }
    
    if(self.logic.roundingAmount == amount) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger amount = 0;
    if(indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                amount = 5;
                break;
            case 1:
                amount = 10;
                break;
            case 2:
                amount = 25;
                break;
            case 3:
                amount = 50;
                break;
            case 4:
                amount = 100;
                break;
        }
    }
    
    self.logic.roundingAmount = amount;
    [self.navigationController popViewControllerAnimated:YES];
}
@end
