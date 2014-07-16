//
//  NSString+Additions.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "NSString+Additions.h"
#import <CoreBitcoin/CoreBitcoin+Categories.h>

@implementation NSString(Additions)

+ (NSString *)stringWithSatoshiInBTCFormat:(BTCSatoshi)satoshiAmount {
    NSDecimalNumber *BTCValueDecimalNumber = [[NSDecimalNumber alloc] initWithLongLong:satoshiAmount];
    BTCValueDecimalNumber = [BTCValueDecimalNumber decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:BTCCoin]];
    
    NSNumberFormatter *twoDecimalPlacesFormatter = [[NSNumberFormatter alloc] init];
    [twoDecimalPlacesFormatter setMaximumFractionDigits:10];
    [twoDecimalPlacesFormatter setMinimumFractionDigits:2];
    [twoDecimalPlacesFormatter setMinimumIntegerDigits:1];
    
    return [twoDecimalPlacesFormatter stringFromNumber:BTCValueDecimalNumber];
}

@end
