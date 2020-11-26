//
//  ViewController.m
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLDDeviceListViewController.h"
#import "TLDDeviceInfoViewController.h"
#import <ThermaLib/ThermaLib.h>
#import <ThermaLib/TLDevice.h>
#import <ThermaLib/TLSensor.h>

#import "UIView+Toast.h"
#import "TLDUtil.h"

// NSUserDefaults key for persisting Cloud Service App Key

static NSString *THERMAWIFIAPPKEY = @"ThermaWiFiAppKey";

@interface TLDDeviceListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

#pragma mark -
#pragma mark UI fields

@property (weak, nonatomic) IBOutlet UILabel *deviceCountBLE;
@property (weak, nonatomic) IBOutlet UILabel *deviceCountCloud;
@property (weak, nonatomic) IBOutlet UILabel *deviceCountAll;

@property (weak, nonatomic) IBOutlet UISwitch *transportSwitchNone;
@property (weak, nonatomic) IBOutlet UISwitch *transportSwitchBLE;
@property (weak, nonatomic) IBOutlet UISwitch *transportSwitchCloud;

@property (weak, nonatomic) IBOutlet UIButton *serviceConnectCloud;

- (IBAction)transportSwitchPressed:(UISwitch *)sender;
- (IBAction)serviceConnectionButtonWasPressed:(UIButton *)sender;

- (IBAction)scanPressedBLE:(id)sender;
- (IBAction)scanPressedCloud:(id)sender;
- (IBAction)scanPressedAll:(id)sender;
- (IBAction)stopScanPressed:(id)sender;
- (IBAction)clearAllButtonPressed:(id)sender;

@end

@implementation TLDDeviceListViewController

static BOOL wifiConnected = NO;

#pragma mark -
#pragma mark Lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showVersion];

    [self setNotificationListeners];
    
    if( !wifiConnected ) {
        _serviceConnectCloud.enabled = YES;
//        _pairingButton.enabled = NO;
    }
    else {
        _serviceConnectCloud.enabled = NO;
//        _pairingButton.enabled = YES;
    }
    
    // deselect all switches to give default behaviour
    _transportSwitchNone.on = NO;
    _transportSwitchBLE.on = NO;
    _transportSwitchCloud.on = NO;
    [self setSupportedTransportsFromSwitches];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Start scanning for devices
    //[[ThermaLib sharedInstance] startDeviceScan];

    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

// device detail segue preparation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TLDeviceToDeviceInfoSegueIdentifier"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        id<TLDevice> device = [[ThermaLib sharedInstance] deviceList][indexPath.row];
        
        // If we're not already connected to the device, connect to it
        if (device.connectionState == TLDeviceConnectionStateAvailable || device.connectionState == TLDeviceConnectionStateDisconnected) {
            if( [ThermaLib.sharedInstance isServiceConnected:device.transportType]) {
                [[ThermaLib sharedInstance] connectToDevice:device];
            }
        }
        // Give the device info view controller the device to show
        TLDDeviceInfoViewController *viewController = segue.destinationViewController;
        viewController.device = device;
        
    }
    
}

// only allow device add segue if service is connected

-(BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL ret = YES;
    if([identifier isEqualToString:@"PairDeviceSegue"] ) {
        if(![ThermaLib.sharedInstance isServiceConnected:TLTransportCloudService]) {
            [self notifyMessage:@"Cannot pair: cloud service is not connected"];
            ret = NO;
        }
    }
    return ret;
}

- (void)showVersion {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"SDK Version"
                                 message:ThermaLib.sharedInstance.versionNumber
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {}];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark -
#pragma mark User interaction Handlers


- (IBAction)onDeleteTouch:(id)sender {
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceList][indexPath.row];
    
    [ThermaLib.sharedInstance removeDevice:device];
  
}

- (IBAction)onForgetTouch:(id)sender {
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceList][indexPath.row];
    
    [ThermaLib.sharedInstance revokeDeviceAccess:device];
    [ThermaLib.sharedInstance removeDevice:device];
    
}

- (IBAction)serviceConnectionButtonWasPressed:(UIButton *)sender {
    //
    // At the moment, only Cloud devices require a service connection
    //
    if( sender != _serviceConnectCloud ) {
        [self notifyMessage:@"Connection is only required for Cloud devices"];
    }
    else {
        [self attemptServiceConnectionForTransport:TLTransportCloudService];
    }
}

- (IBAction)scanPressedBLE:(id)sender {
    [self startScanWithTransport:TLTransportBluetoothLE retrieveSystemConnections:NO];
}
- (IBAction)retrievePressedBLE:(id)sender {
    [self startScanWithTransport:TLTransportBluetoothLE retrieveSystemConnections:YES];
}

- (IBAction)scanPressedCloud:(id)sender {
    [self startScanWithTransport:TLTransportCloudService retrieveSystemConnections:NO];
}

