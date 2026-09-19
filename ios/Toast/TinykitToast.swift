import React
import SPIndicator
import UIKit

@objcMembers @MainActor public final class TinykitToast: NSObject {
  private let views = NSHashTable<SPIndicatorView>.weakObjects()

  public func show(
    _ options: NSDictionary,
    resolve: RCTPromiseResolveBlock,
    rejecter reject: RCTPromiseRejectBlock
  ) {
    guard let window = RCTKeyWindow() else {
      reject("E_TOAST_NO_WINDOW", "Unable to find a window to present the toast.", nil)
      return
    }

    let icon: SPIndicatorIconPreset = options["icon"] as? String == "error" ? .error : .done
    let haptic: SPIndicatorHaptic
    switch options["haptic"] as? String {
    case "success": haptic = .success
    case "warning": haptic = .warning
    case "error": haptic = .error
    default: haptic = .none
    }

    let view = SPIndicatorView(
      title: options["title"] as? String ?? "",
      message: options["message"] as? String ?? "",
      preset: icon
    )
    view.presentWindow = window
    views.add(view)
    view.present(haptic: haptic)
    resolve(nil)
  }

  public func invalidate() {
    for view in views.allObjects { view.dismiss() }
    views.removeAllObjects()
  }
}
