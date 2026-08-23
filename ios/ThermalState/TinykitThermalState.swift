import Foundation

@objcMembers public final class TinykitThermalState: NSObject {
  public var onThermalStateChange: ((String) -> Void)?

  public init(onThermalStateChange: @escaping ((String) -> Void)) {
    self.onThermalStateChange = onThermalStateChange
    super.init()

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

  public static func currentState() -> String {
    return thermalStateToString(ProcessInfo.processInfo.thermalState)
  }

  @objc private func handleThermalStateChange() {
    onThermalStateChange?(Self.currentState())
  }

  private static func thermalStateToString(_ state: ProcessInfo.ThermalState) -> String {
    switch state {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "nominal"
    }
  }
}
