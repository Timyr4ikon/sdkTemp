//
//  TLDDeviceInfoViewController.m
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import "TLDDeviceInfoViewController.h"
#import "UIResponder+FirstResponder.h"
#import "TLDRemoteSettingsViewController.h"
#import <ThermaLib/TLDevice.h>
#import <ThermaLib/TLSensor.h>
#import <ThermaLib/TLDateStamp.h>
#import <ThermaLib/TLUtils.h>
#import "TLDUtil.h"
#import "UIView+Toast.h"


typedef NS_ENUM(NSInteger, TLDDeviceSection) {
    TLDDeviceSectionInfo,
    TLDDeviceSectionSensor1,
    TLDDeviceSectionSensor2,
    TLDDeviceSectionCount // Always last
};


typedef NS_ENUM(NSInteger, TLDDeviceInfoSection) {
    TLDDeviceInfoSectionIdentifier,
    TLDDeviceInfoSectionDeviceName,
    TLDDeviceInfoSectionConnectionStatus,
    TLDDeviceInfoSectionIsConnected,
    TLDDeviceInfoSectionDeviceReady,
    TLDDeviceInfoSectionDeviceUserReqDisconnect,
    TLDDeviceInfoSectionDeviceType,
    TLDDeviceInfoSectionTransportType,
    TLDDeviceInfoSectionModelNumber,
    TLDDeviceInfoSectionMaxSensorCount,
    TLDDeviceInfoSectionSerialNumber,
    TLDDeviceInfoSectionProtocolVersion,
    TLDDeviceInfoSectionFirmwareRevision,
    TLDDeviceInfoSectionHardwareRevision,
    TLDDeviceInfoSectionSoftwareRevision,
    TLDDeviceInfoSectionManufacturerName,
    TLDDeviceInfoSectionUnits,
    TLDDeviceInfoSectionMeasurementInterval,
    TLDDeviceInfoSectionTransmissionInterval,
    TLDDeviceInfoSectionNextTransmissionTime,
    TLDDeviceInfoSectionAutoOffInterval,
    TLDDeviceInfoSectionEmissivity,
    TLDDeviceInfoSectionSensor2Enabled,
    TLDDeviceInfoSectionBatteryLevel,
    TLDDeviceInfoSectionBatteryCondition,
    TLDDeviceInfoSectionRSSI,
    TLDDeviceInfoSectionCommand,
    TLDDeviceInfoSectionPollRate,
    TLDDeviceInfoSectionFeatures,
    TLDDeviceInfoSectionCount // Always last
};


typedef NS_ENUM(NSInteger, TLDDeviceSensorSection) {
    TLDDeviceSensorSectionName,
    TLDDeviceSensorSectionIndex,
    TLDDeviceSensorSectionReading,
    TLDDeviceSensorSectionReadingAsDisplayed,
    TLDDeviceSensorIsHighAlarmSignalled,
    TLDDeviceSensorIsLowAlarmSignalled,
    TLDDeviceSensorSectionHighAlarm,
    TLDDeviceSensorSectionLowAlarm,
    TLDDeviceSensorSectionTrimValue,
    TLDDeviceSensorSectionTrimSetDate,
    TLDDeviceSensorSectionHighRange,
    TLDDeviceSensorSectionLowRange,
    TLDDeviceSensorSectionType,
    TLDDeviceSensorSectionGenericType,
    TLDDeviceSensorSectionHighAlarmTriggered,
    TLDDeviceSensorSectionLowAlarmTriggered,
    TLDDeviceSensorSectionCount // Always last
};


@interface TLDDeviceInfoViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *remoteSettingsButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end


