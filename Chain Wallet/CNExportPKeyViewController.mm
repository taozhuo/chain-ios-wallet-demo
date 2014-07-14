//
//  CNExportPKeyViewController.mm
//  
//
//
//

#import "CNExportPKeyViewController.h"
#import "QREncoder.h"
#import "CNKeyManager.h"

@interface CNExportPKeyViewController ()

@end

@implementation CNExportPKeyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.MyPrivateKey = [CNKeyManager getPrivateKey];
    [self.MyAddressLabel setTitle:self.MyPrivateKey forState:UIControlStateNormal];
    self.MyAddressLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.QREncoderView.image = [QREncoder renderDataMatrix:[QREncoder encodeWithECLevel:1 version:1 string:self.MyPrivateKey]
                                     imageDimension:self.QREncoderView.frame.size.width];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissReceiveView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)ShareMyAddress:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"Export My Private Key" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Text Message", @"Copy to Clipboard", nil];
    [actionSheet showInView:self.view];
}


#pragma mark - Share Action Sheet

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self shareViaTextMessage];
    }
    if (buttonIndex == 1) {
        [self copyToClipboard];
    }
}

#pragma mark - Share Methods

- (void)copyToClipboard {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.MyPrivateKey;
}

- (void)shareViaTextMessage {
    //check if the device can send text messages
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device cannot send text messages" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //set message text
    NSString * message = [NSString stringWithFormat:@"My Private Key:\n\n%@", self.MyPrivateKey];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setBody:message];
    
    // Render QR Code as image attachment
    NSData *imageData = UIImagePNGRepresentation(self.QREncoderView.image);
    [messageController addAttachmentData:imageData typeIdentifier:@"public.data" filename:@"image.png"];
    
    // Present message view controller on screen
    [messageController.navigationBar setTintColor:[UIColor whiteColor]];
    [self presentViewController:messageController animated:YES completion:^{
        // The global status bar color doesn't apply to this view, so we have to explcitly set it.
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }];

}

#pragma mark - MFMailComposeViewControllerDelegate methods
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Oups, error while sendind SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
