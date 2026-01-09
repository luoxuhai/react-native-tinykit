#import "Tinykit.h"
#import <React/RCTReloadCommand.h>

@implementation Tinykit

/// Initializes the Tinykit module and registers for thermal state change notifications.
- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(thermalStateChange:)
                                                     name:NSProcessInfoThermalStateDidChangeNotification
                                                   object:nil];
    }
    return self;
}

/// Cleans up by removing the observer from the notification center.
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/// Converts a thermal state enum value to its string representation.
/// @param thermalState The thermal state to convert.
/// @return A string representation of the thermal state ("nominal", "fair", "serious", or "critical").
+ (NSString *)thermalStateToString:(NSProcessInfoThermalState)thermalState
{
    switch (thermalState) {
        case NSProcessInfoThermalStateNominal:
            return @"nominal";
        case NSProcessInfoThermalStateFair:
            return @"fair";
        case NSProcessInfoThermalStateSerious:
            return @"serious";
        case NSProcessInfoThermalStateCritical:
            return @"critical";
        default:
            return @"nominal";
    }
}

/// Handles thermal state change notifications from the system.
/// @param notification The notification containing thermal state change information.
- (void)thermalStateChange:(NSNotification *)notification
{
    NSString *state = [Tinykit thermalStateToString:[[NSProcessInfo processInfo] thermalState]];
    [self emitOnThermalStateChange:@{@"thermalState": state}];
}

/// Returns the current thermal state of the device as a string.
/// @return A string representation of the current thermal state.
- (NSString *)getThermalState
{
    NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
    return [Tinykit thermalStateToString:thermalState];
}

/// Triggers a reload of the React Native bundle on the main thread.
- (void)restart {
    dispatch_sync(dispatch_get_main_queue(), ^{
      RCTTriggerReloadCommandListeners(@"react-native-tinykit");
    });
}

/// Returns the TurboModule instance for this native module.
/// @param params The initialization parameters for the TurboModule.
/// @return A shared pointer to the TurboModule instance.
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeTinykitSpecJSI>(params);
}

/// Returns the name of this native module used for JavaScript bridge registration.
/// @return The module name "Tinykit".
+ (NSString *)moduleName
{
  return @"Tinykit";
}

@end
