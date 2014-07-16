//
//  NSString+Additions.h
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBitcoin/CoreBitcoin+Categories.h>

@interface NSString(Additions)

+ (NSString *)stringWithSatoshiInBTCFormat:(BTCSatoshi)satoshiAmount;

@end
