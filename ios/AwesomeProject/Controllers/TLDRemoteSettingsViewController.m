//
//  ViewController.m
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLDRemoteSettingsViewController.h"
#import "UIResponder+FirstResponder.h"
#import "TLDRemoteSettingsViewController.h"
#import <ThermaLib/TLDevice.h>
#import <ThermaLib/TLSensor.h>
#import <ThermaLib/TLDateStamp.h>
#import <ThermaLib/TLUtils.h>
#import <ThermaLib/TLRemoteSettings.h>
#import "TLDUtil.h"


typedef NS_ENUM(NSInteger, TLDDeviceSection) {
    TLDDeviceSectionInfo,
    TLDDeviceSectionSensor1,
    TLDDeviceSectionSensor2,
    TLDDeviceSectionCount // Always last
};


typedef NS_ENUM(NSInteger, TLDDeviceInfoSection) {
    TLDDeviceInfoSectionMesurmentInterval,
    TLDDeviceInfoSectionTranmissionInterval,
    TLDDeviceInfoSectionStartDate,
    TLDDeviceInfoSectionSamplesInMemory,
    TLDDeviceInfoSectionAuditEnabled,
    TLDDeviceInfoSectionDisplayUnit,
    TLDDeviceInfoSectionSignalStrength,
    TLDDeviceInfoSectionCount // Always last
};


typedef NS_ENUM(NSInteger, TLDDeviceSensorSection) {
    TLDDeviceSensorSectionAlarmDelay,
    TLDDeviceSensorSectionHighAlarm,
    TLDDeviceSensorSectionLowAlarm,
    TLDDeviceSensorSectionName,
    TLDDeviceSensorSectionTrimDate,
    TLDDeviceSensorSectionTrimValue,
    TLDDeviceSensorSectionEnabled,
    TLDDeviceSensorSectionHighAlarmEnabled,
    TLDDeviceSensorSectionLowAlarmEnabled,
    TLDDeviceSensorSectionCount // Always last
};


@interface TLDRemoteSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end


@implementation TLDRemoteSettingsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteSettingsChanged:) name:ThermaLibRemoteSettingsChangedNotificationName object:self.device];
    self.title = @"Remote Settings";
    self.remoteSettings = self.device.remoteSettings;
    
}

- (UIView *)inputAccessoryView
{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44.0f)];
    return toolbar;
}


- (void)updateTable
{
    // Don't update the table if we're currently editing a textfield
    UIResponder *responder = [UIResponder currentFirstResponder];
    if ([responder isKindOfClass:[UITextField class]]) return;
    
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark Actions
- (void)remoteSettingsChanged:(NSNotification *)sender
{
    self.remoteSettings = self.device.remoteSettings;
    [self updateTable];
}


#pragma mark -
#pragma mark TableView

- (UITableViewCell *)cellForInfoSectionAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"TLDDeviceInfoCellIdentifier";

    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *label = [cell viewWithTag:1];
    UITextField *textField = [cell viewWithTag:2];
    [textField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    textField.enabled = NO;
    
    switch (indexPath.row) {
        case TLDDeviceInfoSectionMesurmentInterval: {
            label.text = @"Measurement Interval";
            textField.text = [NSString stringWithFormat:@"%d", self.remoteSettings.measurementInterval];
            break;
        }
            
        case TLDDeviceInfoSectionTranmissionInterval:{
            label.text = @"Transmission Interval";
            textField.text = [NSString stringWithFormat:@"%d", self.remoteSettings.transmissionInterval];
            break;
        }
            
        case TLDDeviceInfoSectionStartDate:{
            label.text = @"Start Date";
            textField.text = [NSString stringWithFormat:@"%@", self.remoteSettings.startDate];
            break;
        }
            
        case TLDDeviceInfoSectionSamplesInMemory:{
            label.text = @"Samples in Memory";
            textField.text = [NSString stringWithFormat:@"%d", self.remoteSettings.samplesInMemory];
            break;
        }
            
        case TLDDeviceInfoSectionAuditEnabled:{
            label.text = @"Audit Enabled";
            textField.text = self.remoteSettings.auditEnabled ? @"true" : @"false";
            break;
        }
            
        case TLDDeviceInfoSectionDisplayUnit:{
            label.text = @"Display Unit";
            
            NSString *value = @"Unknown";
            
            if(self.remoteSettings.temperatureDisplayUnit == TLDeviceUnitRelativeHumidity){
                value = @"Relative Humidity";
            } else if(self.remoteSettings.temperatureDisplayUnit == TLDeviceUnitFahrenheit){
                value = @"Relative Fahrenheit";
            } else if(self.remoteSettings.temperatureDisplayUnit == TLDeviceUnitPH){
                value = @"PH";
            } else if(self.remoteSettings.temperatureDisplayUnit == TLDeviceUnitCelsius){
                value = @"Celsius";
            }
            
            textField.text = value;
            
            break;
        }
            
        case TLDDeviceInfoSectionSignalStrength:{
            label.text = @"Signal Strength";
            textField.text = [NSString stringWithFormat:@"%d", self.remoteSettings.signalStrength];
            break;
        }
        default:
            break;
    }
    
    
    return cell;
}

- (UITableViewCell *)cellForSensorSectionAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TLDDeviceInfoCellIdentifier" forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *label = [cell viewWithTag:1];
    UITextField *textField = [cell viewWithTag:2];
    [textField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    
    int index = indexPath.section == 1 ? 1 : 2;
    
    switch (indexPath.row) {
            
        case TLDDeviceSensorSectionAlarmDelay : {
            label.text = @"Alarm Delay";
            textField.text = [NSString stringWithFormat:@"%d", [self.remoteSettings alarmDelayForSensor:index]];
            break;
        }
            
        case TLDDeviceSensorSectionHighAlarm : {
            label.text = @"High Alarm";
            textField.text = [NSString stringWithFormat:@"%f", [self.remoteSettings highLimitForSensor:index]];
            break;
        }
            
        case TLDDeviceSensorSectionLowAlarm : {
            label.text = @"Low Alarm";
            textField.text = [NSString stringWithFormat:@"%f", [self.remoteSettings lowLimitForSensor:index]];
            break;
        }
            
        case TLDDeviceSensorSectionName : {
            label.text = @"Sensor Name";
            textField.text = [NSString stringWithFormat:@"%@", [self.remoteSettings nameOfSensor:index]];
            break;
        }
            
        case TLDDeviceSensorSectionTrimDate : {
            label.text = @"Trim Date";
            textField.text = [NSString stringWithFormat:@"%@", [self.remoteSettings trimDateForSensor:index]];
            break;
        }
            
        case TLDDeviceSensorSectionTrimValue: {
            label.text = @"Trim Value";
            textField.text = [NSString stringWithFormat:@"%f", [self.remoteSettings trimValueForSensor:index]];
            break;
        }
            
        case TLDDeviceSensorSectionEnabled : {
            label.text = @"Enabled";
            textField.text = [self.remoteSettings isSensorEnabled:index] ? @"true" : @"false";
            break;
        }
            
        case TLDDeviceSensorSectionHighAlarmEnabled : {
            label.text = @"High Alarm Enabled";
            textField.text = [self.remoteSettings highAlarmEnabledForSensor:index] ? @"true" : @"false";
            break;
        }
            
        case TLDDeviceSensorSectionLowAlarmEnabled : {
            label.text = @"Low Alarm Enabled";
            textField.text = [self.remoteSettings lowAlarmEnabledForSensor:index] ? @"true" : @"false";
            break;
        }
            
        default:
            break;
    }
    textField.enabled = NO;

    
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
