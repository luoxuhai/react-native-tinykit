#import "Tinykit.h"
#import <React/RCTReloadCommand.h>
#import <UIKit/UIKit.h>

@implementation Tinykit

- (void)restart {
    dispatch_sync(dispatch_get_main_queue(), ^{
      RCTTriggerReloadCommandListeners(@"react-native-tinykit");
    });
}

- (NSNumber *)getBatteryLevel {
    UIDevice *device = [UIDevice currentDevice];
    
    // Check if battery monitoring is already enabled before enabling it
    BOOL wasMonitoringEnabled = device.batteryMonitoringEnabled;
    if (!wasMonitoringEnabled) {
        device.batteryMonitoringEnabled = YES;
    }
    
    float batteryLevel = device.batteryLevel;
    
    // Restore previous monitoring state
    if (!wasMonitoringEnabled) {
        device.batteryMonitoringEnabled = NO;
    }
    
    if (batteryLevel < 0.0) {
        // Battery level is unknown, return -1
        return @(-1);
    }
    
    // Convert to percentage (0-100)
    return @(batteryLevel * 100.0);
}

- (BOOL)isLowPowerModeEnabled {
    return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
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
