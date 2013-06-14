//
//  BillPerson.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Bill, BillItem, Contact;

@interface BillPerson : NSManagedObject

@property (nonatomic, retain) NSString * initials;
@property (nonatomic, retain) NSNumber * isMe;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) Bill *bill;
@property (nonatomic, retain) Contact *contact;
@property (nonatomic, retain) NSSet *items;
@end

@interface BillPerson (CoreDataGeneratedAccessors)

- (void)addItemsObject:(BillItem *)value;
- (void)removeItemsObject:(BillItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
