//
//  SMBBillWhoViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/9/13.
//
//

#import "SMBBillWhoViewController.h"
#import "SplitMyBillPartySelection.h"
#import "SMBBillController.h"

@interface SMBBillWhoViewController () <PartySelectionDataSource, PartySelectionDelegate>
@property (weak, nonatomic) IBOutlet UIView *partyView;

@property (nonatomic, weak) BillUser *editUser;
@property (nonatomic, weak) Contact *editContact;

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
    
    [(SplitMyBillPartySelection *)self.partyView reloadData];
    
    self.title = @"Who's on the Bill?";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //load in the party selection...
    SplitMyBillPartySelection *partyWin = (SplitMyBillPartySelection *)self.partyView;
    partyWin.dataSource = self;
    partyWin.delegate = self;
    if(!partyWin.loadData) {
        //throw error of some kind...?
        
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"edit user"]) {
        if(self.editContact) {
            [segue.destinationViewController setContact:self.editContact];
            [segue.destinationViewController setDelegate: self.partyView];
        } else {
            [(SplitMyBillContactEditorViewController *)segue.destinationViewController setUser:self.editUser];
            [segue.destinationViewController setDelegate: self.partyView];
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
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
    return billRoot.billlogic;
}

- (NSManagedObjectContext *) managedObjectContext {
    SMBBillController *billRoot = (SMBBillController *)self.tabBarController;
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

- (bool) showController:(UIViewController *)controller {
    [self presentViewController:controller animated:YES completion:NULL];
    return YES;
}

- (void) removeController
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) popController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) dismissController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
