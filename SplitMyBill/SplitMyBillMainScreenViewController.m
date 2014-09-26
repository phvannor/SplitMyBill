//
//  SplitMyBillMainScreenViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import "SplitMyBillMainScreenViewController.h"
#import "SplitMyBillContactList.h"
#import "BillLogic.h"
#import <CoreData/CoreData.h>
#import "Contact.h"
#import "ContactContactInfo.h"
#import "SplitMyBillContactDebtViewController.h"
#import "SplitMyBillAllBillsViewController.h"
#import "SMBBillNavigationViewController.h"

@interface SplitMyBillMainScreenViewController () <UICollectionViewDataSource, UICollectionViewDelegate, BillListDelegate>

@property (nonatomic, strong) BillLogic *BillLogic;
@property (nonatomic, strong) NSArray *debtList;
@property (nonatomic, strong) NSArray *billList;

@property (weak, nonatomic) IBOutlet UICollectionView *grid;
@property (nonatomic) bool loadingGrid;
@property (nonatomic) NSInteger loadedData;
@property (nonatomic, weak) Contact *selectedContact;

@property (weak, nonatomic) IBOutlet UIButton *buttonSettings;

@property (strong, nonatomic) NSArray *gridConstraints;
@property (strong, nonatomic) NSArray *addedContstraints;
@property (strong, nonatomic) Bill *editBill;

@end

@implementation SplitMyBillMainScreenViewController
@synthesize BillLogic = _BillLogic;
- (BillLogic *) BillLogic {
    if(!_BillLogic) _BillLogic = [[BillLogic alloc] init];
    //populate the user's data?
    
    return _BillLogic;
}

- (IBAction)buttonSettings:(id)sender {
    [self performSegueWithIdentifier:@"Settings" sender:self];
}

@synthesize managedObjectContext = _managedObjectContext;

- (IBAction)buttonNew:(id)sender {
    self.editBill = [self createBill];
    [self performSegueWithIdentifier:@"bill" sender:self];
}

- (IBAction)actionAllDebts:(id)sender {
    [self performSegueWithIdentifier:@"contacts" sender:nil];
}

- (IBAction)actionAllBills:(id)sender {
    [self performSegueWithIdentifier:@"bills" sender:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"contacts"]) {
        SplitMyBillContactList *controller = segue.destinationViewController;
        controller.managedObjectContext = self.managedObjectContext;
        return;
    }
    if([segue.identifier isEqualToString:@"bills"]) {
        SplitMyBillAllBillsViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.delegate = self;
        return;
    }
    if([segue.identifier isEqualToString:@"bill"]) {
        SMBBillNavigationViewController *controller = segue.destinationViewController;
        
        self.BillLogic = [[BillLogic alloc] initWithBill:self.editBill andContext:self.managedObjectContext];
        
        controller.bill = self.BillLogic.bill;
        controller.billlogic = self.BillLogic;
        controller.managedObjectContext = self.managedObjectContext;
        
        return;
    }
    if([segue.identifier isEqualToString:@"user debt"]) {
         SplitMyBillContactDebtViewController *controller = segue.destinationViewController;
        
        controller.managedObjectContext = self.managedObjectContext;
        controller.contact = self.selectedContact;
    }
}

- (Bill *) createBill {
    //create new bill entity...
    Bill * bill = [NSEntityDescription insertNewObjectForEntityForName:@"Bill" inManagedObjectContext:self.managedObjectContext];
    
    //defaults for a bill
    bill.title = @"";
    bill.created = [NSDate date];
    bill.type = [NSNumber numberWithInt:1];
    bill.taxInDollars = [NSNumber numberWithBool:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *string = [defaults objectForKey:@"taxRate"];
    if(!string) string = @"0";
    bill.tax = [NSDecimalNumber decimalNumberWithString:string];
    
    string = [defaults objectForKey:@"tipRate"];
    if(!string) string = @"0";
    bill.tip = [NSDecimalNumber decimalNumberWithString:string];
    bill.tipInDollars = [NSDecimalNumber numberWithBool:NO];
    bill.type = [NSNumber numberWithInt:0];
    bill.rounding = [NSNumber numberWithInteger:[defaults integerForKey:@"roundValue"]];
    
    //save the newly created bill
    NSError *error;
    if(![self.managedObjectContext save:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error creating a bill" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
        return nil;
    }
    
    //self defaults to being present...
    self.BillLogic = [[BillLogic alloc] initWithBill:bill andContext:self.managedObjectContext];
    BillUser *user = [self makeUserSelfwithDefaults:nil];
    [self.BillLogic addUser:user];
    self.BillLogic.bill = bill;
    
    return bill;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) loadBillsIntoGrid {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Bill"
                                   inManagedObjectContext:self.managedObjectContext];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setFetchLimit:2];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    self.billList = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    self.loadedData++;
    [self.grid reloadData];
}

