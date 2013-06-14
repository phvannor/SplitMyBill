//
//  Bill.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BillItem, BillPerson;

@interface Bill : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSNumber * rounding;
@property (nonatomic, retain) NSDecimalNumber * tax;
@property (nonatomic, retain) NSNumber * taxInDollars;
@property (nonatomic, retain) NSDecimalNumber * tip;
@property (nonatomic, retain) NSNumber * tipInDollars;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * total;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *items;
@property (nonatomic, retain) NSSet *people;
@end

@interface Bill (CoreDataGeneratedAccessors)

- (void)addItemsObject:(BillItem *)value;
- (void)removeItemsObject:(BillItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

- (void)addPeopleObject:(BillPerson *)value;
- (void)removePeopleObject:(BillPerson *)value;
- (void)addPeople:(NSSet *)values;
- (void)removePeople:(NSSet *)values;

@end
