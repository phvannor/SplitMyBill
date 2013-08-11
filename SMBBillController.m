//
//  SMBBillController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 8/9/13.
//
//

#import "SMBBillController.h"

@interface SMBBillController ()
@property (nonatomic) bool settingTotalIsSimple;
@property (nonatomic) bool settingDiscountsPreTax;
@end

@implementation SMBBillController

@synthesize billlogic = _billlogic;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize bill = _bill;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    //load up defaults for the bill
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.settingTotalIsSimple = [defaults boolForKey:@"UserTotalSimple"];
    self.settingDiscountsPreTax = [defaults boolForKey:@"DiscountsPreTax"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark public setting data
- (bool) totalIsSimple {
    return self.settingTotalIsSimple;
}

- (bool) discountsPreTax {
    return self.settingDiscountsPreTax;
}

@end
