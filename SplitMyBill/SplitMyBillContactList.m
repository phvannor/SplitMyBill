//
// SplitMyBillContactList.m
// SplitMyBill
//
// Created by Phillip Van Nortwick on 9/19/12.
//
// Displays a list of each contact and the total they owe/are owed
//

#import "SplitMyBillContactList.h"
#import "Contact.h"
#import <AddressBookUI/AddressBookUI.h>
#import "ContactContactInfo.h"
#import "SplitMyBillContactEditorViewController.h"
#import "SplitMyBillContactDebtViewController.h"
#import "BillLogic.h"
#import <QuartzCore/QuartzCore.h>

@interface SplitMyBillContactList () <ABPeoplePickerNavigationControllerDelegate, ContactEditorDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic) bool CanAccessContacts;
@property (nonatomic, strong) NSFetchedResultsController *contactList;
@property (nonatomic, strong) Contact *editContact;

@end


@implementation SplitMyBillContactList

- (NSFetchedResultsController *)fetchedResultsController {
    if (_contactList != nil) {
        return _contactList;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    fetchRequest.sortDescriptors = @[sort];
    fetchRequest.fetchBatchSize = 20;
    
    [NSFetchedResultsController deleteCacheWithName:@"AllContacts"];
    NSFetchedResultsController *fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:@"AllContacts" ];
    
    fetchedResultsController.delegate = self;

    _contactList = fetchedResultsController;
    
    return _contactList;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"edit contact"]) {
        // Display contact information for one user
        SplitMyBillContactEditorViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        controller.contact = self.editContact;
    } else if ([segue.identifier isEqualToString:@"debts"]) {
        // Display debts about one particular user
        SplitMyBillContactDebtViewController *controller = segue.destinationViewController;
        controller.contact = self.editContact;
        controller.managedObjectContext = self.managedObjectContext;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contactList = nil;
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Error: %@, %@", error, [error userInfo]);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Loading Contacts"
                                                        message:@"An error occurred attempting to load your contacts"
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles: nil];
        [alert show];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
	}
    
    ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil),
                                             ^(bool granted, CFErrorRef error) {
                                                 self.CanAccessContacts = granted;
                                             });
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated: animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)addContact:(id)sender {
    ABPeoplePickerNavigationController *picker = [ABPeoplePickerNavigationController new];
    
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = self.contactList.sections[section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48.0f;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Contact *contact = [self.contactList objectAtIndexPath:indexPath];
    
    UILabel *name = (UILabel *)[cell viewWithTag:1];
    name.text = contact.name;
    
    UILabel *initials = (UILabel *)[cell viewWithTag:2];
    initials.text = contact.initials;
    
    UILabel *owes = (UILabel *)[cell viewWithTag:3];
    
    NSInteger owed = [contact.owes integerValue];
    if (owed >= 0) {
        owes.text = [BillLogic formatMoneyWithInt:owed];
        owes.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    } else {
        owes.text = [BillLogic formatMoneyWithInt:owed];
        owes.textColor = [UIColor colorWithRed:0.9 green:0.0 blue:0.0 alpha:1.0];
    }
    
    UIImageView *image = (UIImageView *)[cell viewWithTag:4];
    image.hidden = YES;
    
    //get image from contact
    ABRecordID contactID = (ABRecordID)[contact.uniqueid integerValue];
    if(contactID != kABRecordInvalidID && self.CanAccessContacts) {
        CFErrorRef *error = nil;
        
        ABAddressBookRef abook = ABAddressBookCreateWithOptions(nil, error);
        ABRecordRef record = ABAddressBookGetPersonWithRecordID(abook, contactID);
        if(record) {
            if(ABPersonHasImageData(record)) {
                NSData *imageData = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
                
                UIImage *img = [[UIImage alloc] initWithData:imageData];
                [image setImage:img];
                [image.layer setCornerRadius:17.0f];
                image.hidden = NO;
            }
        }
        CFRelease(abook);
    }

    initials.hidden = !image.hidden;

    // show a initial window instead
    if(image.hidden) {
        [initials.layer setCornerRadius:17.0f];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"contact";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

// Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.editContact = [self.contactList objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"edit contact" sender:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.editContact = [self.contactList objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"debts" sender:self];    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Fall back to a manual contact
        // Create a person and contact info object and send them to the editor
        NSNumber *customUserId = [NSNumber numberWithInt:kABRecordInvalidID];
        
        Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact"
                                                         inManagedObjectContext:self.managedObjectContext];
        contact.uniqueid = customUserId;
        
        // Blank name and initials
        ContactContactInfo *cinfo = [NSEntityDescription insertNewObjectForEntityForName:@"ContactContactInfo"
                                                                  inManagedObjectContext:self.managedObjectContext];
        contact.contactinfo = cinfo;
        
        // Now go to the editor view
        self.editContact = contact;
        
        [self performSegueWithIdentifier:@"edit contact" sender:self];
    }
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    UIAlertView *manualCreate = [[UIAlertView alloc] initWithTitle:@"Create New Contact"
                                                           message:@"Would you like to add a new contact instead?"
                                                          delegate:self
                                                 cancelButtonTitle:@"No"
                                                 otherButtonTitles:@"Yes", nil];
    [manualCreate show];
}

