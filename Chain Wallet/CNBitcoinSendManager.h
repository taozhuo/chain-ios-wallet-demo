//
//  CNBitcoinSendManager.h
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBitcoin/CoreBitcoin+Categories.h>

@interface CNBitcoinSendManager : NSObject

+ (void)sendAmount:(BTCSatoshi)satoshiAmount receiveAddresss:(NSString *)receiveAddress fee:(BTCSatoshi)fee completionHandler:(void (^)(NSDictionary *dictionary, NSError *error))completionHandler;

@end
