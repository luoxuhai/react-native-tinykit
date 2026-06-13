import Foundation
import React
import StoreKit
import UIKit

@objcMembers public class NativeTinykit: NSObject {
  public var onThermalStateChange: ((String) -> Void)?
  private var colorPickerResolve: RCTPromiseResolveBlock?
  private var colorPickerReject: RCTPromiseRejectBlock?
  private weak var currentColorPicker: UIColorPickerViewController?
  private weak var colorPickerDoneButton: UIButton?

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

  public func showColorPicker(
    _ options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        reject("E_COLOR_PICKER_UNAVAILABLE", "Tinykit is unavailable.", nil)
        return
      }

      guard self.colorPickerResolve == nil else {
        reject("E_COLOR_PICKER_ALREADY_PRESENTED", "A color picker is already presented.", nil)
        return
      }

      guard let presenter = RCTPresentedViewController() else {
        reject("E_COLOR_PICKER_NO_PRESENTING_VIEW_CONTROLLER", "Unable to find a view controller to present the color picker.", nil)
        return
      }

      let picker = UIColorPickerViewController()
      picker.delegate = self

      if let selectedColor = options["selectedColor"] as? String {
        guard let color = Self.color(fromHexString: selectedColor) else {
          reject("E_COLOR_PICKER_INVALID_COLOR", "selectedColor must be a valid hex color string.", nil)
          return
        }
        picker.selectedColor = color
      }

      if let supportsAlpha = options["supportsAlpha"] as? Bool {
        picker.supportsAlpha = supportsAlpha
      } else {
        picker.supportsAlpha = true
      }

      if let supportsEyedropper = options["supportsEyedropper"] as? Bool {
        Self.setValueIfSupported(supportsEyedropper, forKey: "supportsEyedropper", on: picker)
      }

      if let maximumLinearExposure = options["maximumLinearExposure"] as? NSNumber {
        Self.setValueIfSupported(maximumLinearExposure, forKey: "maximumLinearExposure", on: picker)
      }

      if let title = options["title"] as? String {
        picker.title = title
      }

      if let detentError = Self.configureColorPickerSheetPresentation(for: picker, options: options) {
        reject("E_COLOR_PICKER_INVALID_DETENTS", detentError, nil)
        return
      }

      self.colorPickerResolve = resolve
      self.colorPickerReject = reject
      self.currentColorPicker = picker

      let showDoneButton = options["showDoneButton"] as? Bool ?? false

      if showDoneButton {
        let doneButtonTitle = options["doneButtonTitle"] as? String ?? "Done"
        self.installColorPickerDoneButton(title: doneButtonTitle, on: picker)
      }

      picker.presentationController?.delegate = self
      presenter.present(picker, animated: true) { [weak self, weak picker] in
        picker?.presentationController?.delegate = self
      }
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

