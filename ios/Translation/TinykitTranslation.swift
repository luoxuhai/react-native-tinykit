import React
import SwiftUI
import Translation
import UIKit

// Migration of react-native-ios-translation (MIT; see LICENSE).
// The system UI is hosted through Apple's public SwiftUI API.
@objcMembers @MainActor public final class TinykitTranslation: NSObject {
  private var state: TranslationPresentationState?
  private var host: UIViewController?
  private var resolve: RCTPromiseResolveBlock?
  private var reject: RCTPromiseRejectBlock?
  private var dismissResolvers: [RCTPromiseResolveBlock] = []

  nonisolated public static func isSupported() -> Bool {
    #if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
    return false
    #else
    if #available(iOS 17.4, *) { return true }
    return false
    #endif
  }

  public func show(
    _ options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    guard Self.isSupported() else {
      reject("E_TRANSLATION_UNAVAILABLE", "Translation requires a physical iOS device running iOS 17.4 or later.", nil)
      return
    }
    guard state == nil else {
      reject("E_TRANSLATION_ALREADY_PRESENTED", "A translation panel is already open.", nil)
      return
    }
    guard let text = options["text"] as? String,
          !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      reject("E_TRANSLATION_INVALID_TEXT", "Translation text must be a non-empty string.", nil)
      return
    }
    guard let presenter = RCTPresentedViewController(),
          let window = presenter.viewIfLoaded?.window,
          !presenter.isBeingDismissed,
          !presenter.isBeingPresented else {
      reject("E_TRANSLATION_NO_PRESENTER", "Unable to find a visible view controller for translation.", nil)
      return
    }

    let bounds = presenter.view.bounds
    var frame = CGRect(x: bounds.midX, y: bounds.midY, width: 1, height: 1)
    if let anchor = options["anchor"] as? NSDictionary {
      guard let x = anchor["x"] as? Double, let y = anchor["y"] as? Double,
            let width = anchor["width"] as? Double, let height = anchor["height"] as? Double,
            [x, y, width, height].allSatisfy({ $0.isFinite }), width > 0, height > 0 else {
        reject("E_TRANSLATION_INVALID_ANCHOR", "Translation anchor must be a finite rectangle with positive dimensions.", nil)
        return
      }
      frame = presenter.view.convert(CGRect(x: x, y: y, width: width, height: height), from: window)
        .intersection(bounds)
      guard !frame.isNull, !frame.isEmpty else {
        reject("E_TRANSLATION_INVALID_ANCHOR", "The translation target is outside the visible view.", nil)
        return
      }
    }

    #if !targetEnvironment(macCatalyst)
    if #available(iOS 17.4, *) {
      let state = TranslationPresentationState()
      let edge: Edge
      switch options["arrowEdge"] as? String {
      case "bottom": edge = .bottom
      case "leading": edge = .leading
      case "trailing": edge = .trailing
      default: edge = .top
      }
      let finish = { [weak self, weak state] in
        guard let state else { return }
        // The system can update the binding before invoking replacementAction.
        DispatchQueue.main.async { self?.finish(state) }
      }
      let view = TranslationPresentationView(
        state: state,
        text: text,
        arrowEdge: edge,
        allowsReplacement: options["allowsReplacement"] as? Bool ?? false,
        onFinish: finish
      )
      let host = TranslationHostingController(rootView: view)
      host.onParentDismissed = finish
      self.state = state
      self.host = host
      self.resolve = resolve
      self.reject = reject

      presenter.addChild(host)
      host.view.backgroundColor = .clear
      host.view.frame = frame
      host.view.isUserInteractionEnabled = false
      presenter.view.addSubview(host.view)
      host.didMove(toParent: presenter)
    }
    #endif
  }

  public func dismiss(_ resolve: @escaping RCTPromiseResolveBlock) {
    guard let state else {
      resolve(nil)
      return
    }
    dismissResolvers.append(resolve)
    finish(state)
  }

  public func invalidate() {
    reject?("E_TRANSLATION_CANCELLED", "The translation module was invalidated.", nil)
    resolve = nil
    reject = nil
    if let state { finish(state) }
  }

  private func finish(_ state: TranslationPresentationState) {
    guard self.state === state, !state.finished else { return }
    state.finished = true
    state.isPresented = false
    let complete = { [self] in
      guard self.state === state else { return }
      host?.willMove(toParent: nil)
      host?.view.removeFromSuperview()
      host?.removeFromParent()
      host = nil
      self.state = nil
      let resolve = self.resolve
      self.resolve = nil
      reject = nil
      let dismissResolvers = self.dismissResolvers
      self.dismissResolvers = []
      if let translatedText = state.translatedText {
        resolve?(["status": "replaced", "translatedText": translatedText])
      } else {
        resolve?(["status": "dismissed"])
      }
      dismissResolvers.forEach { $0(nil) }
    }
    // Only dismiss the controller belonging to this host, never unrelated UI.
    if let presented = host?.presentedViewController {
      if presented.isBeingDismissed, let transition = presented.transitionCoordinator {
        let scheduled = transition.animate(alongsideTransition: nil) { _ in complete() }
        if !scheduled { complete() }
      } else {
        presented.dismiss(animated: true, completion: complete)
      }
    } else {
      complete()
    }
  }
}

@MainActor private final class TranslationPresentationState: ObservableObject {
  @Published var isPresented = false
  var finished = false
  var translatedText: String?
}

#if !targetEnvironment(macCatalyst)
@available(iOS 17.4, *)
private struct TranslationPresentationView: View {
  @ObservedObject var state: TranslationPresentationState
  let text: String
  let arrowEdge: Edge
  let allowsReplacement: Bool
  let onFinish: () -> Void

  var body: some View {
    Color.clear
      .translationPresentation(
        isPresented: $state.isPresented,
        text: text,
        attachmentAnchor: .rect(.bounds),
        arrowEdge: arrowEdge,
        replacementAction: allowsReplacement ? { translatedText in
          state.translatedText = translatedText
          state.isPresented = false
          onFinish()
        } : nil
      )
      .onAppear {
        // Presentation must start after the host has entered the view hierarchy.
        DispatchQueue.main.async {
          if !state.finished { state.isPresented = true }
        }
      }
      .onChange(of: state.isPresented) { _, presented in
        if !presented { onFinish() }
      }
  }
}

@available(iOS 17.4, *)
private final class TranslationHostingController: UIHostingController<TranslationPresentationView> {
  var onParentDismissed: (() -> Void)?

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    // A parent RN modal can close while its translation panel is open.
    var ancestor = parent
    while let controller = ancestor {
      if controller.isBeingDismissed || controller.isMovingFromParent {
        onParentDismissed?()
        break
      }
      ancestor = controller.parent
    }
  }
}
#endif
