//
//  Debt.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/24/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Debt : NSManagedObject

@property (nonatomic, retain) NSNumber * amount;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSNumber * settled;
@property (nonatomic, retain) NSNumber * isSettleEntry;
@property (nonatomic, retain) Contact *contact;

@end
