//
//  HomeViewController.m
//  Chain Wallet
//
//  Copyright (c) 2014 Chain Inc. All rights reserved.
//

#import "CNHomeViewController.h"
#import "CNSendViewController.h"
#import "CNExportPKeyViewController.h"
#import "CDZQRScanningViewController.h"
#import "Chain.h"
#import "CNKeyManager.h"
#import "CNLocalAuthenication.h"
#import <CoreBitcoin/CoreBitcoin+Categories.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define SEND_METHOD_ACTION_SHEET_TAG 1
#define OPTIONS_ACTION_SHEET_TAG 2

@interface CNHomeViewController () <UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>
@property NSTimer *refreshTimer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSArray *transactions;
@property BTCSatoshi balance;
@property (nonatomic) CNLocalAuthenication *localAuth;
@end

@implementation CNHomeViewController

- (void)dealloc {
    [_refreshTimer invalidate];
    _refreshTimer = nil;
}
            
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsSelection = NO;
    
    [self updateBalanceAndTransactions];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateBalanceAndTransactions) userInfo:nil repeats:YES];
    
    if(![CNLocalAuthenication isTouchIDAvailable]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"TouchID Required" message:@"TouchID is required to use Chain Wallet" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.refreshTimer invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get the stored address before view loads.
    self.address = [CNKeyManager getPublicKey];
    
    self.transactions = [NSArray array];
    [self.tableView reloadData];
}

#pragma mark - IB Actions

- (IBAction)tapSendButton:(id)sender {
    [self _authenticateWithTouchID];
}

- (IBAction)tapOptionsButton:(id)sender {
    // Show options action sheet.
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"More Options" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Visit Chain.com", @"View Source Code", @"Export Private Key", nil];
    [actionSheet showInView:self.view];
    actionSheet.tag = OPTIONS_ACTION_SHEET_TAG;
}

#pragma mark - QR Code Scanner

- (void)presentQRScanner {
    // TODO - Validate scan as valid address with regex
    
    // create the scanning view controller and a navigation controller in which to present it:
    CDZQRScanningViewController *scanningVC = [CDZQRScanningViewController new];
    UINavigationController *scanningNavVC = [[UINavigationController alloc] initWithRootViewController:scanningVC];
    
    // configure the scanning view controller:
    scanningVC.resultBlock = ^(NSString *result) {
        
        // On Sucessful QR scan, present the SendViewController.
        [scanningNavVC.presentingViewController dismissViewControllerAnimated:YES completion:^{
            NSLog(@"raw scan: %@", result);
            
            // We need to remove bitcoin:// or bitcoin: if present at beginning of scanned address.
            NSString* parsedAddress;
            parsedAddress = [result stringByReplacingOccurrencesOfString:@"bitcoin://" withString:@""];
            parsedAddress = [parsedAddress stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@""];
            NSLog(@"parsed scan: %@", parsedAddress);
            
            //Pass the parsed address to the view.
            self.sendToAddress = parsedAddress;
            
            [self presentSendView];
        }];
    };
    scanningVC.cancelBlock = ^() {
        [scanningNavVC dismissViewControllerAnimated:YES completion:nil];
    };
    scanningVC.errorBlock = ^(NSError *error) {
        // todo: show a UIAlertView orNSLog the error
        [scanningNavVC dismissViewControllerAnimated:YES completion:nil];
    };
    
    // present the view controller modally
    [self presentViewController:scanningNavVC animated:YES completion:nil];
}

#pragma mark - GetBalance from API

