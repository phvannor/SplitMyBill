//
//  SplitMyBillContactDebtViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/21/12.
//
//

#import <UIKit/UIKit.h>
#import "Contact.h"
#import <CoreData/CoreData.h>

@interface SplitMyBillContactDebtViewController : UIViewController
@property (nonatomic, weak) Contact *contact;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
- (void) outsideDebtSettlementForAmount:(NSDecimalNumber *)amount toUser:(NSString *)userID withNote:(NSString *)note;
@end
