#ifndef RUNNER_OCR_CHANNEL_H_
#define RUNNER_OCR_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

constexpr UINT kOcrResultMessage = WM_APP + 0x42;

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
CreateOcrChannel(flutter::BinaryMessenger* messenger, HWND window);

void HandleOcrResultMessage(LPARAM payload);

#endif  // RUNNER_OCR_CHANNEL_H_
