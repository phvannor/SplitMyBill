//
//  SplitMyBillContactEditorViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import "SplitMyBillContactEditorViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import <QuartzCore/QuartzCore.h>

@interface SplitMyBillContactEditorViewController ()  <UITextFieldDelegate, UIActionSheetDelegate>
@property (nonatomic) ABAddressBookRef abook;
@property (nonatomic) ABRecordRef abContact;
@property (nonatomic, copy) NSString *orginalValue;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)buttonCancel:(id)sender;
- (IBAction)buttonSave:(id)sender;
- (IBAction)buttonDelete:(id)sender;
@end

@implementation SplitMyBillContactEditorViewController
@synthesize delegate = _delegate;
@synthesize abContact = _abContact;
@synthesize user = _user;
@synthesize orginalValue = _orginalValue;
@synthesize abook = _abook;

- (void)closeForm:(bool)Save {
    [self.view endEditing:YES];
    //validation of our data here...
    
    [self.delegate ContactEditor:self Close:Save];
}

- (IBAction)buttonCancel:(id)sender {
    [self closeForm:NO];
}
- (IBAction)buttonSave:(id)sender {
    [self closeForm:YES];
}

- (IBAction)buttonDelete:(id)sender {
    [self.view endEditing:YES];
    //confirm first
    //todo:
    
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles: nil];
    
    [actions showInView:self.view];    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //no toolbar on this screen
    [self.navigationController setToolbarHidden:YES];
    
    // check if the contactID is valid and still exists on the phone
    if(self.contact) {
        NSNumber *myNum = self.contact.uniqueid;
        ABRecordID myID = (ABRecordID)[myNum integerValue];
        if(myID != kABRecordInvalidID) {
            CFErrorRef err;
            self.abook = ABAddressBookCreateWithOptions(NULL, &err);
            
            ABRecordRef ref = ABAddressBookGetPersonWithRecordID(self.abook, myID);
            self.abContact = ref;
        }
    }
}

- (void) viewDidUnload {
    [self setTableView:nil];
    
    if(!self.abook)
        CFRelease(self.abook);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if(self.user.isSelf)
        return 3;
    
    return 3; //4 for delete
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 1:
            return @"Phone";
        case 2:
            return @"Email";
    }
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) // user
        return 2;
    if(section == 2) // delete
        return 1;
    
    if(self.abContact == NULL)
        return 1;

    NSInteger count = 0;
    if(section == 1) {
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(self.abContact, kABPersonPhoneProperty);
        count = ABMultiValueGetCount(phoneNumbers);
        CFRelease(phoneNumbers);
    } else if(section == 2) {
        ABMultiValueRef emails = ABRecordCopyValue(self.abContact, kABPersonEmailProperty);
        count = ABMultiValueGetCount(emails);
        CFRelease(emails);
    }
    
    return count;
}

- (bool) checkListed:(bool)usePhone {
    if(!self.contact.contactinfo || !self.abContact)
        return NO;
    
    NSString *comparisonValue;
    if(usePhone)
        comparisonValue = self.contact.contactinfo.phone;
    else
        comparisonValue = self.contact.contactinfo.email;
    
    ABMultiValueRef values;
    if(usePhone)
        values = ABRecordCopyValue(self.abContact,                                                         kABPersonPhoneProperty);
    else
        values = ABRecordCopyValue(self.abContact,                                                         kABPersonEmailProperty);
    
    bool found = NO;
    for(NSInteger i = 0; i < ABMultiValueGetCount(values); i++) {
        NSString *temp = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(values, i);
        
        if([temp isEqualToString:comparisonValue]){
            found = YES;
            break;
        }
    }
    CFRelease(values);
    return found;
}