  @objc private func handleColorPickerDone() {
    guard let picker = currentColorPicker else {
      resolveColorPicker(with: UIColor.clear)
      return
    }

    let color = picker.selectedColor
    picker.dismiss(animated: true) { [weak self] in
      self?.resolveColorPicker(with: color)
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

  private func resolveColorPicker(with color: UIColor) {
    guard let resolve = colorPickerResolve else {
      resetColorPickerState()
      return
    }

    resolve(Self.colorResult(from: color))
    resetColorPickerState()
  }

  private func resetColorPickerState() {
    colorPickerResolve = nil
    colorPickerReject = nil
    colorPickerDoneButton?.removeFromSuperview()
    colorPickerDoneButton = nil
    currentColorPicker?.delegate = nil
    currentColorPicker = nil
  }

  private func installColorPickerDoneButton(title: String, on picker: UIColorPickerViewController) {
    picker.loadViewIfNeeded()

    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title.isEmpty ? "Done" : title, for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 17)
    button.backgroundColor = .systemBackground
    button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    button.addTarget(self, action: #selector(handleColorPickerDone), for: .touchUpInside)

    picker.view.addSubview(button)

    NSLayoutConstraint.activate([
      button.trailingAnchor.constraint(equalTo: picker.view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      button.topAnchor.constraint(equalTo: picker.view.safeAreaLayoutGuide.topAnchor, constant: 6),
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
    ])

    colorPickerDoneButton = button
  }

  private static func configureColorPickerSheetPresentation(
    for picker: UIColorPickerViewController,
    options: NSDictionary
  ) -> String? {
    let hasSheetOptions =
      options["detents"] != nil ||
      options["selectedDetentIdentifier"] != nil ||
      options["largestUndimmedDetentIdentifier"] != nil ||
      options["prefersGrabberVisible"] != nil

    guard hasSheetOptions else {
      return nil
    }

    picker.modalPresentationStyle = .pageSheet

    guard let sheet = picker.sheetPresentationController else {
      return nil
    }

    if let rawDetents = options["detents"] as? NSArray {
      guard rawDetents.count > 0 else {
        return "detents must contain at least one detent."
      }

      var detents: [UISheetPresentationController.Detent] = []
      detents.reserveCapacity(rawDetents.count)

      for index in 0..<rawDetents.count {
        guard let detentOptions = rawDetents[index] as? NSDictionary else {
          return "Each detent must be an object."
        }

        let result = Self.colorPickerSheetDetent(from: detentOptions, at: index)
        if let error = result.error {
          return error
        }

        if let detent = result.detent {
          detents.append(detent)
        }
      }

      sheet.detents = detents
    }

    if let selectedDetentIdentifier = Self.nonEmptyString(options["selectedDetentIdentifier"]) {
      sheet.selectedDetentIdentifier = Self.colorPickerSheetDetentIdentifier(from: selectedDetentIdentifier)
    }

    if let largestUndimmedDetentIdentifier = Self.nonEmptyString(options["largestUndimmedDetentIdentifier"]) {
      sheet.largestUndimmedDetentIdentifier = Self.colorPickerSheetDetentIdentifier(from: largestUndimmedDetentIdentifier)
    }

    if let prefersGrabberVisible = options["prefersGrabberVisible"] as? Bool {
      sheet.prefersGrabberVisible = prefersGrabberVisible
    }

    return nil
  }

  private static func colorPickerSheetDetent(
    from options: NSDictionary,
    at index: Int
  ) -> (detent: UISheetPresentationController.Detent?, error: String?) {
    let type = (Self.nonEmptyString(options["type"]) ?? "custom").lowercased()

    switch type {
    case "medium":
      return (.medium(), nil)
    case "large":
      return (.large(), nil)
    case "custom":
      return Self.customColorPickerSheetDetent(from: options, at: index)
    default:
      return (nil, "detents[\(index)].type must be 'medium', 'large', or 'custom'.")
    }
  }

  private static func customColorPickerSheetDetent(
    from options: NSDictionary,
    at index: Int
  ) -> (detent: UISheetPresentationController.Detent?, error: String?) {
    let height = (options["height"] as? NSNumber).map { CGFloat($0.doubleValue) }
    let fraction = (options["fraction"] as? NSNumber).map { CGFloat($0.doubleValue) }

    guard height != nil || fraction != nil else {
      return (nil, "Custom detents must set height or fraction.")
    }

    if let height, height <= 0 {
      return (nil, "Custom detent height must be greater than 0.")
    }

    if let fraction, fraction <= 0 || fraction > 1 {
      return (nil, "Custom detent fraction must be greater than 0 and less than or equal to 1.")
    }

    let identifier = Self.nonEmptyString(options["identifier"])
      ?? Self.generatedColorPickerDetentIdentifier(height: height, fraction: fraction, index: index)

    let detent = UISheetPresentationController.Detent.custom(
      identifier: UISheetPresentationController.Detent.Identifier(identifier)
    ) { context in
      if let height {
        return min(height, context.maximumDetentValue)
      }

      return context.maximumDetentValue * (fraction ?? 1)
    }

    return (detent, nil)
  }

  private static func colorPickerSheetDetentIdentifier(
    from value: String
  ) -> UISheetPresentationController.Detent.Identifier {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "medium":
      return .medium
    case "large":
      return .large
    default:
      return UISheetPresentationController.Detent.Identifier(value)
    }
  }

  private static func generatedColorPickerDetentIdentifier(
    height: CGFloat?,
    fraction: CGFloat?,
    index: Int
  ) -> String {
    if let height {
      return "height-\(Int(round(height)))-\(index)"
    }

    if let fraction {
      return "fraction-\(Int(round(fraction * 1000)))-\(index)"
    }

    return "custom-\(index)"
  }

  private static func nonEmptyString(_ value: Any?) -> String? {
    guard let string = value as? String else {
      return nil
    }

    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private static func setValueIfSupported(_ value: Any, forKey key: String, on object: NSObject) {
    let setterName = "set" + key.prefix(1).uppercased() + key.dropFirst() + ":"
    guard object.responds(to: NSSelectorFromString(setterName)) else {
      return
    }

    object.setValue(value, forKey: key)
  }

  private static func color(fromHexString hexString: String) -> UIColor? {
    let trimmed = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    let hex = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed

    let expandedHex: String
    switch hex.count {
    case 3:
      expandedHex = hex.map { "\($0)\($0)" }.joined() + "FF"
    case 4:
      expandedHex = hex.map { "\($0)\($0)" }.joined()
    case 6:
      expandedHex = hex + "FF"
    case 8:
      expandedHex = hex
    default:
      return nil
    }

    guard let value = UInt32(expandedHex, radix: 16) else {
      return nil
    }

    let red = CGFloat((value >> 24) & 0xFF) / 255.0
    let green = CGFloat((value >> 16) & 0xFF) / 255.0
    let blue = CGFloat((value >> 8) & 0xFF) / 255.0
    let alpha = CGFloat(value & 0xFF) / 255.0

    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private static func colorResult(from color: UIColor) -> NSDictionary {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    if !color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
      let ciColor = CIColor(color: color)
      red = ciColor.red
      green = ciColor.green
      blue = ciColor.blue
      alpha = ciColor.alpha
    }

    let clampedRed = clampColorComponent(red)
    let clampedGreen = clampColorComponent(green)
    let clampedBlue = clampColorComponent(blue)
    let clampedAlpha = clampColorComponent(alpha)

    return [
      "color": String(
        format: "#%02X%02X%02X%02X",
        Int(round(clampedRed * 255)),
        Int(round(clampedGreen * 255)),
        Int(round(clampedBlue * 255)),
        Int(round(clampedAlpha * 255))
      ),
      "red": Double(clampedRed),
      "green": Double(clampedGreen),
      "blue": Double(clampedBlue),
      "alpha": Double(clampedAlpha),
    ]
  }

  private static func clampColorComponent(_ value: CGFloat) -> CGFloat {
    return min(max(value, 0), 1)
  }
}

extension NativeTinykit: UIColorPickerViewControllerDelegate {
  public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
    resolveColorPicker(with: viewController.selectedColor)
  }
}

extension NativeTinykit: UIAdaptivePresentationControllerDelegate {
  public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    guard let picker = currentColorPicker else {
      resetColorPickerState()
      return
    }

    resolveColorPicker(with: picker.selectedColor)
  }
}
