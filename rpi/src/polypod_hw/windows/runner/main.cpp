#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Determine window title from command line arguments or POLYPOD_WINDOW env.
  std::wstring window_title = L"Polypod_Top_Screen";
  std::wstring cmd(command_line);
  if (cmd.find(L"--bottom") != std::wstring::npos) {
    window_title = L"Polypod_Bottom_Window";
  } else if (cmd.find(L"--single") != std::wstring::npos) {
    window_title = L"Polypod Hardware Control";
  }
  // Also check POLYPOD_WINDOW dart-define (passed via env or embedded).
  // When using flutter run --dart-define=POLYPOD_WINDOW=bottom, the define
  // isn't available natively, so we also check the POLYPOD_WINDOW env var.
  wchar_t env_buf[64] = {};
  if (::GetEnvironmentVariableW(L"POLYPOD_WINDOW", env_buf, 64) > 0) {
    std::wstring env_val(env_buf);
    if (env_val == L"bottom") {
      window_title = L"Polypod_Bottom_Window";
    } else if (env_val == L"single") {
      window_title = L"Polypod Hardware Control";
    }
  }

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(window_title.c_str(), origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
