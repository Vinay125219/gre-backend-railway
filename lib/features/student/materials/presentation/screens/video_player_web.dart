// Web implementation for video player
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

/// Register YouTube iframe for web
void registerYouTubeIframe(String viewType, String videoId) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0';
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.allowFullscreen = true;
    iframe.allow =
        'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
    return iframe;
  });
}