@implementation TLDDeviceInfoViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelNotificationReceived:) name:ThermaLibBatteryLevelNotificationName object:self.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdatedNotificationReceived:) name:ThermaLibDeviceUpdatedNotificationName object:self.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorUpdatedNotificationReceived:) name:ThermaLibSensorUpdatedNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rssiUpdatedNotificationReceived:) name:ThermaLibRSSINotificationName object:self.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceNotificationReceived:) name:ThermaLibNotificationReceivedNotificationName object:self.device];
    // Listen for device disconnections. This can be called several times while the device is initialising
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDisconnectionNotificationReceived:) name:ThermaLibDeviceDisconnectionNotificationName object:nil];

    self.title = [self.device deviceName];
    
    if( ![ThermaLib.sharedInstance isServiceConnected:self.device.transportType] ) {
        [self.view makeToast:[NSString stringWithFormat:@"Service is not connected for this device. Type %@", [TLDUtil stringFromTransport:self.device.transportType]]];
    }

    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBarButtonWasTouched:)];
    UIBarButtonItem *disconnect = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(disconnectBarButtonWasTouched:)];
    self.navigationItem.rightBarButtonItems = @[disconnect, refresh];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TLDeviceToRemoteSettingsSegueIdentifier"]) {
        
        // Give the device info view controller the device to show
        TLDRemoteSettingsViewController *viewController = segue.destinationViewController;
        viewController.device = _device;
    }
}

- (UIView *)inputAccessoryView
{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44.0f)];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneToolbarButtonWasTouched:)];
    toolbar.items = @[flexibleSpace, doneButton];

    return toolbar;
}


- (void)updateTable
{
    // Don't update the table if we're currently editing a textfield
    UIResponder *responder = [UIResponder currentFirstResponder];
    if ([responder isKindOfClass:[UITextField class]]) return;

    [self.tableView reloadData];
}


- (void)processIndexPath:(NSIndexPath *)indexPath forSensor:(id<TLSensor>)sensor withValue:(NSString *)value
{
    if (indexPath.row == TLDDeviceSensorSectionHighAlarm) {
        sensor.highAlarm = [value floatValue];
    } else if (indexPath.row == TLDDeviceSensorSectionLowAlarm) {
        sensor.lowAlarm = [value floatValue];
    } else if (indexPath.row == TLDDeviceSensorSectionTrimValue) {
        sensor.trimValue = [value floatValue];
    } else if (indexPath.row == TLDDeviceSensorSectionName) {
        sensor.name = value;
    }
}


#pragma mark -
#pragma mark Actions

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];

    CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect kbIntersectFrame = [window convertRect:CGRectIntersection(window.frame, kbFrame) toView:self.tableView];
    kbIntersectFrame = CGRectIntersection(self.tableView.bounds, kbIntersectFrame);

    // get point before contentInset change
    CGPoint pointBefore = self.tableView.contentOffset;

    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom = kbIntersectFrame.size.height;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

    // get point after contentInset change
    CGPoint pointAfter = self.tableView.contentOffset;

    // avoid jump by settings contentOffset
    self.tableView.contentOffset = pointBefore;

    // and now animate smoothly
    [self.tableView setContentOffset:pointAfter animated:YES];
}


- (void)doneToolbarButtonWasTouched:(UIBarButtonItem *)sender
{
    [[UIResponder currentFirstResponder] resignFirstResponder];
}


- (void)batteryLevelNotificationReceived:(NSNotification *)sender
{
    // We received an updated battery level from a device.
    id<TLDevice> device = sender.object;
    NSInteger batteryLevel = device.batteryLevel;
    NSLog(@"Got updated battery level (%ld) for device: %@", (long)batteryLevel, device);

    [self updateTable];
}


- (void)deviceUpdatedNotificationReceived:(NSNotification *)sender
{
    if (self.device.connectionState == TLDeviceConnectionStateUnsupported) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"This device is not supported" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    if(self.device.isReady && [self.device hasFeature:TLDeviceFeatureAsynchronousSettings]){
        [_remoteSettingsButton setTitle:@"Display Remote Settings" forState:UIControlStateNormal];
        _remoteSettingsButton.enabled = true;
    } else {
        [_remoteSettingsButton setTitle:@"No Remote Settings for Device" forState:UIControlStateNormal];
        _remoteSettingsButton.enabled = false;
    }
    
    //NSLog(@"%@", [TLUtils getTimestampFromNotification:sender]);
    
    [self updateTable];
}


