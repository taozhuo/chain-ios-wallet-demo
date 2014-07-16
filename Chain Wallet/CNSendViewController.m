//
//  SendViewController.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNSendViewController.h"
#import "CNBitcoinSendManager.h"
#import "NSString+Additions.h"
#import <CoreBitcoin/CoreBitcoin+Categories.h>

#define FIXED_FEE 10000

@interface CNSendViewController ()
@property BTCSatoshi balance;
@end

@implementation CNSendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.amountTextField becomeFirstResponder];
    [self.sentToAddressLabel setText: self.sendToAddress];
    self.balance = [[[NSUserDefaults standardUserDefaults] valueForKey:@"balance"] unsignedIntegerValue];
    
    // A transaction requires a miner fee
    BTCSatoshi availableBalance = self.balance - FIXED_FEE;
    self.amountAvailable.text = [NSString stringWithFormat:@"฿ %@ Available (after miner fee)", [NSString stringWithSatoshiInBTCFormat:availableBalance]];
}

#pragma mark - IB Actions

- (IBAction)sendButtonPressed:(id)sender {
    [self presentConfirmationAlert];
}

- (IBAction)cancelSendViewController:(id)sender {
    [self.amountTextField resignFirstResponder];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Send Method

- (void)initiateSend {
    [self showSendingSpinner];
    NSString *amountString = self.amountTextField.text;
    NSDecimalNumber *amountDecimalNumber = [NSDecimalNumber decimalNumberWithString:amountString];
    NSDecimalNumber *satoshiAmountDecimalNumber = [amountDecimalNumber decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithUnsignedInteger:BTCCoin]];
    
    NSUInteger satoshiAmountInteger = [satoshiAmountDecimalNumber unsignedIntegerValue];
    
    __weak UIViewController *presentingViewController = self.presentingViewController;

    BTCSatoshi fee = FIXED_FEE;
    if ([self.sendToAddress length]) {
        [CNBitcoinSendManager sendAmount:(NSUInteger)satoshiAmountInteger receiveAddresss:self.sendToAddress fee:fee completionHandler:^(NSDictionary *dictionary, NSError *error) {
            NSLog(@"%@", dictionary);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [self _presentErrorAlert:error.localizedDescription];
                } else {
                    [self.amountTextField resignFirstResponder];
                    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }
            });
        }];
    } else {
        NSString *errorString = @"Send to address does not exist.";
        [self _presentErrorAlert:errorString];
    }
}

#pragma mark - Alert Views

- (void)_presentErrorAlert:(NSString *)errorString {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Sending" message:errorString delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
    [self showSendButton];
}

- (void)presentConfirmationAlert {
    NSString *amountString = self.amountTextField.text;
    NSString *confirmationMessage  = [NSString stringWithFormat:@"Are you sure you want to send ฿ %@ to %@?", amountString, self.sendToAddress];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Send Bitcoin?"
                                                        message:confirmationMessage
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Send", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1)
        [self initiateSend];
}

#pragma mark - Send Button States

- (void)showSendingSpinner {
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ai];
    [ai startAnimating];
}

- (void)showSendButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self.sendButton action:@selector(sendButtonPressed:)];
}

- (IBAction)userTypedAmount:(id)sender {
    if (((UITextField*)sender).text.length > 0) {
        [self.sendButton setEnabled:YES];
    } else {
        [self.sendButton setEnabled:NO];
    }
}

@end
