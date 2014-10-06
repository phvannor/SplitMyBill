//
//  SplitMyBillMainScreenViewController.h
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 9/19/12.
//
//

#import <UIKit/UIKit.h>

@interface SMBMainScreenViewController : UIViewController <UICollectionViewDataSource>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (IBAction)buttonNew:(id)sender;
- (IBAction)actionAllDebts:(id)sender;
- (IBAction)actionAllBills:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *oweField;
@property (weak, nonatomic) IBOutlet UILabel *owedField;

@end
