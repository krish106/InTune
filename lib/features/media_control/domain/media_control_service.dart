import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../../../core/utils/logger.dart';

class MediaControlService {
  // Virtual key codes for media keys
  static const int VK_MEDIA_PLAY_PAUSE = 0xB3;
  static const int VK_MEDIA_NEXT_TRACK = 0xB0;
  static const int VK_MEDIA_PREV_TRACK = 0xB1;
  static const int VK_VOLUME_UP = 0xAF;
  static const int VK_VOLUME_DOWN = 0xAE;

  static void handleMediaControl(String action) {
    try {
      switch (action) {
        case 'PLAY_PAUSE':
          _simulateKey(VK_MEDIA_PLAY_PAUSE);
          AppLogger.info('🎵 Media: Play/Pause');
          break;
        case 'NEXT':
          _simulateKey(VK_MEDIA_NEXT_TRACK);
          AppLogger.info('🎵 Media: Next Track');
          break;
        case 'PREV':
          _simulateKey(VK_MEDIA_PREV_TRACK);
          AppLogger.info('🎵 Media: Previous Track');
          break;
        case 'VOL_UP':
          _simulateKey(VK_VOLUME_UP);
          AppLogger.info('🔊 Volume Up');
          break;
        case 'VOL_DOWN':
          _simulateKey(VK_VOLUME_DOWN);
          AppLogger.info('🔉 Volume Down');
          break;
        default:
          AppLogger.warning('Unknown media action: $action');
      }
    } catch (e) {
      AppLogger.error('Media control error', e);
    }
  }

  static void _simulateKey(int virtualKey) {
    final input = calloc<INPUT>();
    
    try {
      // Set up keyboard input
      input.ref.type = INPUT_KEYBOARD;
      input.ref.ki.wVk = virtualKey;
      input.ref.ki.dwFlags = 0;

      // Press key
      SendInput(1, input, sizeOf<INPUT>());

      // Small delay
      Sleep(50);

      // Release key
      input.ref.ki.dwFlags = KEYEVENTF_KEYUP;
      SendInput(1, input, sizeOf<INPUT>());
    } finally {
      free(input);
    }
  }
}
