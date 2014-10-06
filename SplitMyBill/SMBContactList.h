//
//  SplitMyBillContactList.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import <UIKit/UIKit.h>

@interface SMBContactList : UIViewController

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

-(IBAction)addContact:(id)sender;

@end
