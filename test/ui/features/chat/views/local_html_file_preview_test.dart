import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/ui/features/chat/views/local_html_file_preview.dart';
import 'package:webview_all/webview_all.dart' show WebViewPlatform;
import 'package:webview_platform_interface/webview_platform_interface.dart'
    hide WebViewPlatform;

import '../../../../support/widget_test_support.dart';

void main() {
  final platform = _TestWebViewPlatform();

  setUp(() {
    WebViewPlatform.instance = platform;
    platform.controller = null;
  });

  testWidgets('loads local HTML with unrestricted JavaScript in a WebView', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-live-html-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/dashboard.html')..writeAsStringSync('''
<!doctype html>
<html>
  <head><title>Live dashboard</title></head>
  <body><div id="value"></div><script src="dashboard.js"></script></body>
</html>
''');
    File('${directory.path}/dashboard.js').writeAsStringSync(
      "document.querySelector('#value').textContent = 'ready';",
    );

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: LocalHtmlFilePreview(file: file),
              ),
            ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LocalHtmlFilePreview), findsOneWidget);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey<String>('message-local-html-runtime')),
    );

    final controller = platform.controller;
    expect(controller, isNotNull);
    expect(controller!.javaScriptMode, JavaScriptMode.unrestricted);
    expect(controller.zoomEnabled, isTrue);
    expect(controller.filePath, file.path);
    expect(controller.navigationDelegate, isNotNull);
    expect(controller.permissionHandler, isNotNull);
    final navigationDelegate =
        controller.navigationDelegate! as _TestNavigationDelegate;
    expect(
      await navigationDelegate.navigationRequest!(
        NavigationRequest(url: file.uri.toString(), isMainFrame: true),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await navigationDelegate.navigationRequest!(
        const NavigationRequest(
          url: 'https://example.com/untrusted',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
    expect(
      find.byKey(const ValueKey<String>('message-local-html-runtime')),
      findsOneWidget,
    );
    expect(find.text('Live dashboard'), findsOneWidget);
    expect(find.text('JS'), findsOneWidget);

    await tester.tap(find.text('源代码'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('message-local-html-source')),
      findsOneWidget,
    );
    expect(find.textContaining('dashboard.js'), findsOneWidget);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

final class _TestWebViewPlatform extends WebViewPlatform {
  _TestWebViewController? controller;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return controller = _TestWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _TestNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _TestWebViewWidget(params);
}

final class _TestWebViewController extends PlatformWebViewController {
  _TestWebViewController(super.params) : super.implementation();

  String? filePath;
  JavaScriptMode? javaScriptMode;
  bool? zoomEnabled;
  PlatformNavigationDelegate? navigationDelegate;
  void Function(PlatformWebViewPermissionRequest request)? permissionHandler;

  @override
  Future<void> loadFile(String absoluteFilePath) async {
    filePath = absoluteFilePath;
    final delegate = navigationDelegate;
    if (delegate is _TestNavigationDelegate) {
      delegate.progress?.call(100);
      delegate.pageFinished?.call(Uri.file(absoluteFilePath).toString());
    }
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    this.javaScriptMode = javaScriptMode;
  }

  @override
  Future<void> enableZoom(bool enabled) async {
    zoomEnabled = enabled;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    navigationDelegate = handler;
  }

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {
    permissionHandler = onPermissionRequest;
  }
}

final class _TestNavigationDelegate extends PlatformNavigationDelegate {
  _TestNavigationDelegate(super.params) : super.implementation();

  PageEventCallback? pageFinished;
  ProgressCallback? progress;
  NavigationRequestCallback? navigationRequest;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    navigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    pageFinished = onPageFinished;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    progress = onProgress;
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {}
}

final class _TestWebViewWidget extends PlatformWebViewWidget {
  _TestWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(key: ValueKey<String>('test-webview'));
  }
}
