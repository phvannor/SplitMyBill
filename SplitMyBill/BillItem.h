//
//  BillItem.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Bill, BillPerson;

@interface BillItem : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * preTax;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSNumber * split;
@property (nonatomic, retain) Bill *bill;
@property (nonatomic, retain) NSSet *people;
@end

@interface BillItem (CoreDataGeneratedAccessors)

- (void)addPeopleObject:(BillPerson *)value;
- (void)removePeopleObject:(BillPerson *)value;
- (void)addPeople:(NSSet *)values;
- (void)removePeople:(NSSet *)values;

@end