-(void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                        didSelectPerson:(ABRecordRef)person
{
    ABRecordID uniqueID = ABRecordGetRecordID(person);
    NSNumber *myNum = [NSNumber numberWithInteger:uniqueID];
    
    [self dismissViewControllerAnimated:YES completion:NULL];

    // If we have access to the actual contact list, check to see if the selected contact is already
    // present in our contact list
    if (self.CanAccessContacts) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Contact"];
        fetchRequest.fetchLimit = 1;
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uniqueid == %@", myNum];
        
        NSError *error;
        NSArray *contacts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if(contacts.count == 1) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Contact Already Added"
                                                            message:@"The selected contact was added previously."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles: nil];
            [alert show];
            
            return;
        }
    }
    
    // Generate the contact's name and abbreviation string
    
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString *compositeName = @"";
    NSString *abbreviation = @"";
    
    if(firstName.length > 1) {
        abbreviation = [firstName substringToIndex:1];
        compositeName = firstName;
    }
    
    if(lastName.length > 1) {
        abbreviation = [abbreviation stringByAppendingString:[lastName substringToIndex:1]];
        if (compositeName) {
            compositeName = [compositeName stringByAppendingFormat:@" %@", lastName];
        } else {
            compositeName = lastName;
        }
    }
        
    if(abbreviation.length == 0) {
        abbreviation = @"??";
        compositeName = @"Unknown";
    }
    
    // Pick a phone number to use for this contact
    
    NSString* phone = @"";
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (phoneNumbers) {
        if (ABMultiValueGetCount(phoneNumbers) > 0) {
            phone = (__bridge_transfer NSString*)
            ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
        }
        CFRelease(phoneNumbers);
    }
    
    // And pick an email address as well
    
    NSString *email = @"";
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (emails) {
        if (ABMultiValueGetCount(emails) > 0) {
            email = (__bridge_transfer NSString*)
            ABMultiValueCopyValueAtIndex(emails, 0);
        }
        CFRelease(emails);
    }
    
    // Now create and save our data
    
    Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact"  inManagedObjectContext:self.managedObjectContext];
    contact.uniqueid = myNum;
    contact.name = compositeName;
    contact.initials = abbreviation;
    contact.owes = 0;
    
    // The create a placeholder for our contact information
    
    ContactContactInfo *cinfo = [NSEntityDescription insertNewObjectForEntityForName:@"ContactContactInfo"
                                                              inManagedObjectContext:self.managedObjectContext];
    
    cinfo.email = email;
    cinfo.phone = phone;
    contact.contactinfo = cinfo;
    
    self.editContact = contact;

    // Now let the user pick any additional details
    [self performSegueWithIdentifier:@"edit contact" sender:self];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

# pragma mark - ContactEditorDelegate

- (void) ContactEditor:(id)Editor Close:(bool)SaveChanges
{
    if (!SaveChanges || self.editContact.name.length == 0) {
        [self.managedObjectContext rollback];
    } else {
    
        // If no initials grab four characters of the name
        if (self.editContact.initials.length == 0) {
            NSUInteger length = self.editContact.name.length;
            length = length > 4 ? 4 : length;
            
            self.editContact.initials = [self.editContact.name substringToIndex:length];
        }
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Couldn't save: %@", [error localizedDescription]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Error"
                                                            message:@"An error occurred while attempting to save your changes"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    self.editContact = nil;
}

- (void) ContactEditorDelete:(id)Editor {
    if (!self.editContact.objectID.isTemporaryID) {
        // Delete our object
        [self.managedObjectContext deleteObject:self.editContact.contactinfo];
        [self.managedObjectContext deleteObject:self.editContact];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Couldn't save: %@", error.localizedDescription);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Contact"
                                                            message:@"An error occurred while attempting to create a new contact"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    
    } else {
        // We just created it, so delete the inserted object by rollingback
        [self.managedObjectContext rollback];
    }

    self.editContact = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - Fetched Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
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

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
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
