#import "TLDService.h"

@implementation TLDService

static NSString *THERMAWIFIAPPKEY = @"ThermaWiFiAppKey";
static BOOL wifiConnected = NO;

#pragma mark Notification Handling

- (void)setNotificationListeners {
    // Listen for new devices being discovered
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDeviceFound:) name:ThermaLibNewDeviceFoundNotificationName object:nil];
    
    // Listen for devices being deleted
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRemoved:) name:ThermaLibDeviceDeletedNotificationName object:nil];
    
    // Listen for device updates. This can be called several times while the device is initialising
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdatedNotificationReceived:) name:ThermaLibDeviceUpdatedNotificationName object:nil];
    
    // Listen for device disconnections. This can be called several times while the device is initialising
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDisconnectionNotificationReceived:) name:ThermaLibDeviceDisconnectionNotificationName object:nil];
    
    // Listen for sensor updates
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorUpdatedNotificationReceived:) name:ThermaLibSensorUpdatedNotificationName object:nil];
  
    // Listen for service connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceConnectionNotificationReceived:) name:ThermaLibServiceConnectedNotificationName object:nil];

}

- (void)newDeviceFound:(NSNotification *)sender
{
  // A new device has been found so refresh the table
  RCTLogInfo(@"New Device Found: %@", ((id<TLDevice>) sender.object).deviceName);
  //[self.tableView reloadData];
  [self updateScanTotals];
}

- (void)deviceRemoved:(NSNotification *)sender
{
  // A new device has been found so refresh the table
  //[self.tableView reloadData];
  [self updateScanTotals];
}

- (void)deviceUpdatedNotificationReceived:(NSNotification *)sender
{
    // The relevant device can be obtained from the notification
    
    //[self.tableView reloadData];
}

- (void)deviceDisconnectionNotificationReceived:(NSNotification *)sender
{
    TLDeviceDisconnectionReason reason = (TLDeviceDisconnectionReason) [[sender.userInfo valueForKey:ThermaLibDeviceDisconnectionNotificationReasonKey] integerValue];
    //[TLDUtil reportDisconnectionForDevice:sender.object
    //                               inView:self.view
    //                           withReason:reason];
    
    //[self.tableView reloadData];
}

- (void)sensorUpdatedNotificationReceived:(NSNotification *)sender
{
    // The relevant sensor can be obtained from the notification
    id<TLSensor> sensor = sender.object;
    id<TLDevice> device = sensor.device;

    // Update the relevant row in the table
    NSInteger index = [[[ThermaLib sharedInstance] deviceList] indexOfObject:device];
    if (index == NSNotFound) return;

    //[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) serviceConnectionNotificationReceived:(NSNotification *)sender
{
    NSString *appKey = (NSString *)sender.object;
    
    if( appKey != nil ) {
      RCTLogInfo(@"Service connection succeeded: %@", appKey);
        [[NSUserDefaults standardUserDefaults] setObject:appKey forKey:THERMAWIFIAPPKEY];
        wifiConnected = YES;
        //_serviceConnectCloud.enabled = NO; disable connect button
    }
    else {
      RCTLogInfo(@"Service connection failed");
    }
}

#pragma mark EVENTS

- (void) scanBLE:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
  RCTLogInfo(@"scanBLE called");
  [self startScanWithTransport:TLTransportBluetoothLE retrieveSystemConnections:NO resolver:resolve rejecter:reject];
}

- (void) retrieveBLE:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
  RCTLogInfo(@"retrieveBLE called");
  [self startScanWithTransport:TLTransportBluetoothLE retrieveSystemConnections:YES resolver:resolve rejecter:reject];
  resolve(@"success");
}

-(void) startScanWithTransport:(TLTransport)transport retrieveSystemConnections:(BOOL)retrieveSystemConnections resolver:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
    if( ![ThermaLib.sharedInstance isTransportSupported:transport] ) {
      NSString *errorString = [NSString stringWithFormat:@"Transport not supported: %@", [TLDUtil stringFromTransport:transport]];
      RCTLogInfo(@"%@", errorString);
      reject(@"not_supported", errorString, nil);
    }
    else if( ![ThermaLib.sharedInstance isServiceConnected:transport] ) {
      NSString *errorString = [NSString stringWithFormat:@"Service not connected for transport: %@", [TLDUtil stringFromTransport:transport]];
      RCTLogInfo(@"%@", errorString);
      reject(@"not_connected", errorString, nil);
    }
    else {
      [ThermaLib.sharedInstance startDeviceScanWithTransport:transport retrieveSystemConnections:retrieveSystemConnections];
      resolve(@"success");
    }
}

-(void) stopScan:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
  RCTLogInfo(@"stopScan called");
  [ThermaLib.sharedInstance stopDeviceScan];
  resolve(@"success");
}

-(void) clearAll:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
  RCTLogInfo(@"clearAll called");
  [ThermaLib.sharedInstance stopDeviceScan];
  [self removeAllDevices];
  [self clearCounts];
  resolve(@"success");
  //[self.tableView reloadData];
}

