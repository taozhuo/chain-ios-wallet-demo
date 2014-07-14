//
//  KeyManager.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNKeyManager.h"
#import "KeychainItemWrapper.h"
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <CoreBitcoin/CoreBitcoin+Categories.h>

#define KEYCHAIN_PRIVATE_KEY_IDENTIFIER @"BTCKey"

@implementation CNKeyManager

+ (NSString *)getPublicKey {
    BTCKey *key = [CNKeyManager _key:NO];
    
    BTCAddress *publicKeyAddress = [BTCPublicKeyAddress addressWithData:[key.publicKey BTCHash160]];
    
    return [publicKeyAddress base58String];
}

+ (NSString *)getPrivateKey {
    BTCKey *key = [CNKeyManager _key:NO];
    
    BTCAddress *privateKeyAddress = [BTCPrivateKeyAddress addressWithData:key.privateKey];
    
    return [privateKeyAddress base58String];
}

+ (BTCPrivateKeyAddress *)privateKeyAddress {
    BTCKey *key = [CNKeyManager _key:NO];
    return [BTCPrivateKeyAddress addressWithData:key.privateKey];
}

+ (void)generatePrivateKey {
    [self _key:YES];
}

+ (BTCKey *)_generateKey {
    NSUInteger length = 32;
    NSMutableData *secret = [NSMutableData dataWithLength:length];
    OSStatus sanityCheck = noErr;

    sanityCheck = SecRandomCopyBytes(kSecRandomDefault, length, secret.mutableBytes);
    if (sanityCheck != noErr) {
        NSLog(@"Issue generating a private key.");
    }
    
    NSAssert(secret.length == 32, @"secret must be 32 bytes long");
    BTCKey *key = [[BTCKey alloc] initWithPrivateKey:secret];
    
    return key;
}

+ (BTCKey *)_key:(BOOL)createNewKey {
    // If we want to prevent other apps from the same organization from accessing this an access group must be set.
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_PRIVATE_KEY_IDENTIFIER accessGroup:nil];
    NSString *privateKeyHexString = (NSString *)[wrapper objectForKey:(__bridge id)kSecValueData];
    
    BTCKey *key = nil;
    
    if (createNewKey) {
        key = [self _generateKey];
        [wrapper setObject:key.privateKey.hexString forKey:(__bridge id)kSecValueData];
    }
    else if ([privateKeyHexString length]) {
        key = [[BTCKey alloc] initWithPrivateKey:BTCDataWithHexString(privateKeyHexString)];
    }

    return key;
}

+ (void)resetKeyManager {
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_PRIVATE_KEY_IDENTIFIER accessGroup:nil];
    [wrapper setObject:@"" forKey:(__bridge id)kSecValueData];
}

@end
