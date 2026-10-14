import React
import StoreKit
import UIKit

@objcMembers @MainActor public final class TinykitStoreOverlay: NSObject {
  private var currentSession: StoreOverlaySession?
  private var isInvalidated = false

  public func show(
    _ options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    guard !isInvalidated else {
      reject("E_STORE_OVERLAY_UNAVAILABLE", "TinyKit is unavailable.", nil)
      return
    }

    guard currentSession == nil else {
      reject("E_STORE_OVERLAY_ALREADY_PRESENTED", "A store overlay is already active.", nil)
      return
    }

    guard let appId = options["appId"] as? String,
      !appId.isEmpty,
      appId.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }),
      let identifier = UInt64(appId), identifier > 0
    else {
      reject("E_STORE_OVERLAY_INVALID_OPTIONS", "appId must be a positive numeric string.", nil)
      return
    }

    let position: SKOverlay.Position
    switch options["position"] {
    case nil:
      position = .bottom
    case let value as String where value == "bottom":
      position = .bottom
    case let value as String where value == "bottomRaised":
      position = .bottomRaised
    default:
      reject(
        "E_STORE_OVERLAY_INVALID_OPTIONS",
        "position must be 'bottom' or 'bottomRaised'.",
        nil
      )
      return
    }

    if let value = options["userDismissible"], !(value is Bool) {
      reject("E_STORE_OVERLAY_INVALID_OPTIONS", "userDismissible must be a boolean.", nil)
      return
    }

    for key in ["campaignToken", "providerToken"] {
      if let value = options[key] {
        guard let token = value as? String,
          !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
          reject("E_STORE_OVERLAY_INVALID_OPTIONS", "\(key) must be a non-empty string.", nil)
          return
        }
      }
    }

    #if targetEnvironment(simulator)
      reject(
        "E_STORE_OVERLAY_UNAVAILABLE",
        "Store overlays are not supported in the iOS Simulator. Use a physical device.",
        nil
      )
    #else
      guard let scene = Self.activeWindowScene() else {
        reject(
          "E_STORE_OVERLAY_NO_WINDOW_SCENE",
          "Unable to find an active window scene to present the store overlay.",
          nil
        )
        return
      }

      let configuration = SKOverlay.AppConfiguration(appIdentifier: appId, position: position)
      configuration.userDismissible = options["userDismissible"] as? Bool ?? true
      configuration.campaignToken = options["campaignToken"] as? String
      configuration.providerToken = options["providerToken"] as? String

      let session = StoreOverlaySession(
        configuration: configuration,
        scene: scene,
        resolve: resolve,
        reject: reject
      ) { [weak self] in
        self?.currentSession = nil
      }
      currentSession = session
      session.present()
    #endif
  }

  public func dismiss(_ resolve: RCTPromiseResolveBlock) {
    currentSession?.cancel(
      code: "E_STORE_OVERLAY_CANCELLED",
      message: "The store overlay was dismissed before presentation finished."
    )
    // Resolve once the request is recorded; native dismissal may wait for presentation.
    resolve(nil)
  }

  public func invalidate() {
    isInvalidated = true
    currentSession?.cancel(
      code: "E_STORE_OVERLAY_CANCELLED",
      message: "TinyKit was invalidated before the store overlay finished presenting."
    )
    currentSession = nil
  }

  private static func activeWindowScene() -> UIWindowScene? {
    if let scene = RCTPresentedViewController()?.viewIfLoaded?.window?.windowScene,
      scene.activationState == .foregroundActive {
      return scene
    }

    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
    return scenes.first { $0.windows.contains(where: \.isKeyWindow) } ?? scenes.first
  }
}

@MainActor private final class StoreOverlaySession: NSObject {
  private let overlay: SKOverlay
  private let scene: UIWindowScene
  private var showResolve: RCTPromiseResolveBlock?
  private var showReject: RCTPromiseRejectBlock?
  private var onFinish: (() -> Void)?
  private var isCancelled = false
  private var isFinished = false
  private var hasFinishedPresentation = false
  private var retainedCancellation: StoreOverlaySession?
  private var sceneDisconnectObserver: NSObjectProtocol?

  init(
    configuration: SKOverlay.AppConfiguration,
    scene: UIWindowScene,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock,
    onFinish: @escaping () -> Void
  ) {
    overlay = SKOverlay(configuration: configuration)
    self.scene = scene
    showResolve = resolve
    showReject = reject
    self.onFinish = onFinish
    super.init()
    overlay.delegate = self
    sceneDisconnectObserver = NotificationCenter.default.addObserver(
      forName: UIScene.didDisconnectNotification,
      object: scene,
      queue: .main
    ) { [weak self] _ in
      DispatchQueue.main.async { self?.finish() }
    }
  }

  func present() {
    overlay.present(in: scene)
  }

  func cancel(code: String, message: String) {
    guard !isFinished else { return }

    isCancelled = true
    // The delegate is weak. Keep cancellation alive across bridge invalidation so a late
    // presentation can be dismissed after StoreKit finishes its in-flight load/animation.
    retainedCancellation = self
    let reject = showReject
    showResolve = nil
    showReject = nil
    // Dismissing during loading has no guaranteed terminal callback. Wait until
    // presentation finishes, then dismiss the retained overlay in its original scene.
    if hasFinishedPresentation { SKOverlay.dismiss(in: scene) }
    reject?(code, message, nil)
  }

  private func finish(error: Error? = nil) {
    guard !isFinished else { return }
    isFinished = true

    let reject = showReject
    let completion = onFinish
    showResolve = nil
    showReject = nil
    onFinish = nil
    overlay.delegate = nil
    if let sceneDisconnectObserver {
      NotificationCenter.default.removeObserver(sceneDisconnectObserver)
    }
    sceneDisconnectObserver = nil
    retainedCancellation = nil
    completion?()

    if let error {
      reject?("E_STORE_OVERLAY_LOAD_FAILED", error.localizedDescription, error)
    } else {
      reject?(
        "E_STORE_OVERLAY_CANCELLED",
        "The store overlay was dismissed before presentation finished.",
        nil
      )
    }
  }
}

extension StoreOverlaySession: SKOverlayDelegate {
  nonisolated func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: Error) {
    let identifier = ObjectIdentifier(overlay)
    DispatchQueue.main.async { [self] in
      guard identifier == ObjectIdentifier(self.overlay) else { return }
      finish(error: error)
    }
  }

  nonisolated func storeOverlayDidFinishPresentation(
    _ overlay: SKOverlay,
    transitionContext: SKOverlay.TransitionContext
  ) {
    let identifier = ObjectIdentifier(overlay)
    DispatchQueue.main.async { [self] in
      guard identifier == ObjectIdentifier(self.overlay), !isFinished else { return }
      hasFinishedPresentation = true
      if isCancelled {
        SKOverlay.dismiss(in: scene)
        return
      }

      let resolve = showResolve
      showResolve = nil
      showReject = nil
      resolve?(nil)
    }
  }

  nonisolated func storeOverlayDidFinishDismissal(
    _ overlay: SKOverlay,
    transitionContext: SKOverlay.TransitionContext
  ) {
    let identifier = ObjectIdentifier(overlay)
    DispatchQueue.main.async { [self] in
      guard identifier == ObjectIdentifier(self.overlay) else { return }
      finish()
    }
  }
}
