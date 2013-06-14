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
#import "SplitMyBillQuickSplitViewController.h"
#import "SplitMyBillAllBillsViewController.h"
#import "SplitMyBillEditorViewController.h"

@interface SplitMyBillMainScreenViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) BillLogic *BillLogic;
@property (weak, nonatomic) IBOutlet UIScrollView *contactScroll;
@property (weak, nonatomic) IBOutlet UIPageControl *contactPage;
@property (nonatomic, strong) NSMutableArray *contactList;
@end

@implementation SplitMyBillMainScreenViewController
@synthesize contactList = _contactList;
@synthesize BillLogic = _BillLogic;
- (BillLogic *) BillLogic {
    if(!_BillLogic) _BillLogic = [[BillLogic alloc] init];
    //populate the user's data?
    
    return _BillLogic;
}

- (IBAction)buttonSettings:(id)sender {
    [self performSegueWithIdentifier:@"Settings" sender:self];
}

- (IBAction)pushSimple:(id)sender {
    self.BillLogic = [[BillLogic alloc] init];
    [self performSegueWithIdentifier:@"simple split" sender:self];    
}

@synthesize managedObjectContext = _managedObjectContext;
- (IBAction)buttonNew:(id)sender {
    self.BillLogic = [[BillLogic alloc] init];
    
    [self performSegueWithIdentifier:@"new bill" sender:self];
    
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
        return;
    }
    if([segue.identifier isEqualToString:@"new bill"]) {
        SplitMyBillEditorViewController *controller = segue.destinationViewController;
        
        [self  createBill];
        
        controller.bill = self.BillLogic.bill;
        controller.billlogic = self.BillLogic;
        controller.managedObjectContext = self.managedObjectContext;
        return;
    }
    if([segue.identifier isEqualToString:@"user debt"]) {
        SplitMyBillContactDebtViewController *controller = segue.destinationViewController;
        [controller setManagedObjectContext:self.managedObjectContext];
        NSInteger index = (self.contactScroll.contentOffset.x / self.contactScroll.frame.size.width);
        [controller setContact:[self.contactList objectAtIndex:index]];
    }
    if([segue.identifier isEqualToString:@"simple split"]) {
        SplitMyBillQuickSplitViewController *controller = segue.destinationViewController;
        
        [self createBill];
        self.BillLogic.bill.type = [NSNumber numberWithInteger:1];

        BillItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"BillItem" inManagedObjectContext:self.managedObjectContext];
        item.price = [NSNumber numberWithInteger:0];
        
        BillLogicItem *newItem = [[BillLogicItem alloc] initWithItem:item];
        [self.BillLogic addItem:newItem];
        
        [controller setLogic:self.BillLogic];
        [controller setManagedObjectContext:self.managedObjectContext];
    }
}

