//
//  SplitMyBillContactDebtViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/21/12.
//

#import "SplitMyBillContactDebtViewController.h"
#import "Debt.h"
#import "SplitMyBillDebtEditorViewController.h"
#import "BillLogic.h"
#import "SplitMyBillAppDelegate.h"
#import "ContactContactInfo.h"

static NSString *const appID = @"1161";
static NSString *const secret = @"6EgYZEH4qYm8fWT9N6yYHkBWyT5JtAe6";

@interface SplitMyBillContactDebtViewController () <DebtEditorDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *labelOwesDesc;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *labelOwes;

@property (strong, nonatomic) Debt *debt;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSInteger debtRow;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) bool paypalEnabled;
@property (nonatomic) bool venmoEnabled;

- (IBAction)buttonAdd:(id)sender;
@end

@implementation SplitMyBillContactDebtViewController
@synthesize contact = _contact;
@synthesize debt = _debt;
@synthesize debtRow = _debtRow;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize paypalEnabled = _paypalEnabled;
@synthesize venmoEnabled = _venmoEnabled;

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Debt" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
    NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"settled" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort2, sort, nil]];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"contact == %@", self.contact.objectID]];
    [fetchRequest setFetchBatchSize:20];

    [NSFetchedResultsController deleteCacheWithName:@"UserDebts"];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
        managedObjectContext:self.managedObjectContext
        sectionNameKeyPath:@"settled"
        cacheName:@"UserDebts" ];

    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
    
}

- (IBAction)buttonSettle:(id)sender {
    NSInteger index = 1;
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Settle Debts" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    
    //create the actionsheet first
    [action addButtonWithTitle:@"Settle In Full"];
    
    [action addButtonWithTitle:@"Cancel"];
    [action setCancelButtonIndex:index];
    
    [action showInView:self.view];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"edit debt"])
    {
        SplitMyBillDebtEditorViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        controller.debt = self.debt;
    }
}

- (IBAction)buttonAdd:(id)sender {
    //create a new debt object
    self.debt = [NSEntityDescription insertNewObjectForEntityForName:@"Debt" inManagedObjectContext:self.managedObjectContext];
    self.debt.created = [[NSDate alloc] init];
    self.debt.contact = self.contact;
    self.debtRow = -1;
    
    [self performSegueWithIdentifier:@"edit debt" sender:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)configureOwesField {
    //format NSNumber to doller amount...
    NSInteger owes = [self.contact.owes integerValue];
    if(owes != 0) {
        if(owes>0) {
            self.labelOwesDesc.title = @"Owes you:";
            self.labelOwes.tintColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        } else {
            self.labelOwesDesc.title = @"You owe:";
            self.labelOwes.tintColor = [UIColor colorWithRed:0.9 green:0.0 blue:0.0 alpha:1.0];
        }
        
        self.labelOwes.title = [BillLogic formatMoneyWithInt:owes];
    } else {
        
        self.labelOwes.title = @"";
        self.labelOwesDesc.title = @"No current debts";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
}
                                 
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //self.navigationItem.title = self.contact.name;
    self.title = self.contact.name;
    
    self.fetchedResultsController = nil;
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debt Error" message:@"Error loading debts" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];

        return;
	}
    self.paypalEnabled = NO;
    
    [self configureOwesField];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setLabelOwes:nil];
    [self setLabelOwesDesc:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}

#pragma mark - Debt Editor Delegate
- (void) DebtEditor:(id)Editor Close:(bool)SaveChanges
{
    if(SaveChanges) {        
        //update the owed amount
        NSInteger owes = [self.contact.owes integerValue];
        owes += [self.debt.amount integerValue];
        self.contact.owes = [NSNumber numberWithInteger:owes];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error saving debt" message:@"An error occurred while attempting to save your changes" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alert show];
            
            //leave them where they are
            return;
            
        } else {
            //refresh the table row
            if(self.debtRow == -1) {
                self.debtRow = [self.tableView numberOfRowsInSection:0];
            }
        }
        [self configureOwesField];
    } else {
        [self.managedObjectContext rollback];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
    self.debt = nil;
    self.debtRow = -1;
}

