//
//  TLDevicePairController.m
//  ThermaLib Demo
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import "TLDeviceAccessRequestController.h"
#import <ThermaLib/ThermaLib.h>
#import <ThermaLib/TLDevice.h>
#import "UIView+Toast.h"

@interface TLDeviceAccessRequestController ()

@property (weak, nonatomic) IBOutlet UITextField *serialNumber;
@property (weak, nonatomic) IBOutlet UITextField *pairingKey;
@property (weak, nonatomic) IBOutlet UILabel *infoMessage;

- (IBAction)pairButtonPressed:(id)sender;
@end

@implementation TLDeviceAccessRequestController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Listen for device pairing complete
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasPaired:) name:ThermaLibDeviceRegistrationCompleteNotificationName object:nil];
    
    // Listen for device pairing failure
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(devicePairingFailed:) name:ThermaLibDeviceRegistrationFailNotificationName object:nil];
 }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
 
- (IBAction)pairButtonPressed:(id)sender {
    // THIS HANDLER ASSUMES THAT THE PAIR REQUEST IS FOR A CLOUD DEVICE, i.e. one whose .transportType is TLTransportCloudService
    self.infoMessage.text = @"";
    
    if( [self validateInputFields] ) {
        // Normalise the serial number by knocking off any leading D (either case).
        NSString *normalisedSerialNumber = [_serialNumber.text.uppercaseString stringByReplacingOccurrencesOfString:@"D" withString:@""];
        // For Cloud devices, the normalised serial number is used as the identifer. (This is in contrast to Bluetooth LE devices, for example,
        // which use the device's MAC address.)
        NSString *identifier = normalisedSerialNumber;
        
        // If ThermaLib already has a corresponding object, use it, otherwise create
        // a new one.
        id<TLDevice> device = [[ThermaLib sharedInstance] deviceWithIdentifier:identifier
                                                                     transport:TLTransportCloudService];
        if( device == nil ) {
            // Not found - try to create a new one, with placeholder name, designed to mimic a real name
            // inasmuch as it begins with the normalised serial number. Note that this will be replaced
            // with the real name once the web service has been polled for information for the device
            // (which for Cloud devices corresponds to the Connected state).
            NSString *name = [normalisedSerialNumber stringByAppendingString:@" Therma WiFi"];
            device = [[ThermaLib sharedInstance] createDeviceWithName:name
                                                           identifier:identifier
                                                            transport:TLTransportCloudService];
        
        }
        
        if( device == nil ) {
            // Device was not found and could not be created - abort.
            [self feedback:@"Could not create WiFi device object"];
        }
        else {
            // IF THE DEVICE EXISTS BUT THE STATE IS ANYTHING OTHER THAN UNREGISTERED, THE DEVICE
            // DOES NOT REQUIRE PAIRING. This is most probably because it is already paired.
            // (Note that the web service permits a connected app to force-unpair from all other apps.
            // At the time of writing the SDK does not allow for such a scenario.)
            //
            if( device.connectionState != TLDeviceConnectionStateUnregistered ) {
                [self feedback:[NSString stringWithFormat:@"Device %@ does not require pairing.", identifier]];
            }
            else {
                // Request access. This is an asynchronous call, whose success or failure is reported by one
                // of the iOS notifications subscribed to above.
                
                // NOTE. This example uses the key exactly as entered, without any mapping of letters/digits that
                // are ambiguous on the display. For example, a user might erroneously enter the letter 'O'
                // for the number '0'. Real apps may wish to intercept such errors and handle them differently,
                // either by mapping them to the letter/digit that was probably meant, or providing interactive
                // correction.
                [[ThermaLib sharedInstance] requestDeviceAccess:device
                                            accessKey:_pairingKey.text.uppercaseString];
            }
        }
    }
    else {
        [self feedback:@"INPUT IS NOT VALID FOR ACCESS REQUEST"];
    }
    
}
- (BOOL) validateInputFields
{
    BOOL ret = YES;
    if( _serialNumber.text == nil
       || _serialNumber.text.length != 9
       || _pairingKey.text == nil
       || _pairingKey.text.length != 8 )
    {
        ret = NO;
    }
    return ret;
}

#pragma mark -
#pragma mark Notification handlers

- (void)deviceWasPaired:(NSNotification *)sender
{
    [self feedback:@"Device was paired successfully."];
}

- (void)devicePairingFailed:(NSNotification *)sender
{
    [self feedback:@"Device pairing failed."];
}

#pragma mark -
#pragma mark Notification handlers

-(void) feedback:(NSString *)message
{
    self.infoMessage.text = message;
}


@end
