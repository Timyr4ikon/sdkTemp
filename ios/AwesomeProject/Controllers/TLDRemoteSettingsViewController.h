//
//  TLDRemoteSettingsViewController.h
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TLDevice;
@protocol TLRemoteSettings;

@interface TLDRemoteSettingsViewController : UIViewController
@property (strong, nonatomic) id<TLDevice> device;
@property (strong, nonatomic) id<TLRemoteSettings> remoteSettings;
@end