#pragma  mark - Table View DataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 220, 20)];
    
    id<NSFetchedResultsSectionInfo> sectionInfo =
    [[self.fetchedResultsController sections] objectAtIndex:section];
    
    if([sectionInfo.name isEqualToString:@"0"])
        label.text = @" Current Debts";
    else
        label.text  = @" Settled Debts";

    label.font = [UIFont fontWithName:@"Avenir-Medium" size:15.0f];
    label.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    
    return label;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id  sectionInfo =
    [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Debt *debt = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if([debt.settled boolValue]|| [debt.isSettleEntry boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    //debt.created
    NSDate *date = debt.created;
    
    static NSDateFormatter *format = nil;
    if(format == nil) {
        format = [[NSDateFormatter alloc] init];
        [format setDateStyle:NSDateFormatterShortStyle];
        [format setTimeStyle:NSDateFormatterShortStyle];
    }
    NSString *dateValue = [format stringFromDate:date];
    
    if(debt.note)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@", dateValue, debt.note];
    else
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", dateValue];

    [cell setNeedsLayout];
    
    NSInteger amount = [debt.amount integerValue];
    cell.textLabel.text = [BillLogic formatMoneyWithInt:amount];
    
    if(amount >= 0) {
        cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    } else {
        cell.textLabel.textColor = [UIColor colorWithRed:0.9 green:0.0 blue:0.0 alpha:1.0];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"debt cell";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Set up the cell...
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.debt = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.debtRow = indexPath.row;

    if ([self.debt.settled boolValue] || [self.debt.isSettleEntry boolValue])
    {
        //don't allow editing these entries
        self.debt = nil;
        self.debtRow = -1;
        return;
    }
    
    //remove this amount, add back in when saved
    NSInteger owes = [self.contact.owes integerValue];
    owes -= [self.debt.amount integerValue];
    self.contact.owes = [NSNumber numberWithInteger:owes];
    
    [self performSegueWithIdentifier:@"edit debt" sender:self];
    
    //unselect the cell
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        //delete this debt record
        Debt *debt = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        NSInteger owes = [self.contact.owes integerValue];
        owes -= [debt.amount integerValue];
        self.contact.owes = [NSNumber numberWithInteger:owes];
        //update what the user owes
        [self.managedObjectContext deleteObject:debt];
        
        NSError *error;
        if(![self.managedObjectContext save:&error]) {
            NSLog(@"Couldn't delete: %@", [error localizedDescription]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error deleting debt" message:@"An error occurred while attempting to save your changes." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alert show];
            return;
        }
        [self configureOwesField];
    }
}

#pragma mark - Fetched Controller Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    if (type == NSFetchedResultsChangeInsert) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
    } else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

#pragma mark - UIActionSheetDelegate
- (void) settleDebtsFor:(NSInteger) amount withNote:(NSString *)note
{
    //get a list of all non settled debts and mark as settled
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Debt"
                                              inManagedObjectContext:self.managedObjectContext];
    
    //mark all open debts as settled
    NSMutableArray *parr = [[NSMutableArray array] init];
    [parr addObject:[NSPredicate predicateWithFormat:@"contact == %@", self.contact.objectID]];
    [parr addObject:[NSPredicate predicateWithFormat:@" settled == %@", [NSNumber numberWithBool:NO]]];
    
    [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:parr]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *debts = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if(error){
        NSLog(@"Couldn't load debts: %@", [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debt Settle Error 01" message:@"An error occurred while attempting to settle this debt.  Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    for(Debt *debt in debts) {
        debt.settled = [NSNumber numberWithBool:YES];
    }
    
    //make a new entry representing the settlement
    Debt *debt = [NSEntityDescription insertNewObjectForEntityForName:@"Debt" inManagedObjectContext:self.managedObjectContext];
    
    debt.created = [[NSDate alloc] init];
    debt.contact = self.contact;
    debt.note = note;
    debt.amount = [NSNumber numberWithInteger:([self.contact.owes integerValue] * -1)];
    debt.settled = [NSNumber numberWithBool:YES];
    debt.isSettleEntry = [NSNumber numberWithBool:YES];
    
    NSInteger owes = [self.contact.owes integerValue];
    self.contact.owes = [NSNumber numberWithInteger:(owes - amount)];
    
    if(![self.managedObjectContext save:&error]) {
        [self.managedObjectContext rollback];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debt Settle Error 02" message:@"An error occured attempting to settle this debt. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    [self configureOwesField];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        [self settleDebtsFor:[self.contact.owes integerValue] withNote:@"Settled debts in full"];

    }
    NSInteger offset = 0;
    if(self.paypalEnabled) {
        if(buttonIndex == 1 + offset) {
            //[ppMEP checkoutWithPayment:currentPayment];
        }
        offset--;
    }
    
    if(self.venmoEnabled) {
        /*
        offset++;
        if(buttonIndex == 2 + offset) {
            //id propertyValue = [(MyAppDelegate *)[[UIApplication sharedApplication] delegate] myProperty];
            
            VenmoClient *venmoClient = [(SplitMyBillAppDelegate *)[[UIApplication sharedApplication] delegate] venmoClient];
            
            //VenmoClient *venmoClient = [VenmoClient clientWithAppId:appID secret:secret];
            VenmoTransaction *vtrans = [[VenmoTransaction alloc] init];
            
            NSInteger temp = [self.contact.owes integerValue];
            bool isNeg = (temp < 0);
            
            if(isNeg) {
                temp *= -1;
                vtrans.type = VenmoTransactionTypePay;
            } else {
                vtrans.type = VenmoTransactionTypeCharge;
            }
            vtrans.amount = [NSDecimalNumber decimalNumberWithMantissa:temp exponent:-2 isNegative:NO];
            vtrans.note = @"settle debts from SplitMyBill";
            
            ContactContactInfo *info = self.contact.contactinfo;
            if(info) {
                if([info.email length] > 0)
                    vtrans.toUserHandle = info.email;
                else if([info.phone length] > 0)
                    vtrans.toUserHandle = info.phone;
                else {
                    //throw an error, can't use venmo
                    return;
                }
            }
            
            VenmoViewController *cont = [venmoClient viewControllerWithTransaction:vtrans];
            if(cont)
            {
                [self presentModalViewController:cont animated:YES];
            }
        }
        */
    }

}

- (void) outsideDebtSettlementForAmount:(NSDecimalNumber *)amount toUser:(NSString *)userID withNote:(NSString *)note
{
    //self.contact.venmoID = userID;
    NSInteger paid = [[amount decimalNumberByMultiplyingByPowerOf10:2] integerValue];
    
    [self settleDebtsFor:paid withNote:note];
}

@end
