//
//  CNExportPKeyViewController.mm
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNExportPKeyViewController.h"
#import "QREncoder.h"
#import "CNKeyManager.h"

@interface CNExportPKeyViewController()
@property (weak, nonatomic) IBOutlet UIImageView *QREncoderView;
@property (weak, nonatomic) IBOutlet UIButton *addressLabel;
@end

@implementation CNExportPKeyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.addressLabel setTitle:[CNKeyManager getPrivateKey] forState:UIControlStateNormal];
    self.addressLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.QREncoderView.image = [QREncoder renderDataMatrix:[QREncoder encodeWithECLevel:1 version:1 string:[CNKeyManager getPrivateKey]]
                                     imageDimension:self.QREncoderView.frame.size.width];
}

- (IBAction)dismissReceiveView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)shareMyAddress:(id)sender {
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
    pasteboard.string = [CNKeyManager getPrivateKey];;
}

- (void)shareViaTextMessage {
    //check if the device can send text messages
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device cannot send text messages" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Set message text
    NSString *message = [NSString stringWithFormat:@"My Private Key:\n\n%@", [CNKeyManager getPrivateKey]];
    
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

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result {
    switch (result) {
        case MessageComposeResultFailed: {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Oups, error while sendind SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }   
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
