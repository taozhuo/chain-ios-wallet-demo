//
//  CNBitcoinSendManager.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNBitcoinSendManager.h"
#import "CNKeyManager.h"
#import "Chain.h"
#import <CoreBitcoin/CoreBitcoin+Categories.h>
#import <CoreBitcoin/BTCChainCom.h>

#define CHAIN_TOKEN @"GUEST-TOKEN"
#define CHAIN_ERROR_DOMAIN @"com.Chain.Chain-Wallet.ErrorDomain"

@implementation CNBitcoinSendManager

+ (void)sendAmount:(BTCSatoshi)satoshiAmount receiveAddresss:(NSString *)receiveAddress fee:(BTCSatoshi)fee completionHandler:(void (^)(NSDictionary *dictionary, NSError *error))completionHandler {
    
    // Based on CoreBitcoin / CoreBitcoin / BTCTransaction+Tests.m
    BTCPrivateKeyAddress *privateKeyAddress = [CNKeyManager privateKeyAddress];
    BTCKey *key = privateKeyAddress.key;
    NSLog(@"Sending from Address: %@", [key.publicKeyAddress base58String]);
    
    [CNBitcoinSendManager sendFromPrivateKey:key to:[BTCPublicKeyAddress addressWithBase58String:receiveAddress] change:key.publicKeyAddress amount:satoshiAmount fee:fee completionHandler:^(BTCTransaction *transaction, NSError *error) {
        if (transaction) {
            NSString *transactionHexString = BTCHexStringFromData([transaction data]);
            [[Chain sharedInstance] sendTransaction:transactionHexString completionHandler:completionHandler];
        } else {
            if (!error) {
                NSString *domain = @"com.Chain.Chain-Wallet.ErrorDomain";
                NSString *desciption = @"Unable to generate transaction.";
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : desciption};
                
                error = [NSError errorWithDomain:domain code:-101 userInfo:userInfo];
            }
            completionHandler(nil, error);
        }
    }];
}

+ (NSArray *)unspentOutputs:(NSDictionary *)responseDictionary {
    NSArray *responseOutputArray = [responseDictionary valueForKey:@"results"];
    NSMutableArray *outputs = [NSMutableArray array];
    
    for (NSDictionary* item in responseOutputArray) {
        BTCTransactionOutput* txout = [[BTCTransactionOutput alloc] init];

        txout.value = [item[@"value"] longLongValue];
        txout.script = [[BTCScript alloc] initWithString:item[@"script"]];
        txout.index = [item[@"output_index"] intValue];
        txout.transactionHash = (BTCReversedData(BTCDataWithHexString(item[@"transaction_hash"])));
        [outputs addObject:txout];
    }
    return outputs;
}

// Based on CoreBitcoin / CoreBitcoin / BTCTransaction+Tests.m
+ (void)sendFromPrivateKey:(BTCKey *)privateKey to:(BTCPublicKeyAddress *)destinationAddress change:(BTCPublicKeyAddress *)changeAddress amount:(BTCSatoshi)amount fee:(BTCSatoshi)fee completionHandler:(void (^)(BTCTransaction *transaction, NSError *error))completionHandler {
    
    BTCKey *key = privateKey;
    
    NSString *sendingAddressString = [key.publicKeyAddress base58String];
    [[Chain sharedInstance] getAddressUnspents:sendingAddressString completionHandler:^(NSDictionary *dictionary, NSError *error) {
        if (error) {
            completionHandler(nil, error);
        } else {
            NSArray *utxos = [CNBitcoinSendManager unspentOutputs:dictionary];
            
            // Find enough outputs to spend the total amount.
            BTCSatoshi totalAmount = amount + fee;
            
            // Sort utxo in order of amount.
            utxos = [utxos sortedArrayUsingComparator:^(BTCTransactionOutput* obj1, BTCTransactionOutput* obj2) {
                if ((obj1.value - obj2.value) < 0) return NSOrderedAscending;
                else return NSOrderedDescending;
            }];
            
            NSMutableArray *txouts = [NSMutableArray array];
            
            BTCSatoshi balance = 0;
            
            for (BTCTransactionOutput *txout in utxos) {
                if (txout.script.isHash160Script) {
                    [txouts addObject:txout];
                    balance = balance + txout.value;
                }
                if (balance >= totalAmount) {
                    break;
                }
            }
            
            // Check for insufficent funds.
            if (!txouts || balance < totalAmount) {
                NSString *errorDescription = [NSString stringWithFormat:@"Insufficient funds. Your balance of %llu is less than transaction amount:%llu", balance, totalAmount];
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorDescription};
                error = [NSError errorWithDomain:CHAIN_ERROR_DOMAIN code:-102 userInfo:userInfo];
                
                completionHandler(nil, error);
            } else {
                // Create a new transaction
                BTCTransaction *tx = [[BTCTransaction alloc] init];

                BTCSatoshi spentCoins = 0;
                
                // Add all outputs as inputs
                for (BTCTransactionOutput *txout in txouts) {
                    BTCTransactionInput *txin = [[BTCTransactionInput alloc] init];
                    txin.previousHash = txout.transactionHash;
                    txin.previousIndex = txout.index;
                    [tx addInput:txin];
                    
                    spentCoins += txout.value;
                }
                
                // Add required outputs - payment and change
                BTCTransactionOutput *paymentOutput = [BTCTransactionOutput outputWithValue:amount address:destinationAddress];
                BTCTransactionOutput *changeOutput = [BTCTransactionOutput outputWithValue:(spentCoins - totalAmount) address:changeAddress];
                
                [tx addOutput:paymentOutput];
                [tx addOutput:changeOutput];
                
                // Sign all inputs. We now have both inputs and outputs defined, so we can sign the transaction.
                for (int i = 0; i < txouts.count; i++) {
                    BTCTransactionOutput *txout = txouts[i]; // output from a previous tx which is referenced by this txin.
                    BTCTransactionInput *txin = tx.inputs[i];
                    
                    BTCScript *sigScript = [[BTCScript alloc] init];
                    NSData* hash = [tx signatureHashForScript:txout.script inputIndex:i hashType:BTCSignatureHashTypeAll error:&error];
                    
                    if (!hash) {
                        NSString *errorDescription = @"Unable to create a hash to sign the transctions.";
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorDescription};
                        error = [NSError errorWithDomain:CHAIN_ERROR_DOMAIN code:-102 userInfo:userInfo];
                        
                        completionHandler (nil, error);
                        return;
                    } else {
                        NSData *signature = [key signatureForHash:hash];
                        
                        NSMutableData *signatureForScript = [signature mutableCopy];
                        unsigned char hashtype = BTCSignatureHashTypeAll;
                        [signatureForScript appendBytes:&hashtype length:1];
                        [sigScript appendData:signatureForScript];
                        [sigScript appendData:key.publicKey];
                        
                        txin.signatureScript = sigScript;
                    }
                }
                completionHandler(tx, error);
            }
        }
    }];
}

@end