- (void)updateBalanceAndTransactions {
    // Balance
    [[Chain sharedInstance] getAddress:self.address completionHandler:^(NSDictionary *dictionary, NSError *error) {
        if (!error) {
            self.balance = [[dictionary objectForKey:@"unconfirmed_balance"] integerValue]+ [[dictionary objectForKey:@"balance"] integerValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                float btcFloat = ((float)self.balance)/BTCCoin;
                NSString *formattedBalanceString = [NSString stringWithFormat:@"฿ %f", btcFloat];
                [self setTitle:formattedBalanceString];
            });
            // Store the Address as User Default
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:@(self.balance) forKey:@"balance"];
            [defaults synchronize];
        }
    }];
    
    // Transactions
    [[Chain sharedInstance] getAddressTransactions:self.address completionHandler:^(NSDictionary *dictionary, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.transactions = [dictionary valueForKey:@"results"];
                [self.tableView reloadData];
            });
        }
    }];
}

- (void)reloadTable {
    [self.tableView reloadData];
}

#pragma mark - Send Option Action Sheet

- (void)_showSendMethodOptionSheet {
    // Show send action sheet.
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"Send to Address" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Scan QR Code", @"Paste from Clipboard", nil];
    actionSheet.tag = SEND_METHOD_ACTION_SHEET_TAG;
    [actionSheet showInView:self.view];
}

#pragma mark - TouchID

- (void)_authenticateWithTouchID {
    [self.localAuth authenticateWithTouchID:@"Authenticate to send Bitcoin" successBlock:^{
        [self _showSendMethodOptionSheet];
    }];
}

#pragma mark - Send Action Sheet

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(actionSheet.tag == SEND_METHOD_ACTION_SHEET_TAG) {
        if (buttonIndex == 0) {
            [self presentQRScanner];
        }
        if (buttonIndex == 1) {
            // Get the contents of the device clipboard.
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            self.sendToAddress = pasteboard.string;
            
            // Check Pasteboard content against a regular expression to see if it is a valid Bitcoin addres format. If it matches, load sendViewController and pass the string to it. If it does not match or clipboard is empty, show a UIAlertView notifying the user.
            if (([self.sendToAddress rangeOfString:@"^[13][a-km-zA-HJ-NP-Z0-9]{26,33}$" options:NSRegularExpressionSearch].location != NSNotFound) && self.sendToAddress.length !=0) {
                
                [self presentSendView];
            }
            else {
                NSLog(@"Not a valid Bitcoin address");
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                                    message:@"Clipboard does not contain a valid Bitcoin address"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                
                [alertView show];
            }
        }
    } if(actionSheet.tag == OPTIONS_ACTION_SHEET_TAG) {
        if (buttonIndex == 0 ) {
            NSString *strurl = @"https://chain.com";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strurl]];
        }
        if (buttonIndex == 1) {
            NSString *strurl = @"https://github.com/chain-engineering/chain-ios8-wallet-demo";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strurl]];
        }
        if (buttonIndex == 2) {
            [self.localAuth authenticateWithTouchID:@"Authenticate to export your private key." disableFallbackAuthWithReason:@"Private key export is only available with Touch ID" successBlock:^{
                UINavigationController *exportNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"exportNavController"];
                [self presentViewController:exportNavigationController animated:YES completion:nil];
            }];
        }
    }
}

- (void)presentSendView {
    NSLog(@"Valid Bitcoin address: %@", self.sendToAddress);
    UINavigationController *sendNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"sendNavController"];
    CNSendViewController *svc = (CNSendViewController *)[sendNavigationController topViewController];
    [svc setSendToAddress:self.sendToAddress];
    [self presentViewController:sendNavigationController animated:YES completion:nil];
}

- (CNLocalAuthenication *)localAuth {
    if (!_localAuth) {
        _localAuth = [[CNLocalAuthenication alloc] init];
    }
    return _localAuth;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.transactions.count;
}

