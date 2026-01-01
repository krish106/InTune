import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/utils/logger.dart';

class SystemTrayManager {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();

  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  Future<void> initSystemTray() async {
    String iconPath = Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    // We first init the system tray menu
    final Menu menu = Menu();
    await menu.buildFrom([
        MenuItemLabel(label: 'Show', onClicked: (menuItem) async {
          await windowManager.show();
          await windowManager.focus();
        }),
        MenuItemLabel(label: 'Exit', onClicked: (menuItem) async {
          await windowManager.destroy();
        }),
    ]);

    await _systemTray.initSystemTray(
      title: "InTune",
      iconPath: iconPath,
    );

    await _systemTray.setContextMenu(menu);

    // Handle left click on tray icon
    _systemTray.registerSystemTrayEventHandler((eventName) async {
      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        bool isVisible = await windowManager.isVisible();
        if (isVisible) {
          await windowManager.hide();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }
}
