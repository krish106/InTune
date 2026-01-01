import 'dart:io';
import 'main_windows.dart' as win;
import 'main_android.dart' as android;

void main() {
  if (Platform.isWindows) {
    win.main();
  } else if (Platform.isAndroid) {
    android.main();
  } else {
    throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
  }
}
