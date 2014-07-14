//
//  KeyManager.h
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BTCPrivateKeyAddress;

@interface CNKeyManager : NSObject

// Returns the public key in the keychain.
+ (NSString *)getPublicKey;

// Create and store a new private key in the keychain.
+ (void)generatePrivateKey;

// Returns the private key in the keychain.
+ (NSString *)getPrivateKey;
+ (BTCPrivateKeyAddress *)privateKeyAddress;

// Resets the private key in the keychain.
+ (void)resetKeyManager;

@end
