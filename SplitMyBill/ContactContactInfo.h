//
//  ContactContactInfo.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface ContactContactInfo : NSManagedObject

@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) Contact *contact;

@end
