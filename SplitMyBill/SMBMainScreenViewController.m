//
//  SplitMyBillMainScreenViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import "SMBMainScreenViewController.h"
#import "SMBContactList.h"
#import "BillLogic.h"
#import <CoreData/CoreData.h>
#import "Contact.h"
#import "ContactContactInfo.h"
#import "SplitMyBillContactDebtViewController.h"
#import "SplitMyBillAllBillsViewController.h"
#import "SMBBillNavigationViewController.h"

@interface SMBMainScreenViewController () <BillListDelegate>

@property (nonatomic, strong) BillLogic *BillLogic;
@property (nonatomic, strong) NSArray *billList;

@property (nonatomic) NSInteger loadedData;
@property (nonatomic, weak) Contact *selectedContact;

@property (weak, nonatomic) IBOutlet UIButton *buttonSettings;

@property (strong, nonatomic) NSArray *gridConstraints;
@property (strong, nonatomic) NSArray *addedContstraints;
@property (strong, nonatomic) Bill *editBill;

@property (weak, nonatomic) IBOutlet UICollectionView *debtList;
@property (strong, nonatomic) Contact *contact;

@end

@implementation SMBMainScreenViewController

@synthesize BillLogic = _BillLogic;
- (BillLogic *) BillLogic {
    if(!_BillLogic) {
        _BillLogic = [[BillLogic alloc] init];
    }
    
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
        SMBContactList *controller = segue.destinationViewController;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    self.oweField.text = @"$--.--";
    self.owedField.text = @"$--.--";
    
    // Begin loading debt information
    [self.managedObjectContext performBlock:^{
        // Load debts & calculate owed & due
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
        
        // Specify criteria for filtering which objects to fetch
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"owes <> 0"];
        
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"owes"
                                                                       ascending:YES];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            // Show on screen error
            NSLog(@"Error loading contact debts: %@", error);
        }
        
        NSInteger owe = 0;
        NSInteger owed = 0;
        self.contact = nil;
        for (Contact *contact in fetchedObjects) {
            if (!self.contact) {
                self.contact = contact;
            }
            
            if (contact.owes > 0) {
                owed += [contact.owes integerValue];
            } else {
                owe += [contact.owes integerValue];
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.owedField.text = [BillLogic formatMoneyWithInt:owed];
            self.oweField.text = [BillLogic formatMoneyWithInt:owe];
            
            [self.debtList reloadData];
        });
    }];
    
    // Reload the correct data
    self.loadedData = 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.debtList.dataSource = self;
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

- (Bill *) BillListCreateBill:(id)ListController
{
    return [self createBill];
}

#pragma mark CollectionView

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.contact) {
        return 1;
    } else {
        return 0;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"contact";
    if ([self.contact.uniqueid integerValue] == -1) {
        cellId = @"contactInitials";
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    
    // UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    
    return cell;
}

@end
