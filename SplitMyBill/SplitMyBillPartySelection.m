//
//  SplitMyBillPartySelection.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/17/13.
//
//

#define SECTION_SELF 0
#define SECTION_CONTACTS 1
#define SECTION_GENERICS 2

#import "SplitMyBillPartySelection.h"
#import <QuartzCore/QuartzCore.h>
#import "Contact.h"
#import "ContactContactInfo.h"
#import <AddressBookUI/AddressBookUI.h>
#import "BillPerson.h"
#import "TestFlight.h"

@interface SplitMyBillPartySelection() <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, ABPeoplePickerNavigationControllerDelegate>

@property (nonatomic, retain) NSFetchedResultsController *contactListController;
@property (nonatomic) NSInteger genericCount;
@property (nonatomic, strong) NSIndexPath *editPath;
@property (nonatomic, strong) BillUser *editUser;
@end

@implementation SplitMyBillPartySelection
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize tableView = _tableView;
@synthesize partySize = _partySize;
@synthesize genericCount = _genericCount;
@synthesize editPath = _editPath;
@synthesize editUser = _editUser;

- (void) setTableView:(UITableView *)tableView {
    _tableView = tableView;
    _tableView.layer.borderWidth = 1.0f;
    _tableView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.5f].CGColor;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (bool) loadData {
    //begin loading up our saved contacts
    self.contactListController = nil;
    NSError *error;
	if (![[self contactListController] performFetch:&error])
    {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        return NO;
	}
    
    self.genericCount = self.dataSource.logic.numberOfGenericUsers + 1;    
    self.partySize.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.dataSource.logic.userCount];
    
    return YES;
}

- (void) reloadData {
    [self.tableView reloadData];
}

@synthesize contactListController = _contactListController;
- (NSFetchedResultsController *) contactListController {
    if (_contactListController != nil) {
        return _contactListController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Contact"
                                   inManagedObjectContext:self.dataSource.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:20];
    
    //[NSFetchedResultsController deleteCacheWithName:@"UserSelection"];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
        managedObjectContext:self.dataSource.managedObjectContext
        sectionNameKeyPath:nil
        cacheName:@"UserSelection" ];
    
    _contactListController = theFetchedResultsController;
    _contactListController.delegate = self;
    
    return _contactListController;
    
}

#pragma mark UITableViewDataSource
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 220, 20)];
    switch (section) {
        case SECTION_CONTACTS:
            label.text = @" From Contacts";
            break;
        case SECTION_GENERICS:
            label.text = @" Generic Users";
            break;
        case SECTION_SELF:
            label.text = @" You";
            break;
    }
    label.font = [UIFont fontWithName:@"Avenir-Medium" size:15.0f];
    label.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    
    return label;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = [self.contactListController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    
    UILabel *label = (UILabel *)[cell viewWithTag:2];
    label.text = contact.name;
    label = (UILabel *)[cell viewWithTag:3];
    label.text = contact.initials;
    
    UIImageView *image = (UIImageView *)[cell viewWithTag:1];
    image.hidden= ![self.dataSource.logic hasUserByContact:contact];
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
             user = [self.dataSource.logic getGenericUser:indexPath.row];
            label = (UILabel *)[cell viewWithTag:2];
            label.text = user.name;
            label = (UILabel *)[cell viewWithTag:3];
            label.text = user.abbreviation;
            image = (UIImageView *)[cell viewWithTag:1];
            image.hidden = NO;
            break;
            
        case SECTION_SELF:
            user = [self.dataSource.logic getSelf];
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
    if([self.dataSource.logic numberOfGenericUsers] > 0)
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
        return self.dataSource.logic.numberOfGenericUsers;
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
         
         [self.delegate editContact:contact];
     } else {
         //copy edit user over to dummy for cancel support
         BillUser *user;
         if(indexPath.section == SECTION_GENERICS)
             user = [self.dataSource.logic getGenericUser:indexPath.row];
         else
             user = [self getSelf];
     
         self.editUser = [[BillUser alloc] initWithName:user.name andAbbreviation:user.abbreviation];
         self.editUser.phone = user.phone;
         self.editUser.email = user.email;
         self.editUser.isSelf = user.isSelf;
         
         [self.delegate editUser:self.editUser];
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
            [self.dataSource.logic removeUserByContact:contact];
            
        } else {
            //create a bill user
            BillUser *user = [[BillUser alloc] initWithName:contact.name andAbbreviation:contact.initials];
            user.phone = contact.contactinfo.phone;
            user.email = contact.contactinfo.email;
            user.contact = contact;
            [self.dataSource.logic addUser:user];
        }
    } else if(indexPath.section == SECTION_GENERICS){
        //can only remove users
        BillUser *user = [self.dataSource.logic getGenericUser:indexPath.row];
        [self.dataSource.logic removeUser:user];
        
        if(self.dataSource.logic.numberOfGenericUsers == 0)
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:YES];
        else
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
    } else if(indexPath.section == SECTION_SELF) {
        UIImageView *image = (UIImageView *)[cell viewWithTag:1];
        image.hidden = !image.hidden;
        if(image.hidden) {
            [self.dataSource.logic removeUser:[self.dataSource.logic getSelf]];
        } else {
            [self.dataSource.logic addUser:[self makeUserSelfwithDefaults:nil]];
        }
    }
    
    NSUInteger userCnt = self.dataSource.logic.userCount;
    if(self.partySize) {
        self.partySize.text = [NSString stringWithFormat:@"%lu", (unsigned long)userCnt];
    }
    if(self.buttonNext)
        self.buttonNext.enabled = (userCnt > 0);
    
    self.buttonContact.enabled = userCnt < 30;
    self.buttonGeneric.enabled = userCnt < 30;
    
    if ([self.delegate respondsToSelector:@selector(usersChanged:)]) {
        [self.delegate usersChanged:YES];
    }    
    
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


- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id )sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    
    sectionIndex = SECTION_CONTACTS;
    
    if (type == NSFetchedResultsChangeInsert) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
    } else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

#pragma mark - Add Buttons...
- (IBAction)addGeneric:(id)sender {
    //we need a unique ID
    if(self.dataSource.logic.userCount >= 30) {
        //only allow up to 30 users
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Party Size Limit" message:@"You can only have up to 30 people in a party" delegate:self cancelButtonTitle:@"OK"otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    BillUser *user = [[BillUser alloc] initWithName:[NSString stringWithFormat:@"Person %ld", (long)self.genericCount] andAbbreviation:[NSString stringWithFormat:@"#%ld",(long)self.genericCount]];
    self.genericCount++;
    
    [self.dataSource.logic addUser:user];
    self.partySize.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.dataSource.logic.userCount];
    
    if(self.dataSource.logic.userCount >= 30) {
        self.buttonContact.enabled = NO;
        self.buttonGeneric.enabled = NO;
    }
    
    NSInteger genCnt = self.dataSource.logic.numberOfGenericUsers;
    if(genCnt > 0) genCnt--;
    
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:genCnt inSection:SECTION_GENERICS];
    if(self.dataSource.logic.numberOfGenericUsers == 1)
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
    
    [self.delegate showController:picker];
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
    [self.delegate removeController];
    ///[self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    ABRecordID uniqueID = ABRecordGetRecordID(person);
    NSNumber *myNum = [NSNumber numberWithInteger:uniqueID];
    [self.delegate removeController];
    ///[self dismissViewControllerAnimated:YES completion:NULL];
    
    //make sure contact isn't already present, if it is put up an error
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact"
        inManagedObjectContext:self.dataSource.managedObjectContext];
    
    [fetch setEntity:entity];
    [fetch setFetchLimit:1];
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"uniqueid == %@", myNum]];
    
    NSError *error;
    NSArray *contacts = [self.dataSource.managedObjectContext executeFetchRequest:fetch error:&error];
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
    Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact"  inManagedObjectContext:self.dataSource.managedObjectContext];
    contact.uniqueid = myNum;
    contact.name = compositeName;
    contact.initials = abbreviation;
    contact.owes = 0;
    
    //create a placeholder for our contact information
    ContactContactInfo *cinfo = [NSEntityDescription
        insertNewObjectForEntityForName:@"ContactContactInfo"
        inManagedObjectContext:self.dataSource.managedObjectContext];
    
    cinfo.email = email;
    cinfo.phone = phone;
    contact.contactinfo = cinfo;
    
    //save?
    if(![self.dataSource.managedObjectContext save:&error]) {
        //show error
        return NO;
    }
    
    //select our contact
    NSIndexPath *path = [self.contactListController indexPathForObject:contact];
    path = [NSIndexPath indexPathForRow:path.row inSection:SECTION_CONTACTS];
    [self tableView:self.tableView didSelectRowAtIndexPath:path];
    
    if(self.dataSource.logic.userCount >= 30) {
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
                user = [self.dataSource.logic getGenericUser:self.editPath.row];
            else
                user = [self.dataSource.logic getSelf];
            
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
            if (![self.dataSource.managedObjectContext save:&error]) {
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
            [self.dataSource.managedObjectContext rollback];
        }
    }
  
    self.editPath = nil;
}

- (void) ContactEditorDelete:(id)Editor {
    
    if(self.editPath.section == SECTION_CONTACTS) {
        Contact *contact = [self.contactListController objectAtIndexPath:[self fecthedObjectIndexPath:self.editPath]];
        [self.dataSource.logic removeUserByContact:contact];
        
        if(!contact.objectID.isTemporaryID) {
            //delete our object
            [self.dataSource.managedObjectContext deleteObject:contact.contactinfo];
            [self.dataSource.managedObjectContext deleteObject:contact];
            
            NSError *error;
            if (![self.dataSource.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Person" message:@"An error occurred while attempting to create a new person" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alert show];
            }
            
        } else {
            [self.dataSource.managedObjectContext rollback];
        }
    } else if(self.editPath.section == SECTION_GENERICS) {
        [self.dataSource.logic removeUser:[self.dataSource.logic getGenericUser:self.editPath.row]];
        
        if(self.dataSource.logic.numberOfGenericUsers > 0) {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.editPath] withRowAnimation:YES];
        } else {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:self.editPath.section] withRowAnimation:YES];
        }
    }
    
    self.partySize.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.dataSource.logic.userCount];
    
    self.editPath = nil;
    [self.delegate popController];
}

- (void) nextScreen {
    [self.delegate nextScreen];
}

#pragma mark - Extra Functions
- (NSIndexPath *) fecthedObjectIndexPath:(NSIndexPath *)path
{
    return [NSIndexPath indexPathForRow:path.row inSection:0];
}

- (BillUser *) getSelf {
    BillUser *user = [self.dataSource.logic getSelf];
    if(!user)
        user = [self makeUserSelfwithDefaults:nil];
    
    return user;
}


@end
