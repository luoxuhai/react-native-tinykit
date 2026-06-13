#import "Tinykit.h"
#if __has_include(<react_native_tinykit/react_native_tinykit-Swift.h>)
#import "react_native_tinykit/react_native_tinykit-Swift.h"
#else
#import "react_native_tinykit-Swift.h"
#endif


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

- (void)activateKeepAwake {
  [_nativeTinykit activateKeepAwake];
}

- (void)deactivateKeepAwake {
  [_nativeTinykit deactivateKeepAwake];
}

- (void)impact:(NSString *)style {
  [_nativeTinykit impactWithStyle:style];
}

- (void)selection {
  [_nativeTinykit selection];
}

- (void)notification:(NSString *)type {
  [_nativeTinykit notificationWithType:type];
}

- (void)showColorPicker:(JS::NativeTinykit::ColorPickerOptions &)options resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  NSMutableDictionary *pickerOptions = [NSMutableDictionary dictionary];

  NSString *selectedColor = options.selectedColor();
  if (selectedColor != nil) {
    pickerOptions[@"selectedColor"] = selectedColor;
  }

  auto supportsAlpha = options.supportsAlpha();
  if (supportsAlpha.has_value()) {
    pickerOptions[@"supportsAlpha"] = @(*supportsAlpha);
  }

  auto supportsEyedropper = options.supportsEyedropper();
  if (supportsEyedropper.has_value()) {
    pickerOptions[@"supportsEyedropper"] = @(*supportsEyedropper);
  }

  auto maximumLinearExposure = options.maximumLinearExposure();
  if (maximumLinearExposure.has_value()) {
    pickerOptions[@"maximumLinearExposure"] = @(*maximumLinearExposure);
  }

  NSString *title = options.title();
  if (title != nil) {
    pickerOptions[@"title"] = title;
  }

  auto showDoneButton = options.showDoneButton();
  if (showDoneButton.has_value()) {
    pickerOptions[@"showDoneButton"] = @(*showDoneButton);
  }

  NSString *doneButtonTitle = options.doneButtonTitle();
  if (doneButtonTitle != nil) {
    pickerOptions[@"doneButtonTitle"] = doneButtonTitle;
  }

  auto detents = options.detents();
  if (detents.has_value()) {
    NSMutableArray *detentOptions = [NSMutableArray arrayWithCapacity:detents->size()];

    for (const auto &detent : *detents) {
      NSMutableDictionary *detentOption = [NSMutableDictionary dictionary];

      NSString *type = detent.type();
      if (type != nil) {
        detentOption[@"type"] = type;
      }

      NSString *identifier = detent.identifier();
      if (identifier != nil) {
        detentOption[@"identifier"] = identifier;
      }

      auto height = detent.height();
      if (height.has_value()) {
        detentOption[@"height"] = @(*height);
      }

      auto fraction = detent.fraction();
      if (fraction.has_value()) {
        detentOption[@"fraction"] = @(*fraction);
      }

      [detentOptions addObject:detentOption];
    }

    pickerOptions[@"detents"] = detentOptions;
  }

  NSString *selectedDetentIdentifier = options.selectedDetentIdentifier();
  if (selectedDetentIdentifier != nil) {
    pickerOptions[@"selectedDetentIdentifier"] = selectedDetentIdentifier;
  }

  NSString *largestUndimmedDetentIdentifier = options.largestUndimmedDetentIdentifier();
  if (largestUndimmedDetentIdentifier != nil) {
    pickerOptions[@"largestUndimmedDetentIdentifier"] = largestUndimmedDetentIdentifier;
  }

  auto prefersGrabberVisible = options.prefersGrabberVisible();
  if (prefersGrabberVisible.has_value()) {
    pickerOptions[@"prefersGrabberVisible"] = @(*prefersGrabberVisible);
  }

  [_nativeTinykit showColorPicker:pickerOptions resolve:resolve rejecter:reject];
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
