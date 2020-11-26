#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"
#import "TLDService.h"

// Instead of LoadingOverlay put the name of your module
@interface ReactBridge : RCTEventEmitter <RCTBridgeModule, TLDeviceDelegate>
@end
