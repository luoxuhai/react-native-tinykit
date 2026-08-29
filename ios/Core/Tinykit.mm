#import "Tinykit.h"

#import <React/RCTLog.h>

#if TINYKIT_FEATURE_MAIL
#import <MessageUI/MessageUI.h>
#endif

#if TINYKIT_FEATURE_RESTART || TINYKIT_FEATURE_THERMAL_STATE || TINYKIT_FEATURE_REVIEW || \
  TINYKIT_FEATURE_KEEP_AWAKE || TINYKIT_FEATURE_COLOR_PICKER || TINYKIT_FEATURE_HAPTICS || \
  TINYKIT_FEATURE_MAIL
#if __has_include(<react_native_tinykit/react_native_tinykit-Swift.h>)
#import <react_native_tinykit/react_native_tinykit-Swift.h>
#else
#import "react_native_tinykit-Swift.h"
#endif
#endif

static void TinykitLogMissingFeature(NSString *feature)
{
  RCTLogError(
    @"[TinyKit] The %@ feature is not installed. Add '%@' to the "
    @"'react-native-tinykit.features' array in package.json and run pod install.",
    feature,
    feature
  );
}

@implementation Tinykit {
#if TINYKIT_FEATURE_THERMAL_STATE
  TinykitThermalState *_thermalState;
#endif
#if TINYKIT_FEATURE_COLOR_PICKER
  TinykitColorPicker *_colorPicker;
#endif
#if TINYKIT_FEATURE_MAIL
  TinykitMail *_mail;
#endif
}

- (NSArray<NSString *> *)getEnabledFeatures
{
  NSMutableArray<NSString *> *features = [NSMutableArray array];

#if TINYKIT_FEATURE_RESTART
  [features addObject:@"Restart"];
#endif
#if TINYKIT_FEATURE_THERMAL_STATE
  [features addObject:@"ThermalState"];
#endif
#if TINYKIT_FEATURE_REVIEW
  [features addObject:@"Review"];
#endif
#if TINYKIT_FEATURE_KEEP_AWAKE
  [features addObject:@"KeepAwake"];
#endif
#if TINYKIT_FEATURE_COLOR_PICKER
  [features addObject:@"ColorPicker"];
#endif
#if TINYKIT_FEATURE_HAPTICS
  [features addObject:@"Haptics"];
#endif
#if TINYKIT_FEATURE_MAIL
  [features addObject:@"Mail"];
#endif

  return features;
}

- (void)restart
{
#if TINYKIT_FEATURE_RESTART
  [TinykitRestart restart];
#else
  TinykitLogMissingFeature(@"Restart");
#endif
}

- (NSString *)getThermalState
{
#if TINYKIT_FEATURE_THERMAL_STATE
  return [TinykitThermalState currentState];
#else
  TinykitLogMissingFeature(@"ThermalState");
  return @"nominal";
#endif
}

- (void)startThermalStateMonitoring
{
#if TINYKIT_FEATURE_THERMAL_STATE
  if (_thermalState == nil) {
    __weak Tinykit *weakSelf = self;
    _thermalState = [[TinykitThermalState alloc] initOnThermalStateChange:^(NSString *value) {
      [weakSelf emitOnThermalStateChange:value];
    }];
  }
#else
  TinykitLogMissingFeature(@"ThermalState");
#endif
}

- (void)stopThermalStateMonitoring
{
#if TINYKIT_FEATURE_THERMAL_STATE
  _thermalState = nil;
#endif
}

- (void)requestReview:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
#if TINYKIT_FEATURE_REVIEW
  [TinykitReview requestReviewWithResolve:resolve rejecter:reject];
#else
  reject(
    @"E_FEATURE_NOT_INSTALLED",
    @"TinyKit Review is not installed. Add 'Review' to the 'react-native-tinykit.features' array in package.json and run pod install.",
    nil
  );
#endif
}

- (void)activateKeepAwake
{
#if TINYKIT_FEATURE_KEEP_AWAKE
  [TinykitKeepAwake activate];
#else
  TinykitLogMissingFeature(@"KeepAwake");
#endif
}

- (void)deactivateKeepAwake
{
#if TINYKIT_FEATURE_KEEP_AWAKE
  [TinykitKeepAwake deactivate];
#else
  TinykitLogMissingFeature(@"KeepAwake");
#endif
}

- (void)impact:(NSString *)style
{
#if TINYKIT_FEATURE_HAPTICS
  [TinykitHaptics impactWithStyle:style];
#else
  TinykitLogMissingFeature(@"Haptics");
#endif
}

