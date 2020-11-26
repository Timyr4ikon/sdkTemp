//
//  TLDUtil.h
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ThermaLib/ThermaLib.h>
#import <ThermaLib/TLDevice.h>
#import <ThermaLib/TLSensor.h>
#import <ThermaLib/TLRemoteSettings.h>
#import "UIView+Toast.h"

@interface TLDUtil : NSObject

// enum decoders
+(NSString *) stringFromTransport:(TLTransport) transport;
+(NSString *) stringFromConnectionStatus:(TLDeviceConnectionState) connectionState;
+(NSString *) stringFromUnit:(TLDeviceUnit) unit;
+(NSString *) stringFromGenericSensorType:(TLGenericSensorType) genType;
+(NSString *) stringFromSensorType:(TLSensorType) sensorType;
+(NSString *) stringFromDisconnectionReason:(TLDeviceDisconnectionReason) reason;

// report device disconnection via toast.
+(void) reportDisconnectionForDevice:(id<TLDevice>) device
                              inView:(UIView *)view
                          withReason:(TLDeviceDisconnectionReason) reason;

@end