// We set this to match the custom cell height from the storyboard
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"transactionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary *transaction = [self.transactions objectAtIndex:indexPath.row];
    
    // Pointers for Cell Values
    UILabel *transactionAmount = (UILabel *)[cell.contentView viewWithTag:1];
    UILabel *transactionAddress = (UILabel *)[cell.contentView viewWithTag:2];
    UILabel *transactionDate = (UILabel *)[cell.contentView viewWithTag:3];
    
    //Transaction Date Formatter
    NSString *localDateString = @"";
    NSString *blockTimeString = [transaction valueForKey:@"block_time"];
    if (blockTimeString && [blockTimeString isKindOfClass:[NSString class]]) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.timeZone = [NSTimeZone systemTimeZone];
        fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
        NSString *utcString = blockTimeString;
        NSDate *utcDate = [fmt dateFromString:utcString];
        fmt.timeStyle = NSDateFormatterNoStyle;
        fmt.dateStyle = NSDateFormatterShortStyle;
        localDateString = [fmt stringFromDate:utcDate];
    }
    
    // Show Date (if confirmed) or 'Pending' (if not confirmed)
    NSInteger transactionConfirmations = [[transaction valueForKey:@"confirmations"] integerValue];
    if (transactionConfirmations == 0)
        transactionDate.text = @"Pending";
    else
        transactionDate.text = localDateString;
    
    // Transaction Amount
    BTCSatoshi transactionValue = [self _valueForTransactionForCurrentUser:transaction];
    NSNumber *BTCValueNumber = [NSNumber numberWithFloat: (float)transactionValue/BTCCoin];

    NSNumberFormatter *twoDecimalPlacesFormatter = [[NSNumberFormatter alloc] init];
    [twoDecimalPlacesFormatter setMaximumFractionDigits:10];
    [twoDecimalPlacesFormatter setMinimumFractionDigits:2];
    [twoDecimalPlacesFormatter setMinimumIntegerDigits:1];
    
    NSString *transactionAmountString = [NSString stringWithFormat:@"฿ %@", [twoDecimalPlacesFormatter stringFromNumber:BTCValueNumber]];
    transactionAmount.text = transactionAmountString;
    
    // Change Color of Transaction Amount if is sent or received or to self
    BOOL isTransactionToSelf = [self _isTransactionToSelf:transaction];
    if (isTransactionToSelf) {
        transactionAmount.textColor = UIColorFromRGB(0x7d2b8b);
        transactionAddress.text = @"To: Yourself (Launder that money, yo!)";
    } else {
        if (transactionValue < 0) {
            // Sent
            transactionAmount.textColor = UIColorFromRGB(0xf76b6b);
            transactionAddress.text = [NSString stringWithFormat:@"To: %@", [self _outputAddressesString:transaction]];
        } else {
            // Receive
            transactionAmount.textColor = UIColorFromRGB(0x7fdf40);
            transactionAddress.text = [NSString stringWithFormat:@"From: %@", [self _inputAddressesString:transaction]];
        }
    }
    
    return cell;
}

#pragma mark - 

- (BOOL)_isTransactionToSelf:(NSDictionary *)transactionDictionary {
    // If all inputs and outputs are wallet's address.
    NSMutableArray *addresses = [NSMutableArray array];
    
    NSArray *inputs = [transactionDictionary valueForKey:@"inputs"];
    for (NSDictionary *input in inputs) {
        [addresses addObjectsFromArray:[input valueForKey:@"addresses"]];
    }
    NSArray *outputs = [transactionDictionary valueForKey:@"outputs"];
    for (NSDictionary *output in outputs) {
        [addresses addObjectsFromArray:[output valueForKey:@"addresses"]];
    }
    
    // Removes wallet address and duplicate addresses. A count of zero means wallet address was included.
    NSArray *filteredAddresses = [self _filteredAddresses:addresses];
    if ([filteredAddresses count] == 0) {
        return true;
    } else{
        return false;
    }
}

- (BTCSatoshi)_valueForInputOrOutput:(NSDictionary *)dictionary {
    BTCSatoshi amount = 0;
    NSArray *addresses = [dictionary valueForKey:@"addresses"];
    BOOL isForUserAddress = NO;
    for (NSString *address in addresses) {
        if ([address isEqualToString:self.address]) {
            isForUserAddress = YES;
        }
    }
    if (isForUserAddress) {
        NSNumber *value = [dictionary valueForKey:@"value"];
        amount = amount + [value integerValue];
    }
    return amount;
}

