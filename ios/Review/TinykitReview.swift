import React
import StoreKit
import UIKit

@objcMembers public final class TinykitReview: NSObject {
  public static func requestReview(
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: RCTPromiseRejectBlock
  ) {
    let activeWindowScene = UIApplication.shared.connectedScenes.first { scene in
      scene.activationState == .foregroundActive && scene is UIWindowScene
    }

    if let scene = activeWindowScene as? UIWindowScene {
      Task {
        await MainActor.run {
          AppStore.requestReview(in: scene)
          resolve(nil)
        }
      }
    } else {
      SKStoreReviewController.requestReview()
      resolve(nil)
    }
  }
}
