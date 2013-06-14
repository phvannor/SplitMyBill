//
//  BillUser.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/3/12.
//  Copyright (c) 2012. All rights reserved.
//
//  represents a user on a bill
//  contains data associated only with the user identity (name ,etc)
//  and nothing around the actual bill

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "Contact.h"
#import "BillPerson.h"

@interface BillUser : NSObject <NSCoding>
@property (nonatomic, strong) BillPerson *person;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *abbreviation; //1-3 Letter abbreviation
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, strong) Contact *contact;
@property (nonatomic) bool isSelf;
@property (nonatomic) bool isDirty;  //set if any value is changed

//designated initializer
- (id)initWithName:(NSString *)name andAbbreviation:(NSString *)abbreviation;
- (id)initWithPerson:(BillPerson *)person;
@end
