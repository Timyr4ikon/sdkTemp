//
//  TLDDeviceInfoViewController.h
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TLDUtil.h"

@protocol TLDevice;


@interface TLDDeviceInfoViewController : UIViewController
@property (strong, nonatomic) id<TLDevice> device;
@end