- (void) loadDebtsIntoGrid {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Contact"
                                   inManagedObjectContext:self.managedObjectContext];

    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"owes" ascending:NO];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchLimit:8];
    
    NSError *error;
    self.debtList = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    //pull out the top eight values now...
    /*
    self.dataList = [[NSMutableArray alloc] init];
    NSInteger front = 0;
    NSInteger back = allContacts.count - 1;
    if(back >= 0) {
        Contact *frontContact = [allContacts objectAtIndex:front];
        Contact *backContact = [allContacts objectAtIndex:back];
        
        for(NSInteger i = 0; i < 8; i++) {
            if(front == back) {
                [self.dataList addObject:frontContact];
                break;
            }
            
            if(abs([frontContact.owes integerValue]) >= abs([backContact.owes integerValue])) {
                [self.dataList addObject:frontContact];
                front++;
                frontContact = [allContacts objectAtIndex:front];
            } else {
                [self.dataList addObject:backContact];
                back--;
                backContact = [allContacts objectAtIndex:back];
            }
        }
    }
    */
    
    //refresh grid now
    self.loadedData++;
    [self.grid reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    //[self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    
    // Reload the correct data
    self.loadedData = 0;
    [self loadBillsIntoGrid];
    [self loadDebtsIntoGrid];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Over protective grid loading logic
    if (self.loadedData != 2) {
        return 1;
    }
    
    if (section == 0) {
        if (self.billList.count > 0) {
            return self.billList.count;
        }
    } else {
        if (self.debtList.count > 0) {
            return self.debtList.count;
        }
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *section;
    
    if([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        section = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
    }
    
    UILabel *header = (UILabel *)[section viewWithTag:1];
    UIButton *button = (UIButton *)[section viewWithTag:2];
    
    [button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    if(indexPath.section == 0) {
        header.text = @"Recent Bills";
        [button addTarget:self action:@selector(viewBills) forControlEvents:UIControlEventTouchDown];
    } else {
        header.text = @"Top Debts";
        [button addTarget:self action:@selector(viewDebts) forControlEvents:UIControlEventTouchDown];
    }
    
    return section;
}

- (void) viewDebts
{
    [self performSegueWithIdentifier:@"contacts" sender:self];
}

- (void) viewBills
{
    [self performSegueWithIdentifier:@"bills" sender:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell;
    
    if(self.loadedData != 2) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"loadcell" forIndexPath:indexPath];
    } else if (indexPath.section == 0) {
        if(self.billList.count == 0) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"nodata" forIndexPath:indexPath];
        } else {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"billcell" forIndexPath:indexPath];
            
            Bill *bill = [self.billList objectAtIndex:indexPath.row];
            
            UILabel *title = (UILabel *)[cell viewWithTag:2];
            title.text = bill.title;
            
            UILabel *cost = (UILabel *)[cell viewWithTag:1];
            cost.text = [BillLogic formatMoneyWithInt:[bill.total integerValue]];
            
            // A date formatter for the time stamp.
            static NSDateFormatter *dateFormatter = nil;
            if (dateFormatter == nil) {
                dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            }
            UILabel *date = (UILabel *)[cell viewWithTag:3];
            date.text = [dateFormatter stringFromDate:bill.created];
        }
    } else {
        if(indexPath.row == self.debtList.count) {
            if(self.debtList.count > 0) {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"viewall" forIndexPath:indexPath];
            } else {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"nodebts" forIndexPath:indexPath];
            }
        } else { // Debts
            // Show the debt details instead
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"debtcell" forIndexPath:indexPath];
        
            Contact *contact = [self.debtList objectAtIndex:indexPath.row];
        
            // Show image of user...
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
            imageView.hidden = YES;
            ABRecordID contactID = (ABRecordID)[contact.uniqueid integerValue];
            if(contactID != kABRecordInvalidID) {
                CFErrorRef err;
                ABAddressBookRef ab = ABAddressBookCreateWithOptions(NULL, &err);
            
                ABRecordRef record = ABAddressBookGetPersonWithRecordID(ab, contactID);
                if(record) {
                    if(ABPersonHasImageData(record)) {
                        NSData *imageData = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
                    
                        imageView.image = [[UIImage alloc] initWithData:imageData];
                        imageView.clipsToBounds = YES;
                        imageView.hidden = NO;
                    }
                }
            }
        
            UILabel *name = (UILabel *)[cell viewWithTag:4];
            name.text = [@" " stringByAppendingString:contact.name];
        
            UILabel *initials = (UILabel *)[cell viewWithTag:3];
            initials.hidden = !imageView.hidden;
        
            if(imageView.hidden) {
                initials.text = contact.initials;
                //randomly assign a color                
                [initials setBackgroundColor:[UIColor
                        colorWithRed:(arc4random() % 150) / 255.0
                        green:arc4random() % 150 / 255.0
                        blue:arc4random() % 150 / 255.0
                                              alpha:1.0f]];
            }
        
            // Show debt...
            UILabel *debtValue = (UILabel *)[cell viewWithTag:2];
            UILabel *owesLabel = (UILabel *)[cell viewWithTag:5];
            
            NSInteger money = [contact.owes integerValue];
            if(money < 0) {
                debtValue.textColor = [UIColor redColor];
                owesLabel.text = @"You owe:";
            } else {
                debtValue.textColor = [UIColor whiteColor];
                owesLabel.text = @"Owes you:";
            }
            
            debtValue.text = [[BillLogic formatMoneyWithInt:money] stringByAppendingString:@" "];
        }
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.loadedData != 2) {
        return CGSizeMake(collectionView.frame.size.width - 10, collectionView.frame.size.height - 10);
    }

    float width = collectionView.frame.size.width / 2 - 2;
    
    if(indexPath.section == 0) {
        return CGSizeMake(width, 80.0f);
    } else {
        float height = (collectionView.frame.size.height - 71 - 80) / 2 - 2;
        return CGSizeMake(width, height);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.loadedData != 2) {
        return;
    }
    
    if(indexPath.section == 0) {
        if(self.billList.count == 0) {
            return;
        }
        
        self.editBill = [self.billList objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"bill" sender:self];
        
    } else {
        if(self.debtList.count == 0)
            return;
    
        self.selectedContact = [self.debtList objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"user debt" sender:self];
    }
}

- (Bill *) BillListCreateBill:(id)ListController
{
    return [self createBill];
}

@end
