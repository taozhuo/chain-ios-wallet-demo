//
//  CNLocalAuthenication.h
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>

@interface CNLocalAuthenication : NSObject

+ (BOOL)isTouchIDAvailable;
- (void)authenticateWithTouchID:(NSString *)localReason successBlock:(void (^)(void))successBlock;
- (void)authenticateWithTouchID:(NSString *)localReason disableFallbackAuthWithReason:(NSString *)fallBackErrorAlertString successBlock:(void (^)(void))successBlock;

@end