- (void)sensorUpdatedNotificationReceived:(NSNotification *)sender
{
    [self updateTable];
}


- (void)rssiUpdatedNotificationReceived:(NSNotification *)sender
{
    [self updateTable];
}


- (void)refreshBarButtonWasTouched:(UIBarButtonItem *)sender
{
    [self.device sendCommand:TLDeviceCommandTypeMeasure];
    [self.device refresh];
}


- (void)disconnectBarButtonWasTouched:(UIBarButtonItem *)sender
{
    [[ThermaLib sharedInstance] disconectFromDevice:self.device];
}


- (void)deviceDisconnectionNotificationReceived:(NSNotification *)sender
{
    // The relevant device can be obtained from the notification
    id<TLDevice> device = (id<TLDevice>) sender.object;
    TLDeviceDisconnectionReason reason = (TLDeviceDisconnectionReason) [[sender.userInfo valueForKey:ThermaLibDeviceDisconnectionNotificationReasonKey] integerValue];
    
    [TLDUtil reportDisconnectionForDevice:device
                                inView:self.view
                            withReason:reason];
}

- (void)deviceNotificationReceived:(NSNotification *)sender
{
    TLDeviceNotificationType notification = [sender.userInfo[ThermaLibNotificationReceivedNotificationTypeKey] integerValue];

    NSString *notificationName;
    switch (notification) {
        case TLDeviceNotificationTypeButtonPressed:
            notificationName = @"Button Pressed";
            break;

        case TLDeviceNotificationTypeShutdown:
            notificationName = @"Shutdown";
            break;

        case TLDeviceNotificationTypeInvalidSetting:
            notificationName = @"Invalid Setting";
            break;

        case TLDeviceNotificationTypeInvalidCommand:
            notificationName = @"Invalid Command";
            break;

        case TLDeviceNotificationTypeCommunicationError:
            notificationName = @"Communication Error";
            break;
            
        case TLDeviceNotificationTypeCheckpoint:
            notificationName = @"Checkpoint";
            break;
            
        case TLDeviceNotificationTypeRefreshRequest:
            notificationName = @"Request to Refresh";
            break;
            
        case TLDeviceNotificationTypeNone:
            notificationName = @"NotificationType:None";
            break;

        default:
            notificationName = [NSString stringWithFormat:@"Unknown notification (%ld)", (long)notification];
            break;
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Notification" message:notificationName preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)textFieldDidEndEditing:(UITextField *)sender
{
    CGRect rect = [self.tableView convertRect:sender.bounds fromView:sender];
    NSIndexPath *indexPath = [self.tableView indexPathsForRowsInRect:rect].firstObject;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UITextField *textField = [cell viewWithTag:2];

    switch (indexPath.section) {
        case TLDDeviceSectionInfo:
            if (indexPath.row == TLDDeviceInfoSectionMeasurementInterval) {
                self.device.measurementInterval = textField.text.integerValue;
            } else if (indexPath.row == TLDDeviceInfoSectionTransmissionInterval) {
                self.device.transmissionInterval = textField.text.integerValue;
            } else if (indexPath.row == TLDDeviceInfoSectionAutoOffInterval) {
                self.device.autoOffInterval = textField.text.integerValue;
            } else if (indexPath.row == TLDDeviceInfoSectionPollRate){
                [self.device setPollInterval:textField.text.integerValue];
            }
            else if (indexPath.row == TLDDeviceInfoSectionEmissivity) {
                self.device.emissivity = textField.text.floatValue;
            }
            break;

        case TLDDeviceSectionSensor1:
            [self processIndexPath:indexPath forSensor:[self.device sensorAtIndex:1] withValue:sender.text];
            break;

        case TLDDeviceSectionSensor2:
            [self processIndexPath:indexPath forSensor:[self.device sensorAtIndex:2] withValue:sender.text];
            break;

        default:
            break;
    }
}


- (void)updateRSSIButtonWasTouched:(UIButton *)sender
{
    [self.device updateRssi];
}


- (void)disableButtonWasTouched:(UIButton *)sender
{
    CGRect rect = [self.tableView convertRect:sender.bounds fromView:sender];
    NSIndexPath *indexPath = [self.tableView indexPathsForRowsInRect:rect].firstObject;

    id<TLSensor> sensor;
    if (indexPath.section == TLDDeviceSectionSensor1) {
        sensor = [self.device sensorAtIndex:1];
    } else {
        sensor = [self.device sensorAtIndex:2];
    }

    if (indexPath.row == TLDDeviceSensorSectionHighAlarm) {
        sensor.highAlarmEnabled = NO;
    } else {
        sensor.lowAlarmEnabled = NO;
    }
}


- (void)sensor2EnabledSwitchValueChanged:(UISwitch *)sender
{
    [self.device sensorAtIndex:2].enabled = sender.on;
}


- (void)deviceUnitValueChanged:(UISegmentedControl *)sender
{
    
    if(sender.selectedSegmentIndex == 0){
        [self.device setDisplayUnitForGenericSensorType:TLGenericSensorTypeTemperature unit:TLDeviceUnitCelsius];
    } else {
        [self.device setDisplayUnitForGenericSensorType:TLGenericSensorTypeTemperature unit:TLDeviceUnitFahrenheit];
    }
    
    
}


- (void)chooseCommandButtonWasTouched:(UIButton *)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Command" message:@"Please choose the command to send" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Send Readings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.device sendCommand:TLDeviceCommandTypeMeasure];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Identify" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.device sendCommand:TLDeviceCommandTypeIdentify];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Restore Defaults" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.device sendCommand:TLDeviceCommandTypeFactorySettings];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Factory Reset" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.device sendCommand:TLDeviceCommandTypeFactoryReset];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];

    UIPopoverPresentationController *presentationController = alertController.popoverPresentationController;
    presentationController.sourceView = sender;
    presentationController.sourceRect = sender.bounds;
}