- (IBAction)scanPressedAll:(id)sender {
    [ThermaLib.sharedInstance startDeviceScan];
    
}

- (IBAction)stopScanPressed:(id)sender {
    [ThermaLib.sharedInstance stopDeviceScan];
}

- (IBAction)clearAllButtonPressed:(id)sender {
    [ThermaLib.sharedInstance stopDeviceScan];
    [self removeAllDevices];
    [self clearCounts];
    [self.tableView reloadData];
}

#pragma mark -
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
    NSLog(@"New Device Found: %@", ((id<TLDevice>) sender.object).deviceName);
    [self.tableView reloadData];
    [self updateScanTotals];
}

- (void)deviceRemoved:(NSNotification *)sender
{
    // A new device has been found so refresh the table
    [self.tableView reloadData];
    [self updateScanTotals];
}

- (void)deviceUpdatedNotificationReceived:(NSNotification *)sender
{
    // The relevant device can be obtained from the notification
    
    [self.tableView reloadData];
}

- (void)deviceDisconnectionNotificationReceived:(NSNotification *)sender
{
    TLDeviceDisconnectionReason reason = (TLDeviceDisconnectionReason) [[sender.userInfo valueForKey:ThermaLibDeviceDisconnectionNotificationReasonKey] integerValue];
    [TLDUtil reportDisconnectionForDevice:sender.object
                                   inView:self.view
                               withReason:reason];
    
    [self.tableView reloadData];
}