- (void)selection
{
#if TINYKIT_FEATURE_HAPTICS
  [TinykitHaptics selection];
#else
  TinykitLogMissingFeature(@"Haptics");
#endif
}

- (void)notification:(NSString *)type
{
#if TINYKIT_FEATURE_HAPTICS
  [TinykitHaptics notificationWithType:type];
#else
  TinykitLogMissingFeature(@"Haptics");
#endif
}

- (void)showColorPicker:(JS::NativeTinykit::ColorPickerOptions &)options
                  resolve:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject
{
#if TINYKIT_FEATURE_COLOR_PICKER
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

  if (_colorPicker == nil) {
    _colorPicker = [TinykitColorPicker new];
  }

  [_colorPicker showColorPicker:pickerOptions resolve:resolve rejecter:reject];
#else
  reject(
    @"E_FEATURE_NOT_INSTALLED",
    @"TinyKit ColorPicker is not installed. Add 'ColorPicker' to the 'react-native-tinykit.features' array in package.json and run pod install.",
    nil
  );
#endif
}

- (NSNumber *)canSendMail
{
#if TINYKIT_FEATURE_MAIL
  if ([NSThread isMainThread]) {
    return @([TinykitMail canSendMail]);
  }

  __block BOOL canSendMail = NO;
  dispatch_sync(dispatch_get_main_queue(), ^{
    canSendMail = [TinykitMail canSendMail];
  });
  return @(canSendMail);
#else
  return @NO;
#endif
}

- (void)openMail:(JS::NativeTinykit::MailOptions &)options
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject
{
#if TINYKIT_FEATURE_MAIL
  NSMutableDictionary *mailOptions = [NSMutableDictionary dictionary];

  NSString *subject = options.subject();
  if (subject != nil) {
    mailOptions[@"subject"] = subject;
  }

  auto recipients = options.recipients();
  if (recipients.has_value()) {
    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:recipients->size()];
    for (NSString *value : *recipients) {
      [values addObject:value];
    }
    mailOptions[@"recipients"] = values;
  }

  auto ccRecipients = options.ccRecipients();
  if (ccRecipients.has_value()) {
    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:ccRecipients->size()];
    for (NSString *value : *ccRecipients) {
      [values addObject:value];
    }
    mailOptions[@"ccRecipients"] = values;
  }

  auto bccRecipients = options.bccRecipients();
  if (bccRecipients.has_value()) {
    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:bccRecipients->size()];
    for (NSString *value : *bccRecipients) {
      [values addObject:value];
    }
    mailOptions[@"bccRecipients"] = values;
  }

  NSString *body = options.body();
  if (body != nil) {
    mailOptions[@"body"] = body;
  }

  auto isHTML = options.isHTML();
  if (isHTML.has_value()) {
    mailOptions[@"isHTML"] = @(*isHTML);
  }

  auto attachments = options.attachments();
  if (attachments.has_value()) {
    NSMutableArray *attachmentOptions = [NSMutableArray arrayWithCapacity:attachments->size()];

    for (const auto &attachment : *attachments) {
      NSMutableDictionary *attachmentOption = [NSMutableDictionary dictionary];

      NSString *path = attachment.path();
      if (path != nil) {
        attachmentOption[@"path"] = path;
      }

      NSString *uri = attachment.uri();
      if (uri != nil) {
        attachmentOption[@"uri"] = uri;
      }

      NSString *type = attachment.type();
      if (type != nil) {
        attachmentOption[@"type"] = type;
      }

      NSString *mimeType = attachment.mimeType();
      if (mimeType != nil) {
        attachmentOption[@"mimeType"] = mimeType;
      }

      NSString *name = attachment.name();
      if (name != nil) {
        attachmentOption[@"name"] = name;
      }

      [attachmentOptions addObject:attachmentOption];
    }

    mailOptions[@"attachments"] = attachmentOptions;
  }

  void (^presentMail)(void) = ^{
    if (self->_mail == nil) {
      self->_mail = [TinykitMail new];
    }

    [self->_mail openMail:mailOptions resolve:resolve rejecter:reject];
  };

  if ([NSThread isMainThread]) {
    presentMail();
  } else {
    dispatch_async(dispatch_get_main_queue(), presentMail);
  }
#else
  reject(
    @"E_FEATURE_NOT_INSTALLED",
    @"TinyKit Mail is not installed. Add 'Mail' to the 'react-native-tinykit.features' array in package.json and run pod install.",
    nil
  );
#endif
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
