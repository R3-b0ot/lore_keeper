import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'inappwebview_platform_stub.dart'
    if (dart.library.html) 'inappwebview_platform_web.dart'
    if (dart.library.io) 'inappwebview_platform_io.dart';

void ensureInAppWebViewPlatform() {
  if (InAppWebViewPlatform.instance != null) return;
  registerInAppWebViewPlatform();
}
