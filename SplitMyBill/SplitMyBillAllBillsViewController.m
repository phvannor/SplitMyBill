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
#import "SMBBillNavigationViewController.h"

@interface SplitMyBillAllBillsViewController () <NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *bills;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
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
    self.editBill = [self.delegate BillListCreateBill:self];
    [self performSegueWithIdentifier:@"bill" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"bill"]) {
         self.logic = [[BillLogic alloc] initWithBill:self.editBill andContext:self.managedObjectContext];        
        
        SMBBillNavigationViewController *controller = segue.destinationViewController;
        controller.bill = self.editBill;
        controller.billlogic = self.logic;
        controller.managedObjectContext = self.managedObjectContext;
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (self.bills != nil) {
        return self.bills;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Bill" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
    fetchRequest.sortDescriptors = @[sort];
    fetchRequest.fetchBatchSize = 20;
    
    [NSFetchedResultsController deleteCacheWithName:@"AllBills"];
    NSFetchedResultsController *fetchResults =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
        managedObjectContext:self.managedObjectContext
        sectionNameKeyPath:nil
        cacheName:@"AllBills" ];
    
    self.bills = fetchResults;
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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.bills = nil;
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Loading Bills" message:@"An error occurred attempting to load your bills" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [alert show];
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
	}
    
    self.title = @"Bills";
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // We can close this form
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

// Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         // Delete the row from the data source
         [self.managedObjectContext deleteObject:[self.bills objectAtIndexPath:indexPath]];
     }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.editBill = [self.bills objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"bill" sender:self];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Fetched Controller Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
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
    [self.tableView endUpdates];
}

@end
