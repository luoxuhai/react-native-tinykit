import React

@objcMembers public final class TinykitRestart: NSObject {
  public static func restart() {
    DispatchQueue.main.async {
      RCTTriggerReloadCommandListeners("react-native-tinykit")
    }
  }
}
