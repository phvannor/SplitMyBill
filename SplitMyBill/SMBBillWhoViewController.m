//
//  SMBBillWhoViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/9/13.
//
//

#import "SMBBillWhoViewController.h"
#import "SMBBillNavigationViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "SplitMyBillContactEditorViewController.h"

#define SECTION_SELF 0
#define SECTION_CONTACTS 1
#define SECTION_GENERICS 2

@interface SMBBillWhoViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, ABPeoplePickerNavigationControllerDelegate, ContactEditorDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) Contact *editContact;
@property (nonatomic, strong) BillUser *editUser;
@property (nonatomic, strong) NSIndexPath *editPath;

@property (nonatomic, retain) NSFetchedResultsController *contactListController;
@property (nonatomic) NSInteger genericCount;

@property (nonatomic, weak) IBOutlet UILabel *partySize;
@property (nonatomic, weak) IBOutlet UIButton *buttonContact;
- (IBAction)addContact:(id)sender;
@property (nonatomic, weak) IBOutlet UIButton *buttonGeneric;
- (IBAction)addGeneric:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonNext;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonCancel;

@end

@implementation SMBBillWhoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (IBAction)actionNext:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)actionCancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contactListController = nil;
    NSError *error;
    if (![[self contactListController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    if(self.logic.users.count > 1) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    self.genericCount = self.logic.numberOfGenericUsers + 1;
    self.partySize.text = [NSString stringWithFormat:@"%d", self.logic.userCount];
    
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"edit user"]) {
        if(self.editContact) {
            [segue.destinationViewController setContact:self.editContact];
            [segue.destinationViewController setDelegate: self];
        } else {
            [(SplitMyBillContactEditorViewController *)segue.destinationViewController setUser:self.editUser];
            [segue.destinationViewController setDelegate: self];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PartySelectionDataSource
- (BillLogic *)logic {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.billlogic;
}

- (NSManagedObjectContext *) managedObjectContext {
    SMBBillNavigationViewController *billRoot = (SMBBillNavigationViewController *)self.navigationController;
    return billRoot.managedObjectContext;
}

#pragma mark - PartySelectionDelegate
- (bool) editUser:(BillUser *)user {
    self.editContact = nil;
    self.editUser = user;
    [self performSegueWithIdentifier:@"edit user" sender:self];
    return YES;
}

- (bool) editContact:(Contact *)contact {
    self.editUser = nil;
    self.editContact = contact;
    [self performSegueWithIdentifier:@"edit user" sender:self];
    return YES;
}

@synthesize contactListController = _contactListController;
- (NSFetchedResultsController *)contactListController {
    if (_contactListController != nil) {
        return _contactListController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Contact"
                                   inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:20];
    
    //[NSFetchedResultsController deleteCacheWithName:@"UserSelection"];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:@"UserSelection" ];
    
    _contactListController = theFetchedResultsController;
    _contactListController.delegate = self;
    
    return _contactListController;
    
}

#pragma mark UITableViewDataSource
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SECTION_CONTACTS:
            return @"From Contacts";
        case SECTION_GENERICS:
            return @"Generic Users";
        case SECTION_SELF:
            return @"You";
    }
    
    return @"";
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = [self.contactListController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    
    UILabel *label = (UILabel *)[cell viewWithTag:2];
    label.text = contact.name;
    label = (UILabel *)[cell viewWithTag:3];
    label.text = contact.initials;
    
    UIImageView *image = (UIImageView *)[cell viewWithTag:1];
    image.hidden= ![self.logic hasUserByContact:contact];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"detail cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *label;
    BillUser *user;
    UIImageView *image;
    switch (indexPath.section) {
        case SECTION_CONTACTS:
            [self configureCell:cell atIndexPath:indexPath];
            break;
        case SECTION_GENERICS:
            user = [self.logic getGenericUser:indexPath.row];
            label = (UILabel *)[cell viewWithTag:2];
            label.text = user.name;
            label = (UILabel *)[cell viewWithTag:3];
            label.text = user.abbreviation;
            image = (UIImageView *)[cell viewWithTag:1];
            image.hidden = NO;
            break;
            
        case SECTION_SELF:
            user = [self.logic getSelf];
            image = (UIImageView *)[cell viewWithTag:1];
            image.hidden = !image.hidden;
            if(!user) {
                user = [self makeUserSelfwithDefaults:nil];
                image.hidden = YES;
            } else {
                image.hidden = NO;
            }
            label = (UILabel *)[cell viewWithTag:2];
            label.text = user.name;
            label = (UILabel *)[cell viewWithTag:3];
            label.text = user.abbreviation;
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if([self.logic numberOfGenericUsers] > 0)
        return 3;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == SECTION_CONTACTS) {
        id  sectionInfo = [[self.contactListController sections] objectAtIndex:0]; //fetched results thinks it 0
        return [sectionInfo numberOfObjects];
    } else if(section == SECTION_GENERICS){
        //return the number of generic users we have on the bill
        return self.logic.numberOfGenericUsers;
    } else if(section == SECTION_SELF) {
        return 1;
    }
    
    return 0;
}

#pragma mark UITableViewDelegate
- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.editPath = indexPath;
    if(indexPath.section == SECTION_CONTACTS) {
        Contact *contact = [self.contactListController objectAtIndexPath:[self fecthedObjectIndexPath:indexPath]];
        
        [self editContact:contact];
    } else {
        //copy edit user over to dummy for cancel support
        BillUser *user;
        if(indexPath.section == SECTION_GENERICS)
            user = [self.logic getGenericUser:indexPath.row];
        else
            user = [self getSelf];
        
        self.editUser = [[BillUser alloc] initWithName:user.name andAbbreviation:user.abbreviation];
        self.editUser.phone = user.phone;
        self.editUser.email = user.email;
        self.editUser.isSelf = user.isSelf;
        
        [self editUser:self.editUser];
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(indexPath.section == SECTION_CONTACTS) {
        Contact *contact = [self.contactListController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        UIImageView *image = (UIImageView *)[cell viewWithTag:1];
        image.hidden = !image.hidden;
        if(image.hidden) {
            [self.logic removeUserByContact:contact];
        } else {
            //create a bill user
            BillUser *user = [[BillUser alloc] initWithName:contact.name andAbbreviation:contact.initials];
            user.phone = contact.contactinfo.phone;
            user.email = contact.contactinfo.email;
            user.contact = contact;
            [self.logic addUser:user];
        }
    } else if(indexPath.section == SECTION_GENERICS){
        //can only remove users
        BillUser *user = [self.logic getGenericUser:indexPath.row];
        [self.logic removeUser:user];
        
        if(self.logic.numberOfGenericUsers == 0)
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:YES];
        else
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
    } else if(indexPath.section == SECTION_SELF) {
        UIImageView *image = (UIImageView *)[cell viewWithTag:1];
        image.hidden = !image.hidden;
        if(image.hidden) {
            [self.logic removeUser:[self.logic getSelf]];
        } else {
            [self.logic addUser:[self makeUserSelfwithDefaults:nil]];
        }
    }
    
    NSUInteger userCnt = self.logic.userCount;
    if(self.partySize) {
        self.partySize.text = [NSString stringWithFormat:@"%d", userCnt];
    }
    
    self.buttonContact.enabled = userCnt < 30;
    self.buttonGeneric.enabled = userCnt < 30;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO; //disallow deletion for now
}

#pragma mark - Fetched Controller Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:SECTION_CONTACTS];
    newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:SECTION_CONTACTS];
    
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
                                               arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    
    sectionIndex = SECTION_CONTACTS;
    
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

#pragma mark - Add Buttons...
- (IBAction)addGeneric:(id)sender {
    //we need a unique ID
    if(self.logic.userCount >= 30) {
        //only allow up to 30 users
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Party Size Limit" message:@"You can only have up to 30 people in a party" delegate:self cancelButtonTitle:@"OK"otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    BillUser *user = [[BillUser alloc] initWithName:[NSString stringWithFormat:@"Person %d", self.genericCount] andAbbreviation:[NSString stringWithFormat:@"#%d",self.genericCount]];
    self.genericCount++;
    
    [self.logic addUser:user];
    self.partySize.text = [NSString stringWithFormat:@"%d", self.logic.userCount];
    
    if(self.logic.userCount >= 30) {
        self.buttonContact.enabled = NO;
        self.buttonGeneric.enabled = NO;
    }
    
    NSInteger genCnt = self.logic.numberOfGenericUsers;
    if(genCnt > 0) genCnt--;
    
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:genCnt inSection:SECTION_GENERICS];
    if(self.logic.numberOfGenericUsers == 1)
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:YES];
    else
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newPath] withRowAnimation:YES];
    
    [self.tableView scrollToRowAtIndexPath:newPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    
    [TestFlight passCheckpoint:@"PartyAddGeneric"];
}

