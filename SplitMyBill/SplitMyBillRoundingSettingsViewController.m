//
//  SplitMyBillRoundingSettingsViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SplitMyBillRoundingSettingsViewController.h"

@interface SplitMyBillRoundingSettingsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSInteger amount;
@end

@implementation SplitMyBillRoundingSettingsViewController
@synthesize roundingDataSource = _dataSource;
@synthesize tableView = _tableView;
@synthesize amount = _amount;

- (IBAction)buttonNavigationBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)buttonSave:(id)sender {
    [self.roundingDataSource setRoundingAmount:self.amount];
    [self buttonNavigationBack:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.amount = [self.roundingDataSource roundingAmount];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return 2;
        case 1:
            if(self.amount > 0)
                return 5; //5,10,25,50,1.00
            else
                return 0;
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    NSInteger rowValue = 0;    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Exact";
                    if(self.amount ==0)
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    break;
                case 1:
                    cell.textLabel.text = @"Round Overall Total";
                    if(self.amount!=0)
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    break;
                //case 2:
                //    cell.textLabel.text = @"Round Overall Total";
                //    break;                    
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    rowValue = 5;
                    cell.textLabel.text = @"$0.05";
                    break;
                case 1:
                    rowValue = 10;
                    cell.textLabel.text = @"$0.10";
                    break;
                case 2:
                    rowValue = 25;
                    cell.textLabel.text = @"$0.25";
                    break;
                case 3:
                    rowValue = 50;
                    cell.textLabel.text = @"$0.50";
                    break;
                case 4:
                    rowValue = 100;
                    cell.textLabel.text = @"$1.00";
                    break;
            }
            if(rowValue == self.amount)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        default:
            break;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Method";
            break;
        case 1:
            if(self.amount>0)
                return @"Round up to";
            break;
    }
    
    return nil;
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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0:
            //unselect all the other rows
            cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.selected = NO;
            //unselect the other selected one
            for(NSUInteger i = 0; i<2;i++) {
                if(indexPath.row != i) {
                    cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            if(indexPath.row == 1){
                self.amount = 25;
            } else {
                self.amount = 0;
            }
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:YES];
            break;
        case 1:
            cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.selected = NO;
            
            switch (indexPath.row) {
                case 0:
                    self.amount = 5;
                    break;
                case 1:
                    self.amount = 10;
                    break;
                case 2:
                    self.amount = 25;
                    break;
                case 3:
                    self.amount = 50;
                    break;
                case 4:
                    self.amount = 100;
                    break;
                default:
                    break;
            }
            
            //unselect the other selected one
            for(NSUInteger i = 0; i<5;i++) {
                if(indexPath.row != i) {
                    cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            
        default:
            break;
    }
}

@end