-(void) deleteDevice:(NSInteger)index resolver:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
  RCTLogInfo(@"deleteDevice called");
  
  NSArray<id<TLDevice>> *devices = [[ThermaLib sharedInstance] deviceList];
  if (index < [devices count]) {
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceList][index];
    [ThermaLib.sharedInstance removeDevice:device];
    resolve(@"success");
  } else {
    NSString *errorString = [NSString stringWithFormat:@"There is no device at index %lu", index];
    RCTLogInfo(@"%@", errorString);
    reject(@"not_found", errorString, nil);
  }
}

-(void) forgetDevice:(NSInteger)index resolver:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
  RCTLogInfo(@"forgetDevice");
  
  NSArray<id<TLDevice>> *devices = [[ThermaLib sharedInstance] deviceList];
  if (index < [devices count]) {
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceList][index];
    
    [ThermaLib.sharedInstance revokeDeviceAccess:device];
    [ThermaLib.sharedInstance removeDevice:device];
    resolve(@"success");
  } else {
    NSString *errorString = [NSString stringWithFormat:@"There is no device at index %lu", index];
    RCTLogInfo(@"%@", errorString);
    reject(@"not_found", errorString, nil);
  }
}

-(void) attemptServiceConnectionForTransport:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject {
  if( ![ThermaLib.sharedInstance isTransportSupported:TLTransportCloudService] ) {
    NSString *errorString = [NSString stringWithFormat:@"Transport not supported: %@", [TLDUtil stringFromTransport:TLTransportCloudService]];
    RCTLogInfo(@"%@", errorString);
    reject(@"not_supported", errorString, nil);
  }
  else if(![ThermaLib.sharedInstance isServiceReachableForTransport:TLTransportCloudService] ) {
    NSString *errorString = [NSString stringWithFormat:@"Service cannot be reached. Perhaps no Internet?"];
    RCTLogInfo(@"%@", errorString);
    reject(@"no_internet", errorString, nil);
  }
  else {
    NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:THERMAWIFIAPPKEY];
    RCTLogInfo(@"Connecting to WIFI service with key %@", appKey);
    [[ThermaLib sharedInstance] connectToService:TLTransportCloudService usingKey:appKey];
    resolve(@"success");
  }
}



-(void) removeAllDevices {
    ThermaLib *tl = ThermaLib.sharedInstance;
    NSMutableArray<id<TLDevice>> *tempArray = [NSMutableArray array];
    for( id<TLDevice> device in tl.deviceList ) {
        [tempArray addObject:device];
    }
    for( id<TLDevice> device in tempArray ) {
        [tl removeDevice:device];
    }
}

-(void) clearCounts {
  // Label
    //_deviceCountAll.text = _deviceCountBLE.text = _deviceCountCloud.text = @"0";
}

-(void) updateScanTotals {
  NSArray<id<TLDevice>> *devices = [[ThermaLib sharedInstance] deviceList];
  
  NSMutableArray *devicesArray = [NSMutableArray array];
  for (id<TLDevice> device in devices) {
    NSMutableDictionary *deviceDictionary = [NSMutableDictionary new];
    [deviceDictionary setObject:device.deviceName forKey:@"deviceName"];
    if (device.isReady) {
      // Check the device temperature unit and adjust the reading and suffix as necessary
      float reading1 = [device sensorAtIndex:1].reading; //
      float reading2 = [device sensorAtIndex:2].reading; //
      
      TLDeviceUnit unit1 = [device sensorAtIndex:1].displayUnit;
      TLDeviceUnit unit2 = [device sensorAtIndex:2].displayUnit;

      if (unit1 == TLDeviceUnitFahrenheit) {
          reading1 = reading1 * 1.8 + 32;
      }
      
      if(unit2 == TLDeviceUnitFahrenheit){
          reading2 = reading2 * 1.8 + 32;
      }
      
      NSString *firstSensor = [[device sensorAtIndex:1] isFault] ? @"FAULT" : [NSString stringWithFormat:@"%.1f %@", reading1, [TLDUtil stringFromUnit:unit1]];
      [deviceDictionary setObject:firstSensor forKey:@"firstSensor"];
      
      // Second sensor
      NSString *text;
      if ([device isSensorEnabledAtIndex:2]) {
          if ([[device sensorAtIndex:2] isFault]) {
              text = @"FAULT";
          } else {
              text = [NSString stringWithFormat:@"%.1f %@", reading2, [TLDUtil stringFromUnit:unit2]];
          }
      } else {
          text = @"-";
      }
      [deviceDictionary setObject:text forKey:@"secondSensor"];
    } else {
      [deviceDictionary setObject:@"-" forKey:@"secondSensor"];
      [deviceDictionary setObject:@"-" forKey:@"firstSensor"];
    }
    NSNumber *batteryLevel = @(device.batteryLevel);
    [deviceDictionary setObject:batteryLevel forKey:@"batteryLevel"];
    [devicesArray addObject:deviceDictionary];
  }
  
  NSArray *devicesArrayToRN = [NSArray arrayWithArray:devicesArray];
  
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:devicesArrayToRN options:NSJSONWritingPrettyPrinted error:&error];
  if (error != nil) {
    RCTLogInfo(@"%@", error.debugDescription);
    return;
  }
  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  
  [self.delegate updateDevices:jsonString];
//    [self updateScanTotalForLabel:self.deviceCountBLE
//                        transport:TLTransportBluetoothLE];
//    self.deviceCountAll.text = [NSNumber numberWithInt:[ThermaLib.sharedInstance deviceCount]].stringValue;
}

@end
