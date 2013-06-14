//
//  SplitMyBillPartySelection.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 2/17/13.
//
//

#import <UIKit/UIKit.h>
#import "BillLogic.h"
#import "BillUser.h"
#import "SplitMyBillContactEditorViewController.h"

/*
@protocol SplitMyBillPartyDelegate
- (Contact *) SplitMyBillPartyDelegate:(id)Party addContact:(ABRecordRef) record;
@end
*/

@protocol PartySelectionDataSource
@property (nonatomic, weak) BillLogic *logic;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@end

@protocol PartySelectionDelegate <NSObject>
- (bool) editContact:(Contact *)contact;
- (bool) editUser:(BillUser *)user;
- (bool) showController:(UIViewController *)controller;
- (void) removeController;
- (void) popController;

@optional
- (void) nextScreen;
- (void) usersChanged:(bool)added;
@end

@interface SplitMyBillPartySelection : UIView <ContactEditorDelegate>

@property (nonatomic, weak) id<PartySelectionDataSource> dataSource;
@property (nonatomic, weak) id<PartySelectionDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *partySize;
@property (nonatomic, weak) IBOutlet UIButton *buttonNext;
@property (nonatomic, weak) IBOutlet UIButton *buttonContact;
- (IBAction)addContact:(id)sender;
@property (nonatomic, weak) IBOutlet UIButton *buttonGeneric;
- (IBAction)addGeneric:(id)sender;
- (IBAction)nextScreen;
- (bool) loadData;
- (void) reloadData;
@end
