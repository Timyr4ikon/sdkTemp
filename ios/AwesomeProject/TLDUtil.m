//
//  TLDUtil.m
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import "TLDUtil.h"
#import "UIView+Toast.h"

@implementation TLDUtil

+ (NSString *) stringFromTransport:(TLTransport) transport {
    NSString *ret = @"Unknown";
    switch(transport) {
        case TLTransportSimulated:
            ret = @"Simulated";
            break;
        case TLTransportBluetoothLE:
            ret = @"Bluetooth LE";
            break;
        case TLTransportCloudService:
            ret = @"Cloud";
            break;
            
    }
    return ret;
}

+ (NSString *) stringFromConnectionStatus:(TLDeviceConnectionState) connectionState {
    NSString *ret = @"Unknown";
    switch(connectionState) {
        case TLDeviceConnectionStateUnknown:
            ret = @"Unknown";
            break;
        case TLDeviceConnectionStateAvailable:
            ret = @"Available";
            break;
        case TLDeviceConnectionStateConnected:
            ret = @"Connected";
            break;
        case TLDeviceConnectionStateConnecting:
            ret = @"Connecting";
            break;
        case TLDeviceConnectionStateUnavailable:
            ret = @"Unavailable";
            break;
        case TLDeviceConnectionStateUnsupported:
            ret = @"Unsupported";
            break;
        case TLDeviceConnectionStateDisconnected:
            ret = @"Disconnected";
            break;
        case TLDeviceConnectionStateUnregistered:
            ret = @"Unregistered";
            break;
        case TLDeviceConnectionStateDisconnecting:
            ret = @"Disconnecting";
            break;
            
    }
    return ret;
}

+ (NSString *) stringFromUnit:(TLDeviceUnit) unit {
    
    NSString *ret = @"Unknown";
    
    switch (unit){
            
        case TLDeviceUnitFahrenheit :
            ret = @"°F";
            break;
        case TLDeviceUnitCelsius :
            ret = @"°C";
            break;
        case TLDeviceUnitPH :
            ret = @"pH";
            break;
        case TLDeviceUnitRelativeHumidity :
            ret = @"%rh";
            break;
        default:
            break;
    }
    
    return ret;
    
}

+ (NSString *) stringFromGenericSensorType:(TLGenericSensorType) genericType {
    NSString *ret = @"Unknown";
    
    switch(genericType) {
        case TLGenericSensorTypeHumidity :
            ret = @"Humidity";
            break;
        case TLGenericSensorTypeAcidity :
            ret = @"Acidity";
            break;
        case TLGenericSensorTypeTemperature :
            ret = @"Temperature";
            break;
        case TLGenericSensorTypeUnknown :
        default:
            ret = @"Unknown";
            break;
    }
    
    return ret;
}

+(NSString *) stringFromSensorType:(TLSensorType) sensorType {
    NSString *ret = @"Unknown";
    switch(sensorType) {
        case TLSensorTypeInternalThermistor :
            ret = @"Internal Thermistor";
            break;
        case TLSensorTypeExternalThermistor :
            ret = @"External Thermistor";
            break;
        case TLSensorTypeKThermocouple :
            ret = @"K Thermocouple Detachable";
            break;
        case TLSensorTypeTThermocouple :
            ret = @"T Thermocouple";
            break;
        case TLSensorTypePT1000 :
            ret = @"PT1000";
            break;
        case TLSensorTypeInfraredType1 :
            ret = @"Infrared (Type 1)";
            break;
        case TLSensorTypePHSensor :
            ret = @"pH Sensor";
            break;
        case TLSensorTypeHumidityTemperature :
            ret = @"Humidity Temperature";
            break;
        case TLSensorTypeHumidity :
            ret = @"Humidity";
            break;
        case TLSensorTypeMoistureSensor :
            ret = @"Moisture Sensor";
            break;
        case TLSensorTypeKThermocoupleFixed :
            ret = @"K Thermocouple Fixed";
            break;
        case TLSensorTypeExternalThermistorConnector :
            ret = @"External Thermistor Connector";
            break;
        case TLSensorTypeUnknown :
        default:
            ret = @"Unknown";
            break;

    }
    return ret;
}

+(NSString *) stringFromDisconnectionReason:(TLDeviceDisconnectionReason) reason {
    NSString *ret = @"reason unknown";
    switch (reason) {
        case TLDeviceDisconnectionReasonUser:
            ret = @"user disconnected";
            break;
        case TLDeviceDisconnectionReasonNoBluetooth:
            ret = @"no Bluetooth";
            break;
        case TLDeviceDisconnectionReasonNoInternet:
            ret = @"no Internet";
            break;
        case TLDeviceDisconnectionReasonUnexpected:
            ret = @"unexpected";
            break;
        case TLDeviceDisconnectionReasonDeviceShutDown:
            ret = @"device shutdown";
            break;
        case TLDeviceDisconnectionReasonAuthenticationFailure:
            ret = @"authentication failure";
            break;
        default:
            break;
    }
    return ret;
}

+(void) reportDisconnectionForDevice:(id<TLDevice>) device
                              inView:(UIView *)view
                          withReason:(TLDeviceDisconnectionReason) reason
{
    [view makeToast:[NSString stringWithFormat:@"Device %@ was disconnected: %@",
                     device.deviceName,
                     [TLDUtil stringFromDisconnectionReason:reason]]];
}

@end
