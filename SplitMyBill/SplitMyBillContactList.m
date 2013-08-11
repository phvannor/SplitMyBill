//
//  SplitMyBillContactList.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import "SplitMyBillContactList.h"
#import "Contact.h"
#import <AddressBookUI/AddressBookUI.h>
#import "ContactContactInfo.h"
#import "SplitMyBillContactEditorViewController.h"
#import "SplitMyBillContactDebtViewController.h"
#import "BillLogic.h"
#import <QuartzCore/QuartzCore.h>

@interface SplitMyBillContactList () <UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate, ContactEditorDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *contactList;
@property (nonatomic, strong) Contact *editContact;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)addContact:(id)sender;
@end

@implementation SplitMyBillContactList

@synthesize managedObjectContext = _managedObjectContext;
@synthesize contactList = _contactList;

- (IBAction)buttonNavigationBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_contactList != nil)
        return _contactList;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Contact" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    //[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"contact == %@", self.contact.objectID]];
    [fetchRequest setFetchBatchSize:20];
    
    [NSFetchedResultsController deleteCacheWithName:@"AllContacts"];
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
        managedObjectContext:self.managedObjectContext
        sectionNameKeyPath:nil
        cacheName:@"AllContacts" ];
    
    self.contactList = theFetchedResultsController;
    _contactList.delegate = self;
    
    return _contactList;
    
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"edit contact"]) {
        SplitMyBillContactEditorViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        controller.contact = self.editContact;
        return;
    }else if([segue.identifier isEqualToString:@"debts"]) {
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
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Loading Contacts" message:@"An error occurred attempting to load your contacts" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [alert show];
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
	}
    self.tableView.layer.borderColor = [UIColor colorWithWhite:0.6f alpha:1.0f].CGColor;
    self.tableView.layer.borderWidth = 1.0f;
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:animated];
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

- (IBAction)addContact:(id)sender {
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id  sectionInfo =
    [[self.contactList sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Contact *contact = [self.contactList objectAtIndexPath:indexPath];
    
    UILabel *name = (UILabel *)[cell viewWithTag:1];
    name.text = contact.name;
    
    UILabel *initials = (UILabel *)[cell viewWithTag:2];
    initials.text = contact.initials;
    
    UILabel *owes = (UILabel *)[cell viewWithTag:3];
    
    NSInteger owed = [contact.owes integerValue];
    if(owed >= 0) {
        owes.text = [BillLogic formatMoneyWithInt:owed];
        owes.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    } else {
        owes.text = [BillLogic formatMoneyWithInt:owed];
        owes.textColor = [UIColor colorWithRed:0.9 green:0.0 blue:0.0 alpha:1.0];
    }
    
    UIImageView *image = (UIImageView *)[cell viewWithTag:4];
    image.hidden = YES;
    
    //get image from contact?
    ABRecordID contactID = (ABRecordID)[contact.uniqueid integerValue];
    if(contactID != kABRecordInvalidID) {
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

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
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
}

#pragma mark - ABPeoplePickerDelegate
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    //fall back to manual contact
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

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    ABRecordID uniqueID = ABRecordGetRecordID(person);
    NSNumber *myNum = [NSNumber numberWithInteger:uniqueID];
    [self dismissViewControllerAnimated:YES completion:NULL];

    //make sure contact isn't already present, if it is put up an error
    
    //see if this contact already exists
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact"
                                    inManagedObjectContext:self.managedObjectContext];
    [fetch setEntity:entity];
    [fetch setFetchLimit:1];
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"uniqueid == %@", myNum]];
 
    NSError *error;
    NSArray *contacts = [self.managedObjectContext executeFetchRequest:fetch error:&error];
    if(contacts.count == 1) {
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
    self.editContact = contact;

    [self performSegueWithIdentifier:@"edit contact" sender:self];
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
    if(SaveChanges) {
        //confirm we have a first name
        if(self.editContact.name.length == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Contact Error" message:@"The name is required to create a contact" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            
            [alert show];
            return;
        }
        if(self.editContact.initials.length == 0) {
            self.editContact.initials = [self.editContact.name substringToIndex:4];
        }
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Person" message:@"An error occurred while attempting to save your changes" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alert show];

            //leave them where they are
            return;
        }
    } else {
        [self.managedObjectContext rollback];
    }

    [self.navigationController popViewControllerAnimated:YES];
    self.editContact = nil;
}

- (void) ContactEditorDelete:(id)Editor {
    if(!self.editContact.objectID.isTemporaryID) {
        //delete our object
        [self.managedObjectContext deleteObject:self.editContact.contactinfo];
        [self.managedObjectContext deleteObject:self.editContact];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Person" message:@"An error occurred while attempting to create a new person" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alert show];
        }
    
    } else {
        //we just created it, so delete the inserted object by rollingback
        [self.managedObjectContext rollback];
    }

    self.editContact = nil;
    [self.navigationController popViewControllerAnimated:YES];
    
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
@end
