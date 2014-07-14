//
//  HomeViewController.h
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CNHomeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property NSString *address;
@property NSString *sendToAddress;
@property (weak, nonatomic) IBOutlet UILabel *transactionAmount;
@property (weak, nonatomic) IBOutlet UILabel *transactionAddress;
@property (weak, nonatomic) IBOutlet UILabel *transactionDate;

@end

