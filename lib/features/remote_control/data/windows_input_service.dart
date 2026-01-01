import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsInputService {
  // Config
  static const double mouseSpeed = 2.0;

  void handleInput(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    print('🖱️ WindowsInputService.handleInput called with type: $type');
    
    switch (type) {
      case 'mouse_move':
        _handleMouseMove(payload);
        break;
      case 'mouse_click':
        _handleMouseClick(payload);
        break;
      case 'mouse_scroll':
        _handleMouseScroll(payload);
        break;
      case 'hotkey':
        _handleHotkey(payload);
        break;
      case 'text_input':
        _handleTextInput(payload);
        break;
    }
  }

  void _handleTextInput(Map<String, dynamic> payload) {
    final text = payload['text'] as String?;
    if (text == null) return;

    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      
      final input = calloc<INPUT>();
      input.ref.type = INPUT_KEYBOARD;
      input.ref.ki.wScan = charCode;
      input.ref.ki.dwFlags = KEYEVENTF_UNICODE; 
      SendInput(1, input, sizeOf<INPUT>());
      
      input.ref.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
      SendInput(1, input, sizeOf<INPUT>());
      free(input);
    }
  }

  void handleMediaControl(Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    if (action == 'MUTE') {
      _sendKeyPress(VK_VOLUME_MUTE);
    }
  }

  void _handleMouseMove(Map<String, dynamic> payload) {
    final dx = (payload['dx'] as num?)?.toDouble() ?? 0.0;
    final dy = (payload['dy'] as num?)?.toDouble() ?? 0.0;

    final point = calloc<POINT>();
    try {
      GetCursorPos(point);
      
      int newX = point.ref.x + (dx * mouseSpeed).round();
      int newY = point.ref.y + (dy * mouseSpeed).round();
      
      // Screen bounds checks could be added here
      
      SetCursorPos(newX, newY);
    } finally {
      free(point);
    }
  }

  void _handleMouseClick(Map<String, dynamic> payload) {
    final button = payload['button'] as String?;
    
    if (button == 'left') {
      final input = calloc<INPUT>();
      input.ref.type = INPUT_MOUSE;
      input.ref.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
      SendInput(1, input, sizeOf<INPUT>());
      
      input.ref.mi.dwFlags = MOUSEEVENTF_LEFTUP;
      SendInput(1, input, sizeOf<INPUT>());
      free(input);
    } else if (button == 'right') {
       final input = calloc<INPUT>();
      input.ref.type = INPUT_MOUSE;
      input.ref.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
      SendInput(1, input, sizeOf<INPUT>());
      
      input.ref.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
      SendInput(1, input, sizeOf<INPUT>());
      free(input);
    }
  }

  void _handleMouseScroll(Map<String, dynamic> payload) {
    final dy = (payload['dy'] as num?)?.toDouble() ?? 0.0;
    
    // Windows expects WHEEL_DELTA (120) for one notch.
    // dy will be small pixels (e.g. 10.0), so we scale it.
    final scrollAmount = (dy * -2).round(); // Invert dy for natural scrolling

    final input = calloc<INPUT>();
    input.ref.type = INPUT_MOUSE;
    input.ref.mi.dwFlags = MOUSEEVENTF_WHEEL;
    input.ref.mi.mouseData = scrollAmount;
    SendInput(1, input, sizeOf<INPUT>());
    free(input);
  }

  void _handleHotkey(Map<String, dynamic> payload) {
    final key = payload['key'] as String?;
    
    if (key == 'WIN+TAB') {
      _sendCombination([VK_LWIN, VK_TAB]);
    } else if (key == 'ALT+F4') {
      _sendCombination([VK_MENU, VK_F4]);
    } else if (key == 'BACKSPACE') {
      _sendKeyPress(VK_BACK);
    } else if (key == 'ENTER') {
      _sendKeyPress(VK_RETURN);
    } else if (key == 'ESCAPE') {
      _sendKeyPress(VK_ESCAPE);
    }
  }

  void _sendKeyPress(int vKey) {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_KEYBOARD;
    input.ref.ki.wVk = vKey;
    SendInput(1, input, sizeOf<INPUT>());
    
    input.ref.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1, input, sizeOf<INPUT>());
    free(input);
  }

  void _sendCombination(List<int> keys) {
    final inputs = calloc<INPUT>(keys.length * 2);
    
    // Press all
    for (int i = 0; i < keys.length; i++) {
        final input = inputs.elementAt(i);
        input.ref.type = INPUT_KEYBOARD;
        input.ref.ki.wVk = keys[i];
    }
    SendInput(keys.length, inputs, sizeOf<INPUT>());

    // Release all (reverse order)
    for (int i = 0; i < keys.length; i++) {
        final input = inputs.elementAt(keys.length + i);
        input.ref.type = INPUT_KEYBOARD;
        input.ref.ki.wVk = keys[keys.length - 1 - i];
        input.ref.ki.dwFlags = KEYEVENTF_KEYUP;
    }
    SendInput(keys.length, inputs.elementAt(keys.length), sizeOf<INPUT>()); // Send releases

    free(inputs);
  }
}
