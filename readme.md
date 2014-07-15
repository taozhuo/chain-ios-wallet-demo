<img src="https://s3.amazonaws.com/chain-assets/chain-wallet-banner.png" style="width:100%"/>

# Chain iOS Wallet Demo

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
Chain Wallet requires iOS 8 and Touch ID (currently available on the iPhone 5s).

## About Chain
[Chain](https://chain.com) is a powerful API that makes it easy to build Bitcoin applications - without managing complicated block chain infrastructure. We believe that virtual currency is only the first of thousands of applications that will be built on the block chain, and we are excited to provide the platform that allows you to focus on creating great products.

We want to understand your needs and build along side you. So don’t hesitate to request features, make suggestions, or just [say hello](mailto:hello@chain.com).
