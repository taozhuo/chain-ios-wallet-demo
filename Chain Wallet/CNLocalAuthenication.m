//
//  CNLocalAuthenication.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNLocalAuthenication.h"
#import "CNKeyManager.h"

#define TOUCH_ID_FALLBACK_ALERT_VIEW_TAG 3

@interface CNLocalAuthenication ()
@property (copy, nonatomic) void (^completion)(void);
@end

@implementation CNLocalAuthenication

+ (BOOL)isTouchIDAvailable {
    LAContext *context = [[LAContext alloc] init];
    NSError *error;
    BOOL success;
    
    // Test if we can evaluate the policy, this test will tell us if Touch ID is available and enrolled
    success = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    return success;
}

- (void)authenticateWithTouchID:(NSString *)localReason successBlock:(void (^)(void))successBlock {
    [self authenticateWithTouchID:localReason disableFallbackAuthWithReason:nil successBlock:successBlock];
}

- (void)authenticateWithTouchID:(NSString *)localReason disableFallbackAuthWithReason:(NSString *)fallBackErrorAlertString successBlock:(void (^)(void))successBlock {
    LAContext *context = [[LAContext alloc] init];
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:localReason reply:^(BOOL success, NSError *authenticationError) {
        if (success && successBlock) {
             dispatch_async(dispatch_get_main_queue(), successBlock);
        } else {
            if (authenticationError.code == kLAErrorUserFallback) {
                // Fallback button pressed.
                if ([fallBackErrorAlertString length]) {
                    // Show error.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry!" message:fallBackErrorAlertString delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                        [alertView show];
                    });
                } else {
                    // Prompt for private key.
                    self.completion = successBlock;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Touch ID Required to Access Private Key"
                                                                            message:@"Paste your private key to send."
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Cancel"
                                                                  otherButtonTitles:@"Continue", nil];
                        
                        [alertView setAlertViewStyle:UIAlertViewStyleSecureTextInput];
                        [alertView textFieldAtIndex:0].placeholder = @"Private Key";
                        alertView.tag = TOUCH_ID_FALLBACK_ALERT_VIEW_TAG;
                        [alertView show];
                    });
                }
            }
        }
    }];
}


#pragma mark - Touch ID Fallback

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == TOUCH_ID_FALLBACK_ALERT_VIEW_TAG && buttonIndex != alertView.cancelButtonIndex) {
        NSString *publicKeyString = [CNKeyManager getPublicKey];
        NSString *privateKeyString = [CNKeyManager getPrivateKey];
        NSString *textFieldString = [alertView textFieldAtIndex:0].text;
        
        if ([textFieldString length] && [privateKeyString isEqual:textFieldString]) {
            if (self.completion) {
                dispatch_async(dispatch_get_main_queue(), self.completion);
            }
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"Unable to send. The entered private key is not for: %@", publicKeyString];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Private Key" message:errorMessage delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alertView show];
        }
    }
    
    self.completion = nil;
}

@end
