//
//  SplitMyBillImageViewController.m
//  SplitMyBill
//
//  Created by Phillip Van Nortwick on 3/5/13.
//
//

#import "SplitMyBillImageViewController.h"

@interface SplitMyBillImageViewController () <UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end

@implementation SplitMyBillImageViewController
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

- (IBAction)addImage:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
    {
        // Show user message
        return;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Displays a control that allows the user to choose picture or
    // movie capture, if both are available:
    cameraUI.allowsEditing = NO;
    //cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    //store the file
    // UIImage *originalImage; //, *editedImage, *imageToSave;
    // originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Save the new image (original or edited) to the Camera Roll
    //UIImageWriteToSavedPhotosAlbum (imageToSave, nil, nil , nil);
    //self.bill.image = UIImageJPEGRepresentation(originalImage, 1.0f);
    /*
    NSError *error;
    
    if(![self.managedObjectContext save:&error]) {
        //throw error...
        
    }
    */
    
    //store image as visible...
    //self.billImage.image = originalImage;
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