- (void) createBill {
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
    
    self.BillLogic = [[BillLogic alloc] initWithBill:bill andContext:self.managedObjectContext];
    self.BillLogic.tax = bill.tax;
    self.BillLogic.tip = bill.tip;
    
    //!!! todo add rounding property into bill object
    self.BillLogic.roundingAmount = [defaults integerForKey:@"roundValue"];
    
    //save the newly created bill
    NSError *error;
    if(![self.managedObjectContext save:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error creating a bill" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
        exit(-1);
        return;
    }
    
    //self defaults to being present...
    
    BillUser *user = [self makeUserSelfwithDefaults:nil];
    [self.BillLogic addUser:user];
    
    self.BillLogic.bill = bill;
    
    return;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)toUserDebts
{
    if(self.contactList.count == 0)
        [self performSegueWithIdentifier:@"contacts" sender:self];
    else
        [self performSegueWithIdentifier:@"user debt" sender:self];
}

NSInteger contactSort(id obj1, id obj2, void *context) {
    Contact *one = (Contact *)obj1;
    Contact *two = (Contact *)obj2;
    
    NSInteger absOne = abs([one.owes integerValue]);
    NSInteger absTwo = abs([two.owes integerValue]);
    
    if(absOne  > absTwo)
        return NSOrderedDescending;
    
    if(absOne  < absTwo)
        return NSOrderedDescending;
    
    return NSOrderedSame;        
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:YES];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
            entityForName:@"Contact"
            inManagedObjectContext:self.managedObjectContext];
    
    //[fetchRequest setFetchLimit:3];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"owes" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"owes != %@", [NSNumber numberWithInt:0]]];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSMutableArray *allContacts = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
    
    //pull out the top three values now...
    self.contactList = [[NSMutableArray alloc] init];
    NSInteger front = 0;
    NSInteger back = allContacts.count - 1;
    if(back >= 0) {
        Contact *frontContact = [allContacts objectAtIndex:front];
        Contact *backContact = [allContacts objectAtIndex:back];
        
        for(NSInteger i = 0; i < 3; i++) {
            if(front == back) {
                [self.contactList addObject:frontContact];
                break;
            }
            
            if(abs([frontContact.owes integerValue]) >= abs([backContact.owes integerValue])) {
                [self.contactList addObject:frontContact];
                front++;
                frontContact = [allContacts objectAtIndex:front];
            } else {
                [self.contactList addObject:backContact];
                back--;
                backContact = [allContacts objectAtIndex:back];
            }
        }
    }
    
    float height = self.contactScroll.frame.size.height;
    float width = self.contactScroll.frame.size.width;
    self.contactScroll.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    if(self.contactList.count > 0) {
        self.contactScroll.contentSize = CGSizeMake(width * self.contactList.count, height);
        
        [self.contactScroll setContentOffset:CGPointMake(0, 0)];
        for(NSUInteger i = 0; i < self.contactList.count; i++) {
            NSInteger offset = i*width;
            Contact *contact = [self.contactList objectAtIndex:i];
                        
            UIButton *button = (UIButton *)[self.contactScroll viewWithTag:(i*10 + 1)];
            if(!button) {
                button = [[UIButton alloc] initWithFrame:CGRectMake(offset, 0, height, height)];
                button.tag = i*10 + 1;
                [self.contactScroll addSubview:button];
                [button addTarget:self action:@selector(toUserDebts) forControlEvents:UIControlEventTouchUpInside];                
            }
            
            bool imageSet = NO;
            ABRecordID contactID = (ABRecordID)[contact.uniqueid integerValue];
            if(contactID != kABRecordInvalidID) {
                ABRecordRef record = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), contactID);
                if(record) {
                    if(ABPersonHasImageData(record)) {
                        NSData *imageData = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
                        
                        [button setBackgroundImage:[[UIImage alloc] initWithData:imageData] forState:UIControlStateNormal];
                        imageSet = YES;
                    }
                }
            }
            if(!imageSet)
                [button setBackgroundImage:[UIImage imageNamed:@"person.png"] forState:UIControlStateNormal];
            
            UILabel *label = (UILabel *)[self.contactScroll viewWithTag:(i*10 + 2)];
            if(!label) {
                label = [[UILabel alloc] initWithFrame:CGRectMake(offset, 0, width, 48)];
                label.tag = i*10 + 2;
                [self.contactScroll addSubview:label];
                label.font = [UIFont fontWithName:@"Helvetica" size:22];
                label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:.3];
                label.textColor = [UIColor whiteColor];
            }
            label.text = [@" " stringByAppendingString:contact.name];
        
            label = (UILabel *)[self.contactScroll viewWithTag:(i*10 + 3)];
            UILabel *label2 = (UILabel *)[self.contactScroll viewWithTag:(i*10 + 4)];
            if(!label) {
                label = [[UILabel alloc] initWithFrame:CGRectMake(offset + height, height - 35, width - height, 35)];
                label.tag = i*10 + 3;
                [self.contactScroll addSubview:label];
                label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
                label.font = [UIFont fontWithName:@"Avenir-Medium" size:24];                
                label.textColor = [UIColor whiteColor];
                label.textAlignment = UITextAlignmentCenter;
                label2 = [[UILabel alloc] initWithFrame:CGRectMake(offset + height, height - 47, width - height, 12)];
                label2.tag = i*10 + 4;
                [self.contactScroll addSubview:label2];
                label2.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
                label2.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
                label2.textColor = [UIColor whiteColor];
                label2.textAlignment = UITextAlignmentCenter;
            }
            NSInteger money = [contact.owes integerValue];
            if(money < 0) {
                //show an "owes" labels
                money *= -1;
                label.textColor = [UIColor redColor];
                label2.text = @"You owe";
            } else {
                label2.text = @"Owes you";
                label.textColor = [UIColor whiteColor];
            }
            label.text = [BillLogic formatMoneyWithInt:money];
        }
        
        self.contactPage.hidden = (self.contactList.count == 1);
        self.contactPage.numberOfPages = self.contactList.count;
        [self.contactPage setCurrentPage:0];
    } else {
        self.contactScroll.contentSize = CGSizeMake(width, height);
        [self.contactScroll setContentOffset:CGPointMake(0, 0)];
        
        //place holder image
        self.contactPage.alpha = 0.0;
        UIButton *button = (UIButton *)[self.contactScroll viewWithTag:1];
        if(!button) {
            button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, height, height)];
            button.tag = 1;
            [button addTarget:self action:@selector(toUserDebts) forControlEvents:UIControlEventTouchUpInside];
            [self.contactScroll addSubview:button];
        }
        
        //button.imageView.image.resizingMode = UIImageResizingModeStretch;
        [button setBackgroundImage:[UIImage imageNamed:@"person.png"] forState:UIControlStateNormal];
        
        UILabel *label = (UILabel *)[self.contactScroll viewWithTag:2];
        if(!label) {
            label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 48)];
            label.tag = 2;
            [self.contactScroll addSubview:label];
            label.font = [UIFont fontWithName:@"Helvetica" size:22];
            label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:.6];
            label.textColor = [UIColor whiteColor];
        }
        label.text = @" You are debt free";
        
        label = (UILabel *)[self.contactScroll viewWithTag:3];
        if(label) {
            label.hidden = YES;
        }
        
        label = (UILabel *)[self.contactScroll viewWithTag:4];
        if(label) {
            label.hidden = YES;
        }
    }
    self.contactScroll.pagingEnabled = YES;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //resize our UIScrollView to the correct size
    float height =  self.view.frame.size.height - self.contactScroll.frame.origin.y - 2;
    self.contactScroll.frame = CGRectMake(self.contactScroll.frame.origin.x, self.contactScroll.frame.origin.y, self.contactScroll.frame.size.width, height);
}

- (void)viewDidUnload
{
    [self setContactScroll:nil];
    [self setContactPage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - ScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger page = (scrollView.contentOffset.x/self.contactScroll.frame.size.width);
    [self.contactPage setCurrentPage:page];
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
