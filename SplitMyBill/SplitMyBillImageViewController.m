//
//  SplitMyBillImageViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 3/5/13.
//
//

#import "SplitMyBillImageViewController.h"

@interface SplitMyBillImageViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end

@implementation SplitMyBillImageViewController
@synthesize bill = _bill;
- (IBAction)buttonBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    
    
}

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
    
    self.image.image = [UIImage imageWithData:self.bill.image];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setImage:nil];
    [super viewDidUnload];
}
@end
