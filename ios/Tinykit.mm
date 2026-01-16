#import "Tinykit.h"
#import "react_native_tinykit-Swift.h"

@implementation Tinykit {
  NativeTinykit *_nativeTinykit;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    __weak Tinykit *weakSelf = self;
    _nativeTinykit = [[NativeTinykit alloc] initOnThermalStateChange:^(NSString *value) {
      [weakSelf emitOnThermalStateChange:value];
    }];
  }
  return self;
}

- (NSString *)getThermalState
{
  return [_nativeTinykit getThermalState];
}

- (void)restart {
  [_nativeTinykit restart];
}

- (void)requestReview:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_nativeTinykit requestReviewWithResolve:resolve rejecter:reject];
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
