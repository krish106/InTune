#include "include/permission_handler_windows/permission_handler_windows_plugin.h"

#include <flutter/plugin_registrar_windows.h>

namespace permission_handler_windows {

class PermissionHandlerWindowsPlugin : public flutter::Plugin {
public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
  PermissionHandlerWindowsPlugin();
  virtual ~PermissionHandlerWindowsPlugin();
};

void PermissionHandlerWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  // No-op registration - permissions not applicable on Windows
}

PermissionHandlerWindowsPlugin::PermissionHandlerWindowsPlugin() {}

PermissionHandlerWindowsPlugin::~PermissionHandlerWindowsPlugin() {}

} // namespace permission_handler_windows

void PermissionHandlerWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  permission_handler_windows::PermissionHandlerWindowsPlugin::
      RegisterWithRegistrar(
          flutter::PluginRegistrarManager::GetInstance()
              ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
