//
//  Contact.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/25/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ContactContactInfo, Debt;

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSString * initials;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * owes;
@property (nonatomic, retain) NSNumber * sortorder;
@property (nonatomic, retain) NSNumber * uniqueid;
@property (nonatomic, retain) ContactContactInfo *contactinfo;
@property (nonatomic, retain) NSSet *debts;
@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addDebtsObject:(Debt *)value;
- (void)removeDebtsObject:(Debt *)value;
- (void)addDebts:(NSSet *)values;
- (void)removeDebts:(NSSet *)values;

@end