- (IBAction)addContact:(id)sender
{
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:NULL];
    [TestFlight passCheckpoint:@"PartyAddContact"];
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

#pragma mark - ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    ABRecordID uniqueID = ABRecordGetRecordID(person);
    NSNumber *myNum = [NSNumber numberWithInteger:uniqueID];
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    //make sure contact isn't already present, if it is put up an error
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact"
                                              inManagedObjectContext:self.managedObjectContext];
    
    [fetch setEntity:entity];
    [fetch setFetchLimit:1];
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"uniqueid == %@", myNum]];
    
    NSError *error;
    NSArray *contacts = [self.managedObjectContext executeFetchRequest:fetch error:&error];
    if(contacts.count == 1) {
        //just select the contact in the list...?
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Contact Already Added" message:@"The selected contact was added previously." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [alert show];
        return NO;
    }
    
    //Generate the contact's name
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString *compositeName;
    NSString *abbreviation = @"";
    if(firstName.length > 1) {
        abbreviation = [firstName substringToIndex:1];
        compositeName = firstName;
    }
    if(lastName.length > 1) {
        abbreviation = [abbreviation stringByAppendingString:[lastName substringToIndex:1]];
        if(compositeName)
            compositeName = [compositeName stringByAppendingFormat:@" %@", lastName];
        else
            compositeName = lastName;
    }
    
    if([abbreviation isEqualToString:@""]) {
        abbreviation = @"??";
        compositeName = @"Unknown";
    }
    
    NSString* phone = nil;
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (ABMultiValueGetCount(phoneNumbers) > 0) {
        phone = (__bridge_transfer NSString*)
        ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
    } else {
        phone = @"";
    }
    CFRelease(phoneNumbers);
    
    NSString *email;
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 0) {
        email = (__bridge_transfer NSString*)
        ABMultiValueCopyValueAtIndex(emails, 0);
    } else {
        email = @"";
    }
    CFRelease(emails);
    
    
    //ok now create and save our data
    Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact"  inManagedObjectContext:self.managedObjectContext];
    contact.uniqueid = myNum;
    contact.name = compositeName;
    contact.initials = abbreviation;
    contact.owes = 0;
    
    //create a placeholder for our contact information
    ContactContactInfo *cinfo = [NSEntityDescription
                                 insertNewObjectForEntityForName:@"ContactContactInfo"
                                 inManagedObjectContext:self.managedObjectContext];
    
    cinfo.email = email;
    cinfo.phone = phone;
    contact.contactinfo = cinfo;
    
    //save?
    if(![self.managedObjectContext save:&error]) {
        //show error
        return NO;
    }
    
    //select our contact
    NSIndexPath *path = [self.contactListController indexPathForObject:contact];
    path = [NSIndexPath indexPathForRow:path.row inSection:SECTION_CONTACTS];
    [self tableView:self.tableView didSelectRowAtIndexPath:path];
    
    if(self.logic.userCount >= 30) {
        self.buttonContact.enabled = NO;
        self.buttonGeneric.enabled = NO;
    }
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

