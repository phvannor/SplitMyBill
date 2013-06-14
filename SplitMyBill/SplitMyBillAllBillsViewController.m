//
//  SplitMyBillAllBillsViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/14/13.
//
//

#import <CoreData/CoreData.h>
#import "SplitMyBillAllBillsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Bill.h"
#import "BillLogic.h"
#import "SplitMyBillEditorViewController.h"
#import "SplitMyBillQuickSplitViewController.h"

@interface SplitMyBillAllBillsViewController () <NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *bills;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)buttonNavigationBack;

@property (nonatomic, strong) Bill *editBill;
@property (nonatomic, strong) BillLogic *logic;
@end

@implementation SplitMyBillAllBillsViewController
@synthesize bills = _bills;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize tableView = _tableView;
@synthesize editBill = _editBill;
@synthesize logic = _logic;

- (IBAction)addBill:(id)sender {
    [self performSegueWithIdentifier:@"add bill" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"to bill"]) {
        self.logic = [[BillLogic alloc] initWithBill:self.editBill andContext:self.managedObjectContext];
        
        SplitMyBillEditorViewController *controller = segue.destinationViewController;
        controller.bill = self.editBill;
        controller.billlogic = self.logic;
        controller.managedObjectContext = self.managedObjectContext;
    } else if([segue.identifier isEqualToString:@"simple bill"]) {
        self.logic = [[BillLogic alloc] initWithBill:self.editBill andContext:self.managedObjectContext];
        
        SplitMyBillQuickSplitViewController *controller = segue.destinationViewController;
        //controller.bill = self.editBill;
        controller.logic = self.logic;
        controller.managedObjectContext = self.managedObjectContext;
        
    } else if([segue.identifier isEqualToString:@"add bill"]) {
        
        SplitMyBillEditorViewController *controller = segue.destinationViewController;
        
        //create new bill entity...
        Bill * bill = [NSEntityDescription insertNewObjectForEntityForName:@"Bill" inManagedObjectContext:self.managedObjectContext];
        
        //defaults for a bill
        bill.title = @"";
        bill.created = [NSDate date];
        bill.type = [NSNumber numberWithInt:1];
        bill.taxInDollars = [NSNumber numberWithBool:NO];
        bill.type = [NSNumber numberWithInt:0];
        self.editBill = bill;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *string = [defaults objectForKey:@"taxRate"];
        if(!string) string = @"0";
        bill.tax = [NSDecimalNumber decimalNumberWithString:string];
        
        string = [defaults objectForKey:@"tipRate"];
        if(!string) string = @"0";
        bill.tip = [NSDecimalNumber decimalNumberWithString:string];
        bill.tipInDollars = [NSDecimalNumber numberWithBool:NO];
        
        self.logic = [[BillLogic alloc] initWithBill:bill andContext:self.managedObjectContext];
        self.logic.tax = bill.tax;
        self.logic.tip = bill.tip;
        self.logic.roundingAmount = [defaults integerForKey:@"roundValue"];
        
        //save the newly created bill
        NSError *error;
        if(![self.managedObjectContext save:&error]) {
            //todo: error condition here
            ///!!!
            ///
        }
        
        //self defaults to being present...
        BillUser *user = [self makeUserSelfwithDefaults:nil];
        [self.logic addUser:user];
        controller.bill = bill;
        
        self.logic.bill = bill;
        controller.billlogic = self.logic;
        controller.managedObjectContext = self.managedObjectContext;
        
        return;
    }
}

- (IBAction)buttonNavigationBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (self.bills != nil)
        return self.bills;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Bill" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setFetchBatchSize:20];
    
    [NSFetchedResultsController deleteCacheWithName:@"AllBills"];
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
        managedObjectContext:self.managedObjectContext
        sectionNameKeyPath:nil
        cacheName:@"AllBills" ];
    
    self.bills = theFetchedResultsController;
    self.bills.delegate = self;
    
    return self.bills;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.bills = nil;
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Loading Bills" message:@"An error occurred attempting to load your bills" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [alert show];
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
	}
    
    self.tableView.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:1.0f].CGColor;
    self.tableView.layer.borderWidth = 1.0f;
    self.title = @"Bills";
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1; //[self.bills sections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id  sectionInfo = [[self.bills sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Bill  *bill = [self.bills objectAtIndexPath:indexPath];

    UILabel *label = (UILabel *)[cell viewWithTag:10];
    if(bill.title.length > 0)
        label.text = bill.title;
    else
        label.text = @"Bill";
    
    label = (UILabel *)[cell viewWithTag:11];
    
    // A date formatter for the time stamp.
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    label.text = [dateFormatter stringFromDate:bill.created];
    
    label = (UILabel *)[cell viewWithTag:12];
    label.text = [BillLogic formatMoneyWithInt:[bill.total integerValue]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"bill";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

// Override to support editing the table view.
/*
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 }
 }
 */

// Override to support rearranging the table view.
/*
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 }
 
 - (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //self.editContact = [self.contactList objectAtIndexPath:indexPath];
    //[self performSegueWithIdentifier:@"edit contact" sender:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.editBill = [self.bills objectAtIndexPath:indexPath];
    if([self.editBill.type integerValue] == 1) {
        [self performSegueWithIdentifier:@"simple bill" sender:self];
    } else {
        [self performSegueWithIdentifier:@"to bill" sender:self];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    /*
    //handle pulling in from actual contact record
    if(buttonIndex == 0) {
        ABPeoplePickerNavigationController *picker =
        [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        
        [self presentViewController:picker animated:YES completion:NULL];
    } else if (buttonIndex == 1) {
        //manual contact
        //create a person and contact info object and send them to the editor
        NSNumber *num = [NSNumber numberWithInt:kABRecordInvalidID];
        Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact"  inManagedObjectContext:self.managedObjectContext];
        contact.uniqueid = num;
        
        //blank name and initials
        ContactContactInfo *cinfo = [NSEntityDescription insertNewObjectForEntityForName:@"ContactContactInfo" inManagedObjectContext:self.managedObjectContext];
        contact.contactinfo = cinfo;
        
        //ok now take them to the editor view
        self.editContact = contact;
        [self performSegueWithIdentifier:@"edit contact" sender:self];
    }
     */
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
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

#pragma mark - Utility Functions
- (BillUser *)makeUserSelfwithDefaults:(NSUserDefaults *)defaults
{
    if(!defaults)
        defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *defaultUser = [defaults objectForKey:@"default user"];
    BillUser *user;
    if(!defaultUser) {
        user = [[BillUser alloc] initWithName:@"Me" andAbbreviation:@"ME"];
    } else {
        user = [NSKeyedUnarchiver unarchiveObjectWithData:defaultUser];
    }
    user.isSelf = YES;
    
    return user;
}

@end