- (BTCSatoshi)_valueForTransactionForCurrentUser:(NSDictionary *)transactionDictionary {
    BTCSatoshi valueForWallet = 0;
    if ([self _isTransactionToSelf:transactionDictionary]) {
        // If sending to self, we assume the first output is the amount to display and other is change.
        NSArray *outputs = [transactionDictionary valueForKey:@"outputs"];
        if ([outputs count] >= 1) {
            valueForWallet = [[[outputs firstObject] valueForKey:@"value"] integerValue];
        }
    } else {
        // Iterate inputs calculating total sent in transaction.
        NSArray *inputs = [transactionDictionary valueForKey:@"inputs"];
        BTCSatoshi amountSent = 0;
        for (NSDictionary *input in inputs) {
            amountSent = amountSent + [self _valueForInputOrOutput:input];
        }
        
        // Iterate outputs calculating total received in transaction.
        NSArray *outputs = [transactionDictionary valueForKey:@"outputs"];
        BTCSatoshi amountReceived = 0;
        for (NSDictionary *output in outputs) {
            amountReceived = amountReceived + [self _valueForInputOrOutput:output];
        }
        
        valueForWallet = amountReceived - amountSent;
        // If it is sent, do not include fee.
        if (valueForWallet < 0) {
            BTCSatoshi fee = [[transactionDictionary valueForKey:@"fees"] integerValue];
            valueForWallet = valueForWallet + fee;
        }
    }
    
    return valueForWallet;
}

- (NSArray *)_filteredAddresses:(NSArray *)addresses {
    // Remove duplicates.
    NSMutableArray *filteredAddresses = [NSMutableArray arrayWithArray:[[NSSet setWithArray:addresses] allObjects]];
    
    // Remove current user.
    NSUInteger indexForCurrentUser = [filteredAddresses indexOfObject:self.address];
    if (indexForCurrentUser != NSNotFound) {
        [filteredAddresses removeObjectAtIndex:indexForCurrentUser];
    }
    
    return filteredAddresses;
}

- (NSString *)_filteredTruncatedAddress:(NSArray *)addresses {
    NSArray *filteredAddresses = [self _filteredAddresses:addresses];
    
    NSMutableString *addressString = [NSMutableString string];
    
    for (int i = 0; i < filteredAddresses.count; i++) {
        NSString *address = [filteredAddresses objectAtIndex:i];
    
        // Truncate if we have more then one.
        if (filteredAddresses.count > 1) {
            NSString *shortenedAddress = address;
            shortenedAddress = [address substringToIndex:10];
            [addressString appendFormat:@"%@…", shortenedAddress];
        } else {
            [addressString appendFormat:@"%@", address];
        }
        
        // Add a comma and space if this is not the last
        if (i != filteredAddresses.count - 1) {
            [addressString appendFormat:@", "];
        }
    }
    
    return addressString;
}

- (NSString *)_inputAddressesString:(NSDictionary *)transactionDictionary {
    NSMutableArray *addresses = [NSMutableArray array];
    
    NSArray *outputs = [transactionDictionary valueForKey:@"outputs"];
    for (NSDictionary *output in outputs) {
        [addresses addObjectsFromArray:[output valueForKey:@"addresses"]];
    }

    return [self _filteredTruncatedAddress:addresses];
}

- (NSString *)_outputAddressesString:(NSDictionary *)transactionDictionary {
    NSMutableArray *addresses = [NSMutableArray array];
    
    NSArray *outputs = [transactionDictionary valueForKey:@"outputs"];
    for (NSDictionary *output in outputs) {
        [addresses addObjectsFromArray:[output valueForKey:@"addresses"]];
    }

    return [self _filteredTruncatedAddress:addresses];
}

@end
