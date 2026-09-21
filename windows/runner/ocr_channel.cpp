#include "ocr_channel.h"

#include <flutter/method_call.h>
#include <flutter/method_result.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <future>
#include <stdexcept>
#include <string>
#include <vector>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::Foundation::Rect;

struct RecognizedLine {
  std::string text;
  double x;
  double y;
};

EncodableList RecognizeText(const std::string& path) {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  const auto file =
      winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(
          winrt::to_hstring(path))
          .get();
  const auto stream = file.OpenAsync(
      winrt::Windows::Storage::FileAccessMode::Read).get();
  const auto decoder =
      winrt::Windows::Graphics::Imaging::BitmapDecoder::CreateAsync(stream)
          .get();
  const auto bitmap = decoder.GetSoftwareBitmapAsync(
      winrt::Windows::Graphics::Imaging::BitmapPixelFormat::Bgra8,
      winrt::Windows::Graphics::Imaging::BitmapAlphaMode::Premultiplied).get();

  auto engine = winrt::Windows::Media::Ocr::OcrEngine::TryCreateFromLanguage(
      winrt::Windows::Globalization::Language(L"zh-Hans"));
  if (!engine) {
    engine = winrt::Windows::Media::Ocr::OcrEngine::
        TryCreateFromUserProfileLanguages();
  }
  if (!engine) {
    throw std::runtime_error(
        "Windows 未安装中文 OCR 语言组件，请在系统语言设置中添加简体中文");
  }

  const auto result = engine.RecognizeAsync(bitmap).get();
  const double width = static_cast<double>(bitmap.PixelWidth());
  const double height = static_cast<double>(bitmap.PixelHeight());
  std::vector<RecognizedLine> lines;
  for (const auto& line : result.Lines()) {
    bool has_rect = false;
    Rect bounds{};
    for (const auto& word : line.Words()) {
      const auto rect = word.BoundingRect();
      if (!has_rect) {
        bounds = rect;
        has_rect = true;
      } else {
        const float right = std::max(bounds.X + bounds.Width,
                                     rect.X + rect.Width);
        const float bottom = std::max(bounds.Y + bounds.Height,
                                      rect.Y + rect.Height);
        bounds.X = std::min(bounds.X, rect.X);
        bounds.Y = std::min(bounds.Y, rect.Y);
        bounds.Width = right - bounds.X;
        bounds.Height = bottom - bounds.Y;
      }
    }
    if (!has_rect) continue;
    lines.push_back({winrt::to_string(line.Text()),
                     (bounds.X + bounds.Width / 2.0) / width,
                     (bounds.Y + bounds.Height / 2.0) / height});
  }
  std::sort(lines.begin(), lines.end(), [](const auto& left, const auto& right) {
    if (std::abs(left.y - right.y) > 0.008) return left.y < right.y;
    return left.x < right.x;
  });

  EncodableList encoded;
  for (const auto& line : lines) {
    encoded.emplace_back(EncodableMap{
        {EncodableValue("text"), EncodableValue(line.text)},
        {EncodableValue("x"), EncodableValue(line.x)},
        {EncodableValue("y"), EncodableValue(line.y)},
    });
  }
  return encoded;
}

}  // namespace

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
CreateOcrChannel(flutter::BinaryMessenger* messenger) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "baizhan_skill/ocr",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        if (call.method_name() != "recognizeText") {
          result->NotImplemented();
          return;
        }
        const auto* arguments =
            std::get_if<EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("arguments", "缺少图片路径");
          return;
        }
        const auto path_it = arguments->find(EncodableValue("path"));
        if (path_it == arguments->end()) {
          result->Error("arguments", "缺少图片路径");
          return;
        }
        const auto* path = std::get_if<std::string>(&path_it->second);
        if (path == nullptr || path->empty()) {
          result->Error("arguments", "图片路径无效");
          return;
        }
        try {
          auto task = std::async(std::launch::async, RecognizeText, *path);
          result->Success(EncodableValue(task.get()));
        } catch (const winrt::hresult_error& error) {
          result->Error("ocr", "Windows 图片文字识别失败",
                        EncodableValue(winrt::to_string(error.message())));
        } catch (const std::exception& error) {
          result->Error("ocr", error.what());
        }
      });
  return channel;
}
