//
//  CNAppDelegate.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNAppDelegate.h"
#import "CNKeyManager.h"
#import "Chain.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface CNAppDelegate ()
            

@end

@implementation CNAppDelegate
            

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // REPLACE THIS LIMITED "GUEST-TOKEN" WITH YOUR API TOKEN FROM CHAIN.COM
    [Chain sharedInstanceWithToken:@"GUEST-TOKEN"];
    
    // REMOVE THIS LINE AFTER DEFINING YOUR API TOKEN
    NSLog(@"\n!!!\nYOUR ARE USING A LIMITED GUEST TOKEN FOR THE CHAIN API. PLEASE VISIT CHAIN.COM AND REGISTER TO RECIEVE YOUR PERSONAL API TOKEN.\n!!!\n");
    
    
    
    // Style the navigation bar
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x12cae1)];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"Avenir" size:21.0], NSFontAttributeName, nil]];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Uncomment to test the welcome screen. Backup your private key first.
//    [CNKeyManager resetKeyManager];
    
    // Show welcome screen if we haven't generated an address.
    NSString *publicKey = [CNKeyManager getPublicKey];
    UIViewController *viewController  = nil;
//    if (![publicKey length]) {
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"welcomeViewController"];
//    } else {
//        viewController = [storyboard instantiateViewControllerWithIdentifier:@"transactionsNavigationController"];
//    }
    
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
