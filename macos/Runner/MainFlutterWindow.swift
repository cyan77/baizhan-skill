import Cocoa
import FlutterMacOS
import Vision

class MainFlutterWindow: NSWindow {
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

    super.awakeFromNib()
  }
}
