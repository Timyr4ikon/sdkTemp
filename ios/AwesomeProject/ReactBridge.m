#import "React/RCTLog.h"
#import "ReactBridge.h" // Here put the name of your module

@implementation ReactBridge // Here put the name of your module
{
  bool hasListeners;
  TLDService *tldService;
}

-(NSArray<NSString *> *)supportedEvents {
  return @[@"UpdateDevices"];
}

-(void)startObserving {
  hasListeners = YES;
}

-(void)stopObserving {
  hasListeners = NO;
}

// This RCT (React) "macro" exposes the current module to JavaScript
RCT_EXPORT_MODULE();

RCT_REMAP_METHOD(promise, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  BOOL yes = YES; // could be any data type listed under https://facebook.github.io/react-native/docs/native-modules-ios.html#argument-types
  if (yes) {
    resolve(@"iOS promise test");
  } else {
//    NSError *error = ...
    reject(@"error", @"error description", nil);
  }
}

RCT_EXPORT_METHOD(callback:(double)time callback:(RCTResponseSenderBlock)callback)
{
  callback(@[[NSNull null], [NSString stringWithFormat:@"iOS callback test: %f", time]]); // (error, someData) in js
}

RCT_EXPORT_METHOD(setupBridge) {
  tldService = [[TLDService alloc] init];
  tldService.delegate = self;
  [tldService setNotificationListeners];
  RCTLogInfo(@"Bridge setted up");
}

// Scan BLE
RCT_REMAP_METHOD(scanBLE, scanBLEWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [tldService scanBLE:resolve rejecter:reject];
}

// Retrieve BLE
RCT_REMAP_METHOD(retrieveBLE, retrieveBLEWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [tldService retrieveBLE:resolve rejecter:reject];
}

// Stop device scan
RCT_REMAP_METHOD(stopScan, stopScanWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [tldService stopScan:resolve rejecter:reject];
}

// Clear all
RCT_REMAP_METHOD(clearAll, clearAllWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [tldService clearAll:resolve rejecter:reject];
}

// Delete by index
RCT_REMAP_METHOD(deleteDevice, deleteDeviceByIndex:(NSInteger)index withResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [tldService deleteDevice:index resolver:resolve rejecter:reject];
}

// Forget device by index
RCT_REMAP_METHOD(forgetDevice, forgetDeviceByIndex:(NSInteger)index withResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [tldService forgetDevice:index resolver:resolve rejecter:reject];
}

// WiFi Service connection
RCT_REMAP_METHOD(connectToService, connectToServerWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
  [tldService attemptServiceConnectionForTransport:resolve rejecter:reject];
}

-(void)updateDevices:(NSString *)deviceList {
  if (hasListeners) {
    [self sendEventWithName:@"UpdateDevices" body:deviceList];
  }
}

@end