- (UITableViewCell *)tableView:(UITableView *)tableView getCellType:(NSInteger) type forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger count = 0;
    NSString *details;
    NSString *label;
    CFStringRef rawLabel = nil;
    NSString *comparisonValue;
    
    ABMultiValueRef values;
    if(self.contact.contactinfo) {
        if(type == 0)
            comparisonValue = self.contact.contactinfo.phone;
        else
            comparisonValue = self.contact.contactinfo.email;
    }
    
    if(self.abContact != NULL) {
        if(type == 0) {
            values = ABRecordCopyValue(self.abContact,                                                         kABPersonPhoneProperty);
        } else {
            values = ABRecordCopyValue(self.abContact,                                                         kABPersonEmailProperty);
        }
        
        count = ABMultiValueGetCount(values);
        
        if(count != indexPath.row) {
            details = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(values, indexPath.row);
            rawLabel = ABMultiValueCopyLabelAtIndex(values, indexPath.row);
            CFRelease(values);
            
            if(rawLabel) {
                label = (__bridge_transfer NSString*) ABAddressBookCopyLocalizedLabel(rawLabel);
                CFRelease(rawLabel);
            } else {
                label = @"";
            }
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"display cell"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = label;
            cell.detailTextLabel.text = details;
            
            if([comparisonValue isEqualToString:details])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
            return cell;
        }
        CFRelease(values);
    }
    
    //either no other numbers or we are the last row
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"edit cell"];
        
    //populate the text of the cell with the value in contact
    UILabel *myLabel = (UILabel *) [cell viewWithTag:2];
    myLabel.text = @"custom";

    UITextField *textField = (UITextField *) [cell viewWithTag:1];
    
    //get the contactcontactinfo record
    if(self.contact) {
        ContactContactInfo *cinfo = self.contact.contactinfo;
        if(type == 0)
            textField.text = cinfo.phone;
        else
            textField.text = cinfo.email;
    } else {
        if(type == 0)
            textField.text = self.user.phone;
        else
            textField.text = self.user.email;
    }
    
    //set up textfield defaults
    if(type == 0) {
        textField.placeholder = @"phone number";
        [textField setKeyboardType:UIKeyboardTypePhonePad];
        textField.tag = 12;
    } else {
        textField.placeholder = @"email address";
        [textField setKeyboardType:UIKeyboardTypeEmailAddress];
        textField.tag = 13;
    }

    if([self checkListed:(type == 0)]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        textField.text = @"";
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"edit cell"];
        [cell setSelectionStyle: UITableViewCellSelectionStyleNone];
        
        UITextField *textField = (UITextField *) [cell viewWithTag:1];
        if(indexPath.row == 0) {
            if(self.contact)
                textField.text = self.contact.name;
            else
                textField.text = self.user.name;
            
            textField.placeholder = @"Display name";
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.tag = 10;
            
        } else {
            if(self.contact)
                textField.text = self.contact.initials;
            else
                textField.text = self.user.abbreviation;
            
            textField.placeholder = @"Initials";
            textField.autocapitalizationType =UITextAutocapitalizationTypeAllCharacters;
            textField.tag = 11;
            
            //todo: limit to 4 characters
        }
    } else if(indexPath.section == 1) {
        cell = [self tableView:tableView getCellType:0 forRowAtIndexPath:indexPath];
    } else if(indexPath.section == 2) {
        cell = [self tableView:tableView getCellType:1 forRowAtIndexPath:indexPath];
    }

    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 || indexPath.section == 3)
        return;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    NSString *value;
    
    //update the phone/email to the correct value
    if([cell.reuseIdentifier isEqualToString:@"text cell"]) {
        value = cell.detailTextLabel.text;
    } else {
        value = cell.detailTextLabel.text;
    }

    if(indexPath.section == 1)
        self.contact.contactinfo.phone = value;
    else
        self.contact.contactinfo.email = value;

    for(NSInteger i = 0; i < [tableView numberOfRowsInSection:indexPath.section]; i++) {
        if(i == indexPath.row)
            continue;

        //uncheck all rows
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //hack, need a better way to do this...
    if([textField.placeholder isEqualToString:@"Initials"]) {
        NSString *temp = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        return (temp.length < 5);
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.orginalValue = [textField.text copy];
    
    //if text or email other, check off using this field
    NSInteger section;
    if(textField.tag == 12) {
        section = 1;
    } else if(textField.tag == 13) {
        section = 2;
    } else {
        return;
    }
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:section]-1) inSection:section]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSInteger section = 0;


    switch(textField.tag) {
        case 10:
            if(textField.text.length == 0)
                textField.text = self.orginalValue;

            if(self.contact)
                self.contact.name = textField.text;
            else
                self.user.name = textField.text;
            break;
        case 11:
            if(textField.text.length == 0)
                textField.text = self.orginalValue;
            
            if(self.contact)
                self.contact.initials = textField.text;
            else
                self.user.abbreviation = textField.text;
            break;
        case 12:
            section = 1;
            break;
        case 13:
            section = 2;
            break;
    }
    if(section == 0) return;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:section] - 1) inSection:section]];
    if(cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        if(section == 1) {
            if(self.contact)
                self.contact.contactinfo.phone = textField.text;
            else
                self.user.phone = textField.text;
        } else {
            if(self.contact)
                self.contact.contactinfo.email = textField.text;
            else
                self.user.email =textField.text;
        }
    }    
}


// validateEmail
// very simple email check for formatting only
- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

#pragma mark - UIActionSheetDelegate
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
        [self.delegate ContactEditorDelete:self];
}

@end