#pragma mark -
#pragma mark TableView

- (UITableViewCell *)cellForInfoSectionAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    if (indexPath.row == TLDDeviceInfoSectionRSSI || indexPath.row == TLDDeviceInfoSectionCommand) {
        identifier = @"TLDDeviceInfoButtonCellIdentifier";
    } else if (indexPath.row == TLDDeviceInfoSectionSensor2Enabled) {
        identifier = @"TLDDeviceInfoSwitchCellIdentifier";
    } else if (indexPath.row == TLDDeviceInfoSectionUnits) {
        identifier = @"TLDDeviceInfoSegmentedCellIdentifier";
    } else {
        identifier = @"TLDDeviceInfoCellIdentifier";
    }

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UILabel *label = [cell viewWithTag:1];
    UITextField *textField = [cell viewWithTag:2];
    [textField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];

    switch (indexPath.row) {
        case TLDDeviceInfoSectionIdentifier:
            label.text = @"Identifier";
            textField.text = self.device.deviceIdentifier;
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionDeviceName:
            label.text = @"Device Name";
            textField.text = self.device.deviceName;
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionDeviceReady: {
            label.text = @"Device Ready";
            textField.text = [NSString stringWithFormat:@"%s", self.device.ready ? "true" : "false"];
            textField.enabled = NO;
            break;
        }
            
        case TLDDeviceInfoSectionDeviceUserReqDisconnect: {
            label.text = @"User Req. Disconnect";
            textField.text = [NSString stringWithFormat:@"%s", self.device.userRequestedDisconnect ? "true" : "false"];
            textField.enabled = NO;
            break;
        }

        case TLDDeviceInfoSectionIsConnected: {
            label.text = @"Is Connected";
            textField.text = [NSString stringWithFormat:@"%s", self.device.isConnected ? "true" : "false"];
            textField.enabled = NO;
            break;
        }
            
        case TLDDeviceInfoSectionDeviceType:
            label.text = @"Device Type";
            textField.text = self.device.deviceTypeName;
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionTransportType:
            label.text = @"Transport Type";
            textField.text = [TLDUtil stringFromTransport:self.device.transportType];
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionModelNumber:
            label.text = @"Model Number";
            textField.text = self.device.modelNumber;
            textField.enabled = NO;
            break;

        case TLDDeviceInfoSectionSerialNumber:
            label.text = @"Serial Number";
            textField.text = self.device.serialNumber;
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionProtocolVersion:
            label.text = @"Protocol Version";
            textField.text = self.device.protocolVersion;
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionFirmwareRevision:
            label.text = @"Firmware Revision";
            textField.text = self.device.firmwareRevision;
            textField.enabled = NO;
            break;

        case TLDDeviceInfoSectionHardwareRevision:
            label.text = @"Hardware Version";
            textField.text = self.device.hardwareVersion;
            textField.enabled = NO;
            break;

        case TLDDeviceInfoSectionSoftwareRevision:
            label.text = @"Software Revision";
            textField.text = self.device.softwareRevision;
            textField.enabled = NO;
            break;

        case TLDDeviceInfoSectionManufacturerName:
            label.text = @"Manufacturer Name";
            textField.text = self.device.manufacturerName;
            textField.enabled = NO;
            break;

        case TLDDeviceInfoSectionUnits: {
            label.text = @"Temperature Units";

            UISegmentedControl *segmentedControl = [cell viewWithTag:5];
            segmentedControl.selectedSegmentIndex = [self.device displayUnitForGenericSensorType:TLGenericSensorTypeTemperature];
            [segmentedControl removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
            [segmentedControl addTarget:self action:@selector(deviceUnitValueChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        }

        case TLDDeviceInfoSectionMeasurementInterval:
            label.text = @"Measurement Interval";
            textField.text = [NSString stringWithFormat:@"%li", (long)self.device.measurementInterval];
            textField.enabled = YES;
            break;
            
        case TLDDeviceInfoSectionTransmissionInterval:
            label.text = @"Transmission Interval";
            textField.text = [NSString stringWithFormat:@"%li", (long)self.device.transmissionInterval];
            textField.enabled = YES;
            break;
            
        case TLDDeviceInfoSectionNextTransmissionTime:
            label.text = @"Next Transmission Time";
            textField.text = [NSString stringWithFormat:@"%@", self.device.nextTransmissionTime];
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionAutoOffInterval:
            label.text = @"Auto Off Interval";
            textField.text = [NSString stringWithFormat:@"%ld", (long)self.device.autoOffInterval];
            textField.enabled = YES;
            break;
            
        case TLDDeviceInfoSectionMaxSensorCount:
            label.text = @"Max Sensor Count";
            textField.text = [NSString stringWithFormat:@"%ld", (long)self.device.maxSensorCount];
            textField.enabled = NO;
            break;
            
        case TLDDeviceInfoSectionEmissivity:
            label.text = @"Emissivity";
            if( [self.device hasFeature:TLDeviceFeatureEmissivity] ) {
                textField.text = [NSString stringWithFormat:@"%.2f", self.device.emissivity];
                textField.enabled = YES;
            }
            else {
                textField.text = @"N/A";
                textField.enabled = NO;
            }
            
            break;
            
        case TLDDeviceInfoSectionSensor2Enabled: {
            label.text = @"Sensor 2 Enabled";

            UISwitch *enabledSwitch = [cell viewWithTag:4];
            enabledSwitch.on = [self.device isSensorEnabledAtIndex:2];
            enabledSwitch.enabled = [self.device maxSensorCount] == 2;
            [enabledSwitch removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
            [enabledSwitch addTarget:self action:@selector(sensor2EnabledSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        }

        case TLDDeviceInfoSectionBatteryLevel: {
            label.text = @"Battery Level";
            textField.text = [NSString stringWithFormat:@"%li", (long)self.device.batteryLevel];
            textField.enabled = NO;
            break;
        }
            
        case TLDDeviceInfoSectionBatteryCondition: {
            label.text = @"Battery Warning Level";
            
            NSString *level = @"Unknown";
            
            switch(self.device.batteryWarningLevel) {
                case TLBatteryWarningLevelHalf:{ level = @"Half"; break;}
                case TLBatteryWarningLevelLow:{ level = @"Low"; break;}
                case TLBatteryWarningLevelCritical:{ level = @"Critical"; break;}
                case TLBatteryWarningLevelFull:{ level = @"Full"; break;}
            }
            
            textField.text = level;
            textField.enabled = NO;
            break;
        }
        case TLDDeviceInfoSectionRSSI: {
            label.text = @"RSSI";
            textField.text = [NSString stringWithFormat:@"%@", self.device.rssi];
            textField.enabled = NO;

            UIButton *button = [cell viewWithTag:3];
            [button setTitle:@"Update" forState:UIControlStateNormal];
            [button removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(updateRSSIButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }

        case TLDDeviceInfoSectionCommand: {
            label.text = @"Command";
            textField.text = @"";
            textField.enabled = NO;

            UIButton *button = [cell viewWithTag:3];
            [button setTitle:@"Choose command" forState:UIControlStateNormal];
            [button removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(chooseCommandButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
            
        case TLDDeviceInfoSectionConnectionStatus: {
            label.text = @"Connection Status";
            textField.text = [TLDUtil stringFromConnectionStatus:self.device.connectionState ];
            textField.enabled = NO;
            
            break;
        }
            
        case TLDDeviceInfoSectionPollRate: {
         
            label.text = @"Poll Rate";
            
            if((self.device.features & TLDeviceFeaturePolledDevice) != 0){
                textField.text = [NSString stringWithFormat:@"%li", (long)self.device.pollInterval];
                textField.enabled = YES;
            } else {
                textField.text = @"Not a polled Device";
                textField.enabled = NO;
            }
            
            break;
            
        }
            
        case TLDDeviceInfoSectionFeatures : {
            
            label.text = @"Features";
            textField.text = [self makeFeatureString];
            textField.enabled = NO;
            
            break;
            
        }
            
        default:
            break;
    }


    return cell;
}

-(NSString *)makeFeatureString{
    
    NSMutableString *ret = [NSMutableString new];
    
    [self addFeatureComponentToString:TLDeviceFeatureAlarm featureString:@"Alarm" mutableString:ret];
    [self addFeatureComponentToString:TLDeviceFeatureDisplay featureString:@"Display" mutableString:ret];
    [self addFeatureComponentToString:TLDeviceFeaturePolledDevice featureString:@"Polled" mutableString:ret];
    [self addFeatureComponentToString:TLDeviceFeatureAsynchronousSettings featureString:@"Asynch. Settings" mutableString:ret];
    [self addFeatureComponentToString:TLDeviceFeatureAutoOff featureString:@"Auto Off" mutableString:ret];
    [self addFeatureComponentToString:TLDeviceFeatureEmissivity featureString:@"Emissivity" mutableString:ret];
    
    return [NSString stringWithString:ret];
    
}

-(void)addFeatureComponentToString:(int)feature featureString:(NSString *)featureString mutableString:(NSMutableString *)mutableString {
    
    if((self.device.features & feature) != 0 ) {
        if(mutableString.length != 0){
            [mutableString appendString:@","];
        }
        [mutableString appendString:featureString];
    }
    
}

- (UITableViewCell *)cellForSensorSectionAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row == TLDDeviceSensorSectionHighAlarm || indexPath.row == TLDDeviceSensorSectionLowAlarm) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"TLDDeviceInfoButtonCellIdentifier" forIndexPath:indexPath];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"TLDDeviceInfoCellIdentifier" forIndexPath:indexPath];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UILabel *label = [cell viewWithTag:1];
    UITextField *textField = [cell viewWithTag:2];
    [textField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];

    NSInteger index = indexPath.section == 1 ? 1 : 2;
    id<TLSensor> sensor = [self.device sensorAtIndex:index];
    BOOL sensorIsEnabled = [self.device isSensorEnabledAtIndex:index];
    
    switch (indexPath.row) {
        case TLDDeviceSensorSectionName:
            label.text = @"Name";
            textField.text = sensor.name;
            textField.enabled = sensorIsEnabled;
            break;
            
        case TLDDeviceSensorSectionIndex:
            label.text = @"Index";
            textField.text = [NSString stringWithFormat:@"%lu", (unsigned long)sensor.index];
            textField.enabled = sensorIsEnabled;
            textField.enabled = NO;
            break;
            
        case TLDDeviceSensorSectionReadingAsDisplayed: {
            label.text = @"Displayed Reading";
            
            NSString *readingAsDisplayed = sensor.readingAsDisplayed;
            NSString *unit = [TLDUtil stringFromUnit:[self.device displayUnitForGenericSensorType:sensor.genericType]];
            if( readingAsDisplayed == nil || readingAsDisplayed.length == 0 ) {
                textField.text = @"None displayed";
            }
            else {
                textField.text = [NSString stringWithFormat:@"%@ %@", readingAsDisplayed, unit];
            }
            textField.enabled = NO;
            break;
        }
        case TLDDeviceSensorIsHighAlarmSignalled: {
            label.text = @"High Alarm On Device";
            
            NSString *ans = @"n/a";
            if( self.device != nil ) {
                int features = self.device.features;
                if( features & TLDeviceFeatureAlarm ) {
                    BOOL signalled = sensor.highAlarmSignalled;
                    ans = signalled ? @"yes" : @"no";
                }
            }
            textField.text = ans;
            textField.enabled = NO;
            break;
        }
            
        case TLDDeviceSensorIsLowAlarmSignalled: {
            label.text = @"Low Alarm On Device";
            
            NSString *ans = @"n/a";
            if( self.device != nil && [self.device hasFeature:TLDeviceFeatureAlarm] ) {
                ans = sensor.lowAlarmSignalled ? @"yes" : @"no";
            }
            textField.text = ans;
            textField.enabled = NO;
            break;
        }
            
        case TLDDeviceSensorSectionReading: {
            label.text = @"Reading";
            
            float reading = sensor.reading;
            NSString *unitString = [TLDUtil stringFromUnit:sensor.readingUnit];
            NSString *text = nil;
            if (sensorIsEnabled) {
                if ([sensor isFault]) {
                    text = @"FAULT";
                } else {
                    text = [NSString stringWithFormat:@"%.5f %@", reading, unitString];
                }
            } else {
                text = @"Sensor Disabled";
            }
            textField.text = text;
            textField.enabled = NO;
            break;
        }
            
        case TLDDeviceSensorSectionHighAlarm: {
            label.text = @"High Alarm";
            textField.text = sensorIsEnabled && sensor.highAlarmEnabled ? [NSString stringWithFormat:@"%.1f", sensor.highAlarm] : @"";
            textField.enabled = sensorIsEnabled;

            UIButton *button = [cell viewWithTag:3];
            [button setTitle:@"Disable" forState:UIControlStateNormal];
            [button removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(disableButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }

        case TLDDeviceSensorSectionLowAlarm: {
            label.text = @"Low Alarm";
            textField.text = sensorIsEnabled && sensor.lowAlarmEnabled ? [NSString stringWithFormat:@"%.1f", sensor.lowAlarm] : @"";
            textField.enabled = sensorIsEnabled;

            UIButton *button = [cell viewWithTag:3];
            [button setTitle:@"Disable" forState:UIControlStateNormal];
            [button removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(disableButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }

        case TLDDeviceSensorSectionTrimValue:
            label.text = @"Trim Value";
            textField.text = sensorIsEnabled ? [NSString stringWithFormat:@"%.1f", sensor.trimValue] : @"";
            textField.enabled = sensorIsEnabled;
            break;

        case TLDDeviceSensorSectionTrimSetDate:
            label.text = @"Trim Set Date";
            textField.text = sensorIsEnabled ? [NSString stringWithFormat:@"%ld/%ld/%ld", (long)sensor.trimSetDate.day, (long)sensor.trimSetDate.month, (long)sensor.trimSetDate.year] : @"";
            textField.enabled = NO;
            break;
            
        case TLDDeviceSensorSectionHighRange:
            label.text = @"Sensor High Range";
            textField.text = sensorIsEnabled ? [NSString stringWithFormat:@"%.1f", [[sensor range] high]] : @"";
            textField.enabled = NO;
            break;
            
        case TLDDeviceSensorSectionLowRange:
            label.text = @"Sensor Low Range";
            textField.text = sensorIsEnabled ? [NSString stringWithFormat:@"%.1f", [[sensor range] low]] : @"";
            textField.enabled = NO;
            break;
            
        case TLDDeviceSensorSectionType:
            label.text = @"Type";
            textField.text = [TLDUtil stringFromSensorType:sensor.type];
            textField.enabled = NO;
            break;
        
        case TLDDeviceSensorSectionGenericType:
            label.text = @"Generic Type";
            textField.text = [TLDUtil stringFromGenericSensorType:sensor.genericType];
            textField.enabled = NO;
            break;

        case TLDDeviceSensorSectionHighAlarmTriggered:
            label.text = @"Sensor High Alarm Triggered";
            textField.text = sensorIsEnabled ? [NSString stringWithFormat:@"%s", [sensor highAlarmBreached] ? "true" : "false"] : @"";
            textField.enabled = NO;
            break;
            
        case TLDDeviceSensorSectionLowAlarmTriggered:
            label.text = @"Sensor Low Alarm Triggered";
            textField.text = sensorIsEnabled ? [NSString stringWithFormat:@"%s", [sensor lowAlarmBreached] ? "true" : "false"] : @"";
            textField.enabled = NO;
            break;


        default:
            break;
    }
    
    
    return cell;
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.device maxSensorCount] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case TLDDeviceSectionInfo:
            return TLDDeviceInfoSectionCount;

        case TLDDeviceSectionSensor1:
            return TLDDeviceSensorSectionCount;

        case TLDDeviceSectionSensor2:
            return TLDDeviceSensorSectionCount;

        default:
            return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case TLDDeviceSectionInfo:
            return [self cellForInfoSectionAtIndexPath:indexPath];

        case TLDDeviceSectionSensor1:
            return [self cellForSensorSectionAtIndexPath:indexPath];

        case TLDDeviceSectionSensor2:
            return [self cellForSensorSectionAtIndexPath:indexPath];

        default:
            return nil;
    }
}


#pragma mark -
#pragma mark UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case TLDDeviceSectionInfo:
            return @"Device Info";

        case TLDDeviceSectionSensor1:
            return @"Sensor 1";

        case TLDDeviceSectionSensor2:
            return [NSString stringWithFormat:@"Sensor 2%@", [self.device isSensorEnabledAtIndex:2] ? @"" : @" (DISABLED)"];

        default:
            return nil;
    }
}



@end
