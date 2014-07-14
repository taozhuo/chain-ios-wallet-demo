//
//  SendViewController.h
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CNSendViewController : UIViewController <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UILabel *sentToAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountAvailable;
@property (nonatomic) NSString *sendToAddress;

@end
