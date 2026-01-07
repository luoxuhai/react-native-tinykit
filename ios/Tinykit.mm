#import "Tinykit.h"
#import <React/RCTReloadCommand.h>

@implementation Tinykit
{
    bool hasListeners;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(thermalStateDidChange:)
                                                     name:NSProcessInfoThermalStateDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"thermalStateDidChange"];
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

- (void)thermalStateDidChange:(NSNotification *)notification
{
    if (hasListeners) {
        NSString *state = [self thermalStateToString:[[NSProcessInfo processInfo] thermalState]];
        [self sendEventWithName:@"thermalStateDidChange" body:@{@"thermalState": state}];
    }
}

- (NSString *)thermalStateToString:(NSProcessInfoThermalState)thermalState
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

- (NSString *)getThermalState
{
    NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
    return [self thermalStateToString:thermalState];
}

- (void)restart {
    dispatch_sync(dispatch_get_main_queue(), ^{
      RCTTriggerReloadCommandListeners(@"react-native-tinykit");
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
