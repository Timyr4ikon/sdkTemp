#import <ThermaLib/ThermaLib.h>
#import "TLDUtil.h"
#import "React/RCTLog.h"

@protocol TLDeviceDelegate <NSObject>
-(void)updateDevices:(NSString*)deviceList;
@end

@interface TLDService: NSObject

@property (assign) id <TLDeviceDelegate> delegate;

- (void)setNotificationListeners;

-(void) scanBLE:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject;

-(void) retrieveBLE:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject;

-(void) stopScan:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject;

-(void) clearAll:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject;

-(void) deleteDevice:(NSInteger)index resolver:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject;

-(void) forgetDevice:(NSInteger)index resolver:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject;

-(void) attemptServiceConnectionForTransport:(void (^)(__strong id))resolve rejecter:(void (^)(NSString *__strong, NSString *__strong, NSError *__strong))reject;

@end

