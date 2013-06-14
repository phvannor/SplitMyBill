//
//  SplitMyBillContactEditorViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import <UIKit/UIKit.h>
#import "Contact.h"
#import "ContactContactInfo.h"
#import "BillUser.h"

@protocol ContactEditorDelegate
- (void) ContactEditor:(id)Editor Close:(bool)SaveChanges;
- (void) ContactEditorDelete:(id)Editor;
@end

@interface SplitMyBillContactEditorViewController : UIViewController
@property (nonatomic, weak) Contact *contact;
@property (nonatomic, weak) BillUser *user;
@property (nonatomic, weak) id delegate;
@end
