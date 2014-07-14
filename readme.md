<img src="https://s3.amazonaws.com/chain-assets/chain-wallet-banner.png" style="width:100%"/>

# Chain Wallet

A Touch ID iOS Bitcoin wallet built on the [Chain API](https://chain.com).

## Summary
This open source Bitcoin wallet uses the iOS 8 Touch ID API to securely store your private key in your Apple Keychain, which can only be accessed with your fingerprint.

Fork it and build something great! 

## Installation
Chain Wallet uses the [Chain API iOS SDK](https://github.com/chain-engineering/chain-ios) and [BitcoinCore](https://github.com/oleganza/CoreBitcoin), both included as CocoaPods.

To install, first run:
```
pod install
```

Then open the workspace file in XCode:
```
Chain Wallet.xcworkspace
```

Finally, get a Chain API token at [Chain.com](https://chain.com) and define the following in CNAppDelegate.m:
```
[Chain sharedInstanceWithToken:@"{YOUR-API-TOKEN}"];  
```

## Requirements
Chain Wallet requires Touch ID (currently available only on iPhone 5s) and iOS 8.
