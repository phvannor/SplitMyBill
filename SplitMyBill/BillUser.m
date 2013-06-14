//
//  BillUser.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BillUser.h"
#import "ContactContactInfo.h"

@interface BillUser()
@end

@implementation BillUser
@synthesize person = _person;
- (id)initWithPerson:(BillPerson *)person {
    self = [super init];
    
    self.person = person;
    self.name = person.name;
    self.abbreviation = person.initials;
    self.phone = person.phone;
    self.email = person.email;
    self.isSelf = [person.isMe boolValue];
    self.contact = person.contact;
    self.isDirty = NO;
    
    return self;
}

@synthesize isSelf = _isSelf;

@synthesize name = _name;
- (void) setName:(NSString *)name {
    _name = name;
    if(self.person && !self.contact) {
        self.person.name = _name;
    }
    self.isDirty = YES;
}
@synthesize abbreviation = _abbreviation;
- (void) setAbbreviation:(NSString *)abbreviation {
    _abbreviation = abbreviation;
    self.isDirty = YES;
    if(_abbreviation.length > 3) {
        _abbreviation = [_abbreviation substringToIndex:3];        
    }
    if(self.person && !self.contact) {
        self.person.initials = _abbreviation;
    }
}

@synthesize phone = _phone;
- (void) setPhone:(NSString *)phone {
    _phone = phone;
    if(self.person) //selected phone if contact...
        self.person.phone = _phone;
        
    self.isDirty = YES;
}

@synthesize email = _email;
- (void) setEmail:(NSString *)email {
    _email = email;
    if(self.person)
        self.person.email = _email;
    
    self.isDirty = YES;
}

@synthesize contact = _contact;
- (void) setContact:(Contact *)contact {
    _contact = contact;
    if(self.person) {
        self.person.contact = contact;
        if(contact) {
            //fall back to name in contact record
            self.person.name = nil;
            self.person.email = nil;
        }
    }
    
    if(contact == nil) {
        return;
    }
    
    self.name = contact.name;
    self.abbreviation = contact.initials;
    self.phone = contact.contactinfo.phone;
    self.email = contact.contactinfo.email;
}

@synthesize isDirty = _isDirty;

- (BillUser *) initWithName:(NSString *)name 
           andAbbreviation:(NSString *)abbreviation 
{
    self =[super init];
    if(!self)
        return nil;
    
    self.name = name;
    self.abbreviation = abbreviation;
    self.isDirty = YES;
    return self;   
}

- (BOOL) isEqual:(id)object {
    if(![object isKindOfClass:[BillUser class]]) {
        return NO;
    }
    
    BillUser *compareUser = object;
    if(![self.name isEqualToString:compareUser.name]) {
        return NO;        
    }

    if(self.contact != compareUser.contact)
        return NO;
    
    return YES;
}

//allow encode/init with coder so users can be stored in our user preferences
//currently only one allowed for "default", eventually will allow quick picks
//as well
- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.abbreviation forKey:@"abbreviation"];
    [coder encodeObject:self.phone forKey:@"phone"];
    [coder encodeObject:self.email forKey:@"email"];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    self = [[BillUser alloc] init];
    if (self != nil)
    {
        self.name = [coder decodeObjectForKey:@"name"];
        self.abbreviation =  [coder decodeObjectForKey:@"abbreviation"];
        self.phone = [coder decodeObjectForKey:@"phone"];
        self.email = [coder decodeObjectForKey:@"email"];
        self.isDirty = NO;
    }   
    return self;
}

@end
