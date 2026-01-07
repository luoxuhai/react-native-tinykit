#import "Tinykit.h"
#import <React/RCTReloadCommand.h>
#import <UIKit/UIKit.h>

@implementation Tinykit

- (void)restart {
    dispatch_sync(dispatch_get_main_queue(), ^{
      RCTTriggerReloadCommandListeners(@"react-native-tinykit");
    });
}

- (void)getBatteryLevel:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIDevice *device = [UIDevice currentDevice];
        device.batteryMonitoringEnabled = YES;
        
        float batteryLevel = device.batteryLevel;
        
        if (batteryLevel < 0.0) {
            // Battery level is unknown
            reject(@"BATTERY_UNAVAILABLE", @"Battery level is unavailable", nil);
        } else {
            // Convert to percentage (0-100)
            NSNumber *batteryPercentage = @(batteryLevel * 100.0);
            resolve(batteryPercentage);
        }
    });
}

- (void)isLowPowerModeEnabled:(RCTPromiseResolveBlock)resolve
                       reject:(RCTPromiseRejectBlock)reject {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isLowPowerModeEnabled = [[NSProcessInfo processInfo] isLowPowerModeEnabled];
        resolve(@(isLowPowerModeEnabled));
    });
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeTinykitSpecJSI>(params);
}

+ (NSString *)moduleName
{
  return @"Tinykit";
}

@end
