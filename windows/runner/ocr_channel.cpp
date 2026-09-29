#include "ocr_channel.h"

#include <flutter/method_call.h>
#include <flutter/method_result.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
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

struct OcrResultPayload {
  std::unique_ptr<flutter::MethodResult<EncodableValue>> result;
  EncodableList lines;
  std::string error;
  std::string details;
};

void PostOcrResult(HWND window, OcrResultPayload* payload) {
  if (!PostMessage(window, kOcrResultMessage, 0,
                   reinterpret_cast<LPARAM>(payload))) {
    delete payload;
  }
}

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
  const auto source_width = decoder.PixelWidth();
  const auto source_height = decoder.PixelHeight();
  const auto max_dimension =
      winrt::Windows::Media::Ocr::OcrEngine::MaxImageDimension();
  if (source_width > max_dimension || source_height > max_dimension) {
    throw std::runtime_error("图片尺寸过大，无法进行文字识别");
  }
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

  std::vector<RecognizedLine> lines;
  // Crop tall, narrow screenshots before enlarging them. Scaling the entire
  // image is limited by its height and leaves three-column skill names tiny.
  const bool split = source_width < 900 && source_height > 700 &&
      decoder.OrientedPixelWidth() == source_width &&
      decoder.OrientedPixelHeight() == source_height;
  const uint32_t strip_height = split ? 480 : source_height;
  const uint32_t overlap = split ? 48 : 0;
  for (uint32_t top = 0; top < source_height;) {
    const uint32_t crop_height = std::min(strip_height, source_height - top);
    const double scale = source_width < 900
        ? std::min(900.0 / source_width,
                   static_cast<double>(max_dimension) /
                       std::max(source_width, crop_height))
        : 1.0;
    auto transform = winrt::Windows::Graphics::Imaging::BitmapTransform();
    uint32_t scaled_width = source_width;
    uint32_t scaled_height = source_height;
    if (scale > 1.05) {
      scaled_width = static_cast<uint32_t>(std::round(source_width * scale));
      scaled_height = static_cast<uint32_t>(std::round(source_height * scale));
      transform.ScaledWidth(scaled_width);
      transform.ScaledHeight(scaled_height);
      transform.InterpolationMode(
          winrt::Windows::Graphics::Imaging::BitmapInterpolationMode::Cubic);
    }
    // BitmapTransform applies Bounds after scaling, in scaled coordinates.
    const uint32_t crop_top = static_cast<uint32_t>(std::round(top * scale));
    const uint32_t crop_bottom = top + crop_height == source_height
        ? scaled_height
        : static_cast<uint32_t>(std::round((top + crop_height) * scale));
    transform.Bounds({0, crop_top, scaled_width, crop_bottom - crop_top});
    const auto bitmap = decoder.GetSoftwareBitmapAsync(
        winrt::Windows::Graphics::Imaging::BitmapPixelFormat::Bgra8,
        winrt::Windows::Graphics::Imaging::BitmapAlphaMode::Premultiplied,
        transform,
        winrt::Windows::Graphics::Imaging::ExifOrientationMode::RespectExifOrientation,
        winrt::Windows::Graphics::Imaging::ColorManagementMode::DoNotColorManage).get();
    const auto result = engine.RecognizeAsync(bitmap).get();
    const double width = static_cast<double>(bitmap.PixelWidth());
    const double height = static_cast<double>(bitmap.PixelHeight());
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
      const double center_y = (bounds.Y + bounds.Height / 2.0) / height;
      // Use the inner part of each strip so the overlap cannot duplicate a
      // skill or a rank heading at the edge of two OCR requests.
      if (split && ((top > 0 && center_y < overlap / (2.0 * crop_height)) ||
          (top + crop_height < source_height &&
           center_y > 1.0 - overlap / (2.0 * crop_height)))) continue;
      lines.push_back({winrt::to_string(line.Text()),
                       (bounds.X + bounds.Width / 2.0) / width,
                       (top + center_y * crop_height) / source_height});
    }
    if (top + crop_height >= source_height) break;
    top += crop_height - overlap;
  }
  std::sort(lines.begin(), lines.end(), [](const auto& left, const auto& right) {
    if (left.y != right.y) return left.y < right.y;
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
CreateOcrChannel(flutter::BinaryMessenger* messenger, HWND window) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "baizhan_skill/ocr",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [window](const flutter::MethodCall<EncodableValue>& call,
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
        std::thread([window, path = *path,
                     result = std::move(result)]() mutable {
          auto* payload = new OcrResultPayload{std::move(result), {}, {}, {}};
          try {
            payload->lines = RecognizeText(path);
          } catch (const winrt::hresult_error& error) {
            payload->error = "Windows 图片文字识别失败";
            payload->details = winrt::to_string(error.message());
          } catch (const std::exception& error) {
            payload->error = error.what();
          } catch (...) {
            payload->error = "Windows 图片文字识别发生未知错误";
          }
          PostOcrResult(window, payload);
        }).detach();
      });
  return channel;
}

void HandleOcrResultMessage(LPARAM value) {
  std::unique_ptr<OcrResultPayload> payload(
      reinterpret_cast<OcrResultPayload*>(value));
  if (!payload || !payload->result) return;
  if (payload->error.empty()) {
    payload->result->Success(EncodableValue(std::move(payload->lines)));
  } else if (payload->details.empty()) {
    payload->result->Error("ocr", payload->error);
  } else {
    payload->result->Error("ocr", payload->error,
                           EncodableValue(payload->details));
  }
}