#pragma mark - ContactEditorDelegate
- (void) ContactEditor:(id)Editor Close:(bool)SaveChanges
{
    if(self.editPath.section != SECTION_CONTACTS) {
        if(SaveChanges) {
            BillUser *user;
            if(self.editPath.section == SECTION_GENERICS)
                user = [self.logic getGenericUser:self.editPath.row];
            else
                user = [self.logic getSelf];
            
            if(self.editUser.name.length > 0)
                user.name = self.editUser.name;
            if(self.editUser.abbreviation.length > 0)
                user.abbreviation = self.editUser.abbreviation;
            
            user.phone = self.editUser.phone;
            user.email = self.editUser.email;
            
            if(self.editPath.section == SECTION_SELF) {
                //save back to user defaults...
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:user] forKey:@"default user"];
                [defaults synchronize];
            }
            
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:self.editPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else {
        if(SaveChanges) {
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Person" message:@"An error occurred while attempting to save your changes" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alert show];
                
                //leave them where they are
                return;
            }
            
            /*
             //update contact if in bill as well
             Contact *contact = [self.contactListController objectAtIndexPath:[self fecthedObjectIndexPath:self.editPath]];
             BillUser *temp = [self.dataSource.logic getUserByContact:contact];
             
             //force update of properties of user
             if(temp)
             temp.contact = contact;
             */
            
        } else {
            [self.managedObjectContext rollback];
        }
    }
    
    self.editPath = nil;
}

- (void) ContactEditorDelete:(id)Editor {
    
    if(self.editPath.section == SECTION_CONTACTS) {
        Contact *contact = [self.contactListController objectAtIndexPath:[self fecthedObjectIndexPath:self.editPath]];
        [self.logic removeUserByContact:contact];
        
        if(!contact.objectID.isTemporaryID) {
            //delete our object
            [self.managedObjectContext deleteObject:contact.contactinfo];
            [self.managedObjectContext deleteObject:contact];
            
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Person" message:@"An error occurred while attempting to create a new person" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alert show];
            }
            
        } else {
            [self.managedObjectContext rollback];
        }
    } else if(self.editPath.section == SECTION_GENERICS) {
        [self.logic removeUser:[self.logic getGenericUser:self.editPath.row]];
        
        if(self.logic.numberOfGenericUsers > 0) {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.editPath] withRowAnimation:YES];
        } else {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:self.editPath.section] withRowAnimation:YES];
        }
    }
    
    self.partySize.text = [NSString stringWithFormat:@"%d", self.logic.userCount];
    self.editPath = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Extra Functions
- (NSIndexPath *) fecthedObjectIndexPath:(NSIndexPath *)path
{
    return [NSIndexPath indexPathForRow:path.row inSection:0];
}

- (BillUser *) getSelf {
    BillUser *user = [self.logic getSelf];
    if(!user) {
        user = [self makeUserSelfwithDefaults:nil];
    }
    return user;
}

@end
