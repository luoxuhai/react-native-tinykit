import UIKit

@objcMembers public final class TinykitKeepAwake: NSObject {
  public static func activate() {
    DispatchQueue.main.async {
      UIApplication.shared.isIdleTimerDisabled = true
    }
  }

  public static func deactivate() {
    DispatchQueue.main.async {
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }
}
