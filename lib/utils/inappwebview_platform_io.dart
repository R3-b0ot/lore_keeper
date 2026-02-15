// ignore_for_file: implementation_imports

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview_android/src/inappwebview_platform.dart'
    as android;
import 'package:flutter_inappwebview_ios/src/inappwebview_platform.dart' as ios;
import 'package:flutter_inappwebview_macos/src/inappwebview_platform.dart'
    as macos;
import 'package:flutter_inappwebview_windows/src/inappwebview_platform.dart'
    as windows;

void registerInAppWebViewPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      android.AndroidInAppWebViewPlatform.registerWith();
      return;
    case TargetPlatform.iOS:
      ios.IOSInAppWebViewPlatform.registerWith();
      return;
    case TargetPlatform.macOS:
      macos.MacOSInAppWebViewPlatform.registerWith();
      return;
    case TargetPlatform.windows:
      windows.WindowsInAppWebViewPlatform.registerWith();
      return;
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return;
  }
}
