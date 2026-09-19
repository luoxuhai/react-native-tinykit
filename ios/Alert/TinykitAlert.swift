import React
import SPAlert
import UIKit

@objcMembers @MainActor public final class TinykitAlert: NSObject {
  private let views = NSHashTable<AlertAppleMusic16View>.weakObjects()

  public func show(
    _ options: NSDictionary,
    resolve: RCTPromiseResolveBlock,
    rejecter reject: RCTPromiseRejectBlock
  ) {
    let duration = options["duration"] as? Double ?? 2000
    guard duration.isFinite else {
      reject("E_ALERT_INVALID_DURATION", "Alert duration must be a finite number.", nil)
      return
    }
    guard let window = RCTKeyWindow() else {
      reject("E_ALERT_NO_WINDOW", "Unable to find a window to present the alert.", nil)
      return
    }

    let icon: AlertIcon
    switch options["icon"] as? String {
    case "error": icon = .error
    case "spinner": icon = .spinnerLarge
    case "heart": icon = .heart
    default: icon = .done
    }
    let haptic: AlertHaptic
    switch options["haptic"] as? String {
    case "success": haptic = .success
    case "warning": haptic = .warning
    case "error": haptic = .error
    default: haptic = .none
    }

    let view = AlertAppleMusic16View(
      title: options["title"] as? String ?? "",
      subtitle: options["message"] as? String ?? "",
      icon: icon
    )
    view.haptic = haptic
    view.dismissByTap = false
    view.dismissInTime = duration > 0
    view.duration = duration / 1000
    views.add(view)
    view.present(on: window)
    resolve(nil)
  }

  public func dismissAll() {
    for view in views.allObjects { view.dismiss() }
    views.removeAllObjects()
  }
}
