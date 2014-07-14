//
//  CNWelcomeViewController.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNWelcomeViewController.h"
#import "CNKeyManager.h"

@implementation CNWelcomeViewController

- (IBAction)generateAnAddressAction:(id)sender {
    [CNKeyManager generatePrivateKey];
    
    NSLog(@"Generated an address:");
    NSString *publicKey = [CNKeyManager getPublicKey];
    NSLog(@"Public: %@", publicKey);
    
    // Present transactions view contorller.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"transactionsNavigationController"];
    [self presentViewController:viewController animated:YES completion:nil];
}

@end