- (void)sensorUpdatedNotificationReceived:(NSNotification *)sender
{
    // The relevant sensor can be obtained from the notification
    id<TLSensor> sensor = sender.object;
    id<TLDevice> device = sensor.device;

    // Update the relevant row in the table
    NSInteger index = [[[ThermaLib sharedInstance] deviceList] indexOfObject:device];
    if (index == NSNotFound) return;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark -
#pragma mark Service Connection Handling

// Attempt service connection

- (void)attemptServiceConnectionForTransport:(TLTransport)transport {
    //
    // Check that this transport is supported. See ThermaLib setSupportedTransports
    //
    if( ![ThermaLib.sharedInstance isTransportSupported:transport] ) {
        [self notifyMessage:[NSString stringWithFormat:@"Transport not supported: %@",
                             [TLDUtil stringFromTransport:transport]]];
    }
    //
    // Check that the service is reachable for the transport - to demonstrate, try pressing the pair button
    // when the iOS device has no internet connection.
    //
    else if(![ThermaLib.sharedInstance isServiceReachableForTransport:transport] ) {
        [self notifyMessage:@"Service cannot be reached. Perhaps no Internet?"];
    }
    else {
        //
        // supported and reachable, so try to connect.
        // NOTES:
        // - service connection is an asynchronous operation whose result is reported via the
        //      ThermaLibServiceConnectedNotificationName notification.
        // - Service connection requires a key that identifies the application to the service.
        // - If a key is not provided to connectToService, one will be allocated. In either case
        //      the ThermaLibServiceConnectedNotificationName notification contains the key used.
        // - To retain app access to devices between invocations of the app, the generated app key
        //      should be persisted and reused.
        // - CONSIDERATION: app keys and the permissioning of app keys against devices are permanent
        //      on the service side, so you should re-use app keys where possible, if necessary using
        //      revokeDeviceAccess to break app-device links, and allow the service to reclaim resources.
        
        
        // THIS EXAMPLE persists the app key using NSUserDefaults, so that app access to devices
        // is retained between invocations of the app.
        //
        //
        
        //
        // recover persisted key if there is one.
        //
        NSString *appKey = [[NSUserDefaults standardUserDefaults] stringForKey:THERMAWIFIAPPKEY];
        NSLog( @"Connecting to WIFI service with key %@", appKey);
        //
        // attempt the connection
        //
        [[ThermaLib sharedInstance] connectToService:transport usingKey:appKey];
    }
}

// Handle response to service connection request

- (void) serviceConnectionNotificationReceived:(NSNotification *)sender
{
    // The notification's object is the appKey to be used when setting up device access.
    // In this case, the appKey is known to be a string.
    //
    // Failure of connection is signalled by a nil object.
    //
    NSString *appKey = (NSString *)sender.object;
    
    if( appKey != nil ) {
        [self notifyMessage:[NSString stringWithFormat:@"Service connection succeeded: %@", appKey]];
        
        // IN THIS EXAMPLE we are using NSUserDefaults to persist the key, so that
        // device access is preserved across invocations of the app.
        //
        [[NSUserDefaults standardUserDefaults] setObject:appKey forKey:THERMAWIFIAPPKEY];
        wifiConnected = YES;
        _serviceConnectCloud.enabled = NO;
        //        _pairingButton.enabled = YES;
    }
    else {
        [self notifyMessage:@"Service connection failed"];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[ThermaLib sharedInstance] deviceList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceList][indexPath.row];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TLDDeviceListCellIdentifier" forIndexPath:indexPath];

    UILabel *titleLabel = [cell viewWithTag:1];
    titleLabel.text = [device deviceName];
    
    UILabel *sensor1Label = [cell viewWithTag:2];
    UILabel *sensor2Label = [cell viewWithTag:3];
    

    if(device.isReady){
        
        // Check the device temperature unit and adjust the reading and suffix as necessary
        float reading1 = [device sensorAtIndex:1].reading;
        float reading2 = [device sensorAtIndex:2].reading;
        
        TLDeviceUnit unit1 = [device sensorAtIndex:1].displayUnit;
        TLDeviceUnit unit2 = [device sensorAtIndex:2].displayUnit;

        if (unit1 == TLDeviceUnitFahrenheit) {
            reading1 = reading1 * 1.8 + 32;
        }
        
        if(unit2 == TLDeviceUnitFahrenheit){
            reading2 = reading2 * 1.8 + 32;
        }
        
        sensor1Label.text = [[device sensorAtIndex:1] isFault] ? @"FAULT" : [NSString stringWithFormat:@"%.1f %@", reading1, [TLDUtil stringFromUnit:unit1]];
        
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
        sensor2Label.text = text;
        
    } else {
        sensor2Label.text = @"-";
        sensor1Label.text = @"-";
    }

    UILabel *batteryLabel = [cell viewWithTag:4];
    batteryLabel.text = [NSString stringWithFormat:@"%ld%%", (long)device.batteryLevel];

    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}


#pragma mark -
#pragma mark UITableViewDelegate



#pragma mark -
#pragma mark Util


-(void) notifyMessage:(NSString *)message
{
    [self.view makeToast:message];
}

-(void) updateScanTotalForLabel:(UILabel *)label
                      transport:(TLTransport)transport
{
    if( label != nil ) {
        NSString *s = @"n/a";
        if( [ThermaLib.sharedInstance isTransportSupported:transport]) {
            int count = [ThermaLib.sharedInstance deviceCountForTransport:transport];
            s = [NSNumber numberWithInt:count].stringValue;
            
        }
        label.text = s;
    }
}

-(void) updateScanTotals {
    [self updateScanTotalForLabel:self.deviceCountBLE
                        transport:TLTransportBluetoothLE];
    [self updateScanTotalForLabel:self.deviceCountCloud
                        transport:TLTransportCloudService];
    self.deviceCountAll.text = [NSNumber numberWithInt:[ThermaLib.sharedInstance deviceCount]].stringValue;
}


-(void) startScanWithTransport:(TLTransport)transport retrieveSystemConnections:(BOOL)retrieveSystemConnections{
    if( ![ThermaLib.sharedInstance isTransportSupported:transport] ) {
        [self.view makeToast:[NSString stringWithFormat:@"Transport not supported: %@",
                              [TLDUtil stringFromTransport:transport]]];
    }
    else if( ![ThermaLib.sharedInstance isServiceConnected:transport] ) {
        [self.view makeToast:[NSString stringWithFormat:@"Service not connected for transport: %@",
                              [TLDUtil stringFromTransport:transport]]];
    }
    else {
        [ThermaLib.sharedInstance startDeviceScanWithTransport:transport retrieveSystemConnections:retrieveSystemConnections];
    }
}

// 'None' is an explicit None, so turn all the others off.
// No explicit setting gives the default behaviour
// NOTE once there's been an explicit setting, default behaviour cannot be restored. Test default
// behaviour first.
- (IBAction)transportSwitchPressed:(UISwitch *)sender {
    NSString *name = @"?";
    if( sender == _transportSwitchNone ) {
        name = @"None";
    }
    else if( sender == _transportSwitchBLE ) {
        name = @"BLE";
    }
    else if( sender == _transportSwitchCloud) {
        name = @"Cloud";
    }
    if( sender.isOn  ) {
        if( sender == _transportSwitchNone ) {
                self.transportSwitchBLE.on = NO;
                self.transportSwitchCloud.on = NO;
 
        }
        else {
            self.transportSwitchNone.on = NO;
        }
    }
    [self setSupportedTransportsFromSwitches];
}

-(void) setSupportedTransportsFromSwitches {
    NSMutableArray *transportsToSupport = [NSMutableArray array];
    if( _transportSwitchNone.isOn ) {
         // leave the array empty
    }
    else {
        if( _transportSwitchBLE.isOn ) {
            [transportsToSupport addObject:@(TLTransportBluetoothLE)];
        }
        if( _transportSwitchCloud.isOn ) {
            [transportsToSupport addObject:@(TLTransportCloudService)];
        }
    }
    [[ThermaLib sharedInstance] setSupportedTransports:transportsToSupport];

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
    _deviceCountAll.text = _deviceCountBLE.text = _deviceCountCloud.text = @"0";
}


@end
