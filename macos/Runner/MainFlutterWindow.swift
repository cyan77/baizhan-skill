import Cocoa
import FlutterMacOS
import Vision

class MainFlutterWindow: NSWindow {
  private var localDataURL: URL?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let ocrChannel = FlutterMethodChannel(
      name: "baizhan_skill/ocr",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    ocrChannel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        guard let image = NSImage(contentsOfFile: path),
              let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let cgImage = bitmap.cgImage else {
          DispatchQueue.main.async { result(FlutterError(code: "image", message: "无法读取图片", details: nil)) }
          return
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "zh-Hant"]
        do {
          try VNImageRequestHandler(cgImage: cgImage).perform([request])
          let items = (request.results ?? []).compactMap { observation -> [String: Any]? in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            return ["text": text, "x": observation.boundingBox.midX, "y": observation.boundingBox.midY]
          }.sorted {
            let leftY = $0["y"] as? Double ?? 0
            let rightY = $1["y"] as? Double ?? 0
            if abs(leftY - rightY) > 0.008 { return leftY > rightY }
            return ($0["x"] as? Double ?? 0) < ($1["x"] as? Double ?? 0)
          }
          DispatchQueue.main.async { result(items) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "ocr", message: "图片文字识别失败", details: error.localizedDescription)) }
        }
      }
    }

    let storageChannel = FlutterMethodChannel(
      name: "baizhan_skill/local_storage",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    storageChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "saveBookmark":
        guard let arguments = call.arguments as? [String: Any],
              let path = arguments["path"] as? String else {
          result(FlutterError(code: "arguments", message: "缺少本地数据路径", details: nil))
          return
        }
        do {
          self.stopAccessingLocalData()
          let url = URL(fileURLWithPath: path)
          let bookmark = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil)
          UserDefaults.standard.set(bookmark, forKey: "localDataSecurityBookmark")
          guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "BaizhanSkill", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "无法取得所选文件的访问权限"])
          }
          self.localDataURL = url
          result(nil)
        } catch {
          result(FlutterError(code: "bookmark", message: "无法保存本地数据位置授权", details: error.localizedDescription))
        }
      case "restoreBookmark":
        guard let bookmark = UserDefaults.standard.data(forKey: "localDataSecurityBookmark") else {
          result(false)
          return
        }
        do {
          var stale = false
          let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale)
          self.stopAccessingLocalData()
          guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "BaizhanSkill", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "无法恢复本地数据位置授权"])
          }
          self.localDataURL = url
          if stale {
            let refreshed = try url.bookmarkData(
              options: .withSecurityScope,
              includingResourceValuesForKeys: nil,
              relativeTo: nil)
            UserDefaults.standard.set(refreshed, forKey: "localDataSecurityBookmark")
          }
          result(url.path)
        } catch {
          result(FlutterError(code: "bookmark", message: "无法恢复本地数据位置授权", details: error.localizedDescription))
        }
      case "clearBookmark":
        self.stopAccessingLocalData()
        UserDefaults.standard.removeObject(forKey: "localDataSecurityBookmark")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  private func stopAccessingLocalData() {
    localDataURL?.stopAccessingSecurityScopedResource()
    localDataURL = nil
  }
}
