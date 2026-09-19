import React
import SPConfetti
import UIKit

@objcMembers @MainActor public final class TinykitConfetti: NSObject {
  private var stopWork: DispatchWorkItem?

  public func start(
    _ options: NSDictionary,
    resolve: RCTPromiseResolveBlock,
    rejecter reject: RCTPromiseRejectBlock
  ) {
    let duration = options["duration"] as? Double ?? 2000
    guard duration.isFinite && duration >= 0 else {
      reject(
        "E_CONFETTI_INVALID_DURATION",
        "Confetti duration must be a finite, non-negative number.",
        nil
      )
      return
    }
    guard let window = RCTKeyWindow() else {
      reject("E_CONFETTI_NO_WINDOW", "Unable to find a window to present confetti.", nil)
      return
    }

    stopWork?.cancel()
    SPConfetti.startAnimating(
      .fullWidthToDown,
      particles: [.arc, .star, .heart, .triangle],
      in: window
    )

    // Own the timer so an earlier start cannot stop a later animation.
    let work = DispatchWorkItem { [weak self] in self?.stop() }
    stopWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + duration / 1000, execute: work)
    resolve(nil)
  }

  public func stop() {
    stopWork?.cancel()
    stopWork = nil
    SPConfetti.stopAnimating()
  }
}
