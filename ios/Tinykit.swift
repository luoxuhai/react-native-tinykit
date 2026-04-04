import Foundation
import React
import StoreKit

@objcMembers public class NativeTinykit: NSObject {
  public var onThermalStateChange: ((String) -> Void)?

  public init(onThermalStateChange: @escaping ((String) -> Void)) {
    super.init()
    self.onThermalStateChange = onThermalStateChange
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleThermalStateChange),
      name: ProcessInfo.thermalStateDidChangeNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  public func getThermalState() -> String {
    return thermalStateToString(ProcessInfo.processInfo.thermalState)
  }

  public func restart() {
    DispatchQueue.main.async {
      RCTTriggerReloadCommandListeners("react-native-tinykit")
    }
  }

  public func requestReview(
    resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock
  ) {
    let activeWindowScene = UIApplication.shared.connectedScenes.filter { scene in
      return scene.activationState == .foregroundActive && scene is UIWindowScene
    }.first

    if let scene = activeWindowScene as? UIWindowScene {
      if #available(iOS 16.0, *) {
        Task {
          await MainActor.run {
            AppStore.requestReview(in: scene)
            resolve(nil)
          }
        }
      } else {
        SKStoreReviewController.requestReview(in: scene)
        resolve(nil)
      }
    } else {
      SKStoreReviewController.requestReview()
      resolve(nil)
    }
  }

  public func activateKeepAwake() {
    DispatchQueue.main.async {
      UIApplication.shared.isIdleTimerDisabled = true
    }
  }

  public func deactivateKeepAwake() {
    DispatchQueue.main.async {
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }

  @objc private func handleThermalStateChange() {
    let state = getThermalState()
    onThermalStateChange?(state)
  }

  public func impact(style: String) {
    DispatchQueue.main.async {
      let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
      switch style {
      case "light":
        feedbackStyle = .light
      case "medium":
        feedbackStyle = .medium
      case "heavy":
        feedbackStyle = .heavy
      case "soft":
        feedbackStyle = .soft
      case "rigid":
        feedbackStyle = .rigid
      default:
        feedbackStyle = .medium
      }
      let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
      generator.prepare()
      generator.impactOccurred()
    }
  }

  public func selection() {
    DispatchQueue.main.async {
      let generator = UISelectionFeedbackGenerator()
      generator.prepare()
      generator.selectionChanged()
    }
  }

  public func notification(type: String) {
    DispatchQueue.main.async {
      let feedbackType: UINotificationFeedbackGenerator.FeedbackType
      switch type {
      case "success":
        feedbackType = .success
      case "warning":
        feedbackType = .warning
      case "error":
        feedbackType = .error
      default:
        feedbackType = .success
      }
      let generator = UINotificationFeedbackGenerator()
      generator.prepare()
      generator.notificationOccurred(feedbackType)
    }
  }

  private func thermalStateToString(_ state: ProcessInfo.ThermalState) -> String {
    switch state {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "nominal"
    }
  }
}
