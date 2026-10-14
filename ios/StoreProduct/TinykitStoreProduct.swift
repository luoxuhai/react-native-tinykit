import React
import StoreKit
import UIKit

@objcMembers @MainActor public final class TinykitStoreProduct: NSObject {
  private var product: SKStoreProductViewController?
  private var resolve: RCTPromiseResolveBlock?
  private var reject: RCTPromiseRejectBlock?
  private var dismissResolvers: [RCTPromiseResolveBlock] = []
  private var isPresenting = false
  private var dismissRequested = false
  private var isInvalidated = false

  public func show(
    _ options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    guard !isInvalidated else {
      reject("E_STORE_PRODUCT_CANCELLED", "The StoreProduct module was invalidated.", nil)
      return
    }
    guard product == nil else {
      reject("E_STORE_PRODUCT_ALREADY_PRESENTED", "A store product page is already loading or presented.", nil)
      return
    }
    guard let appId = options["appId"] as? String,
          !appId.isEmpty, appId.utf8.allSatisfy({ (48...57).contains($0) }),
          let identifier = UInt64(appId), identifier > 0 else {
      reject("E_STORE_PRODUCT_INVALID_OPTIONS", "appId must be a positive numeric App Store ID.", nil)
      return
    }
    guard Self.presenter() != nil else {
      reject("E_STORE_PRODUCT_NO_PRESENTER", "Unable to find a visible view controller for the store product page.", nil)
      return
    }

    var parameters: [String: Any] = [SKStoreProductParameterITunesItemIdentifier: NSNumber(value: identifier)]
    for (option, parameter) in [
      ("affiliateToken", SKStoreProductParameterAffiliateToken),
      ("campaignToken", SKStoreProductParameterCampaignToken),
      ("providerToken", SKStoreProductParameterProviderToken),
    ] {
      if let value = options[option] {
        guard let token = value as? String,
              !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          reject("E_STORE_PRODUCT_INVALID_OPTIONS", "\(option) must be a non-empty string.", nil)
          return
        }
        parameters[parameter] = token
      }
    }

    let product = SKStoreProductViewController()
    product.delegate = self
    self.product = product
    self.resolve = resolve
    self.reject = reject

    product.loadProduct(withParameters: parameters) { [weak self, weak product] loaded, error in
      DispatchQueue.main.async {
        guard let self, let product, self.product === product else { return }
        guard loaded, error == nil else {
          self.reject?("E_STORE_PRODUCT_LOAD_FAILED", error?.localizedDescription ?? "Unable to load the store product page.", error)
          self.finish(product, resolvePresentation: false)
          return
        }
        guard let presenter = Self.presenter() else {
          self.reject?("E_STORE_PRODUCT_NO_PRESENTER", "The presenting view controller is no longer visible.", nil)
          self.finish(product, resolvePresentation: false)
          return
        }

        self.isPresenting = true
        product.presentationController?.delegate = self
        // Keep the helper alive through the animation so invalidation can still close the page.
        presenter.present(product, animated: true) { [self, weak product] in
          guard let product, self.product === product else { return }
          self.isPresenting = false
          product.presentationController?.delegate = self
          guard product.presentingViewController != nil else {
            self.reject?("E_STORE_PRODUCT_NO_PRESENTER", "The store product page could not be presented.", nil)
            self.finish(product, resolvePresentation: false)
            return
          }
          if self.dismissRequested { self.close(product) }
        }
      }
    }
  }

  public func dismiss(_ resolve: @escaping RCTPromiseResolveBlock) {
    guard let product else {
      resolve(nil)
      return
    }
    dismissResolvers.append(resolve)
    dismissRequested = true
    close(product)
  }

  public func invalidate() {
    isInvalidated = true
    reject?("E_STORE_PRODUCT_CANCELLED", "The StoreProduct module was invalidated.", nil)
    resolve = nil
    reject = nil
    let dismissResolvers = self.dismissResolvers
    self.dismissResolvers = []
    dismissResolvers.forEach { $0(nil) }
    dismissRequested = true
    if let product { close(product) }
  }

  private static func presenter() -> UIViewController? {
    guard let presenter = RCTPresentedViewController(),
          presenter.viewIfLoaded?.window != nil,
          !presenter.isBeingPresented, !presenter.isBeingDismissed,
          presenter.presentedViewController == nil else { return nil }
    return presenter
  }

  private func close(_ product: SKStoreProductViewController) {
    guard self.product === product, !isPresenting else { return }
    guard product.presentingViewController != nil else {
      // Cancelling a load clears identity; a late load completion cannot present it.
      finish(product)
      return
    }
    guard !product.isBeingDismissed else { return }
    product.dismiss(animated: !isInvalidated) { [self] in finish(product) }
  }

  private func finish(_ product: SKStoreProductViewController, resolvePresentation: Bool = true) {
    guard self.product === product else { return }
    let resolve = self.resolve
    let dismissResolvers = self.dismissResolvers
    product.delegate = nil
    product.presentationController?.delegate = nil
    self.product = nil
    self.resolve = nil
    reject = nil
    self.dismissResolvers = []
    isPresenting = false
    dismissRequested = false
    if resolvePresentation { resolve?(nil) }
    dismissResolvers.forEach { $0(nil) }
  }
}

extension TinykitStoreProduct: SKStoreProductViewControllerDelegate {
  public nonisolated func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
    DispatchQueue.main.async { [self] in
      guard product === viewController else { return }
      dismissRequested = true
      close(viewController)
    }
  }
}

extension TinykitStoreProduct: UIAdaptivePresentationControllerDelegate {
  public nonisolated func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    DispatchQueue.main.async { [self] in
      guard let product, presentationController.presentedViewController === product else { return }
      finish(product)
    }
  }
}
