import MessageUI
import React
import UIKit
import UniformTypeIdentifiers

@objcMembers @MainActor public final class TinykitMail: NSObject {
  private struct PreparedAttachment {
    let data: Data
    let mimeType: String
    let fileName: String
  }

  private struct AttachmentError: Error {
    let code: String
    let message: String
  }

  private var mailResolve: RCTPromiseResolveBlock?
  private var mailReject: RCTPromiseRejectBlock?
  private weak var currentComposer: MFMailComposeViewController?

  public static func canSendMail() -> Bool {
    MFMailComposeViewController.canSendMail()
  }

  public func openMail(
    _ options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    guard mailResolve == nil else {
      reject("E_MAIL_ALREADY_PRESENTED", "A mail composer is already presented.", nil)
      return
    }

    guard Self.canSendMail() else {
      reject(
        "E_MAIL_UNAVAILABLE",
        "This device is not configured to send mail.",
        nil
      )
      return
    }

    guard let presenter = RCTPresentedViewController() else {
      reject(
        "E_MAIL_NO_PRESENTING_VIEW_CONTROLLER",
        "Unable to find a view controller to present the mail composer.",
        nil
      )
      return
    }

    let attachments: [PreparedAttachment]
    do {
      attachments = try Self.prepareAttachments(from: options)
    } catch let error as AttachmentError {
      reject(error.code, error.message, error)
      return
    } catch {
      reject("E_MAIL_ATTACHMENT_UNREADABLE", error.localizedDescription, error)
      return
    }

    let composer = MFMailComposeViewController()
    composer.mailComposeDelegate = self

    if let recipients = options["recipients"] as? [String] {
      composer.setToRecipients(recipients)
    }
    if let ccRecipients = options["ccRecipients"] as? [String] {
      composer.setCcRecipients(ccRecipients)
    }
    if let bccRecipients = options["bccRecipients"] as? [String] {
      composer.setBccRecipients(bccRecipients)
    }
    if let subject = options["subject"] as? String {
      composer.setSubject(subject)
    }
    if let body = options["body"] as? String {
      composer.setMessageBody(body, isHTML: options["isHTML"] as? Bool ?? false)
    }

    for attachment in attachments {
      composer.addAttachmentData(
        attachment.data,
        mimeType: attachment.mimeType,
        fileName: attachment.fileName
      )
    }

    mailResolve = resolve
    mailReject = reject
    currentComposer = composer
    presenter.present(composer, animated: true)
  }

  private static func prepareAttachments(from options: NSDictionary) throws -> [PreparedAttachment] {
    guard let rawAttachments = options["attachments"] as? [NSDictionary] else {
      return []
    }

    return try rawAttachments.enumerated().map { index, attachment in
      guard let url = attachmentURL(from: attachment) else {
        throw AttachmentError(
          code: "E_MAIL_ATTACHMENT_INVALID",
          message: "attachments[\(index)] must provide a local path or file URI."
        )
      }

      guard url.isFileURL else {
        throw AttachmentError(
          code: "E_MAIL_ATTACHMENT_INVALID",
          message: "attachments[\(index)] must reference a local file."
        )
      }

      let data: Data
      do {
        data = try Data(contentsOf: url, options: .mappedIfSafe)
      } catch {
        throw AttachmentError(
          code: "E_MAIL_ATTACHMENT_UNREADABLE",
          message: "Unable to read attachments[\(index)] at \(url.path): \(error.localizedDescription)"
        )
      }

      let fileName = nonEmptyString(attachment["name"])
        ?? nonEmptyString(url.lastPathComponent)
        ?? "attachment"

      return PreparedAttachment(
        data: data,
        mimeType: attachmentMimeType(from: attachment, fileName: fileName, url: url),
        fileName: fileName
      )
    }
  }

  private static func attachmentURL(from attachment: NSDictionary) -> URL? {
    if let path = nonEmptyString(attachment["path"]) {
      if path.hasPrefix("file://") {
        return URL(string: path)
      }
      return URL(fileURLWithPath: path)
    }

    guard let uri = nonEmptyString(attachment["uri"]) else {
      return nil
    }

    if let url = URL(string: uri), url.scheme != nil {
      return url
    }
    return URL(fileURLWithPath: uri)
  }

  private static func attachmentMimeType(
    from attachment: NSDictionary,
    fileName: String,
    url: URL
  ) -> String {
    if let mimeType = nonEmptyString(attachment["mimeType"]) {
      return mimeType
    }

    if let type = nonEmptyString(attachment["type"]) {
      if type.contains("/") {
        return type
      }
      let fileExtension = type.hasPrefix(".") ? String(type.dropFirst()) : type
      if let mimeType = UTType(filenameExtension: fileExtension)?.preferredMIMEType {
        return mimeType
      }
    }

    let fileExtension = URL(fileURLWithPath: fileName).pathExtension.isEmpty
      ? url.pathExtension
      : URL(fileURLWithPath: fileName).pathExtension

    return UTType(filenameExtension: fileExtension)?.preferredMIMEType
      ?? "application/octet-stream"
  }

  private static func nonEmptyString(_ value: Any?) -> String? {
    guard let value = value as? String else {
      return nil
    }
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedValue.isEmpty ? nil : trimmedValue
  }

  private func finish(result: MFMailComposeResult, error: Error?) {
    let resolve = mailResolve
    let reject = mailReject
    resetMailState()

    switch result {
    case .sent:
      resolve?("sent")
    case .saved:
      resolve?("saved")
    case .cancelled:
      resolve?("cancelled")
    case .failed:
      reject?(
        "E_MAIL_FAILED",
        error?.localizedDescription ?? "The mail composer failed to finish.",
        error
      )
    @unknown default:
      reject?("E_MAIL_FAILED", "The mail composer returned an unknown result.", error)
    }
  }

  private func resetMailState() {
    mailResolve = nil
    mailReject = nil
    currentComposer?.mailComposeDelegate = nil
    currentComposer = nil
  }
}

extension TinykitMail: MFMailComposeViewControllerDelegate {
  public nonisolated func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: Error?
  ) {
    MainActor.assumeIsolated {
      controller.dismiss(animated: true) { [weak self] in
        self?.finish(result: result, error: error)
      }
    }
  }
}
