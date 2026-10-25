import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/ui/features/chat/views/local_pdf_file_preview.dart';

import '../../../../support/widget_test_support.dart';

void main() {
  setUpAll(() async {
    // flutter_tester does not use the app bundle's native library directory.
    // Resolve the library produced by the package build hook for widget tests.
    final build = Directory('.dart_tool/hooks_runner/shared/pdfium_dart/build');
    if (build.existsSync() &&
        !Platform.environment.containsKey('PDFIUM_PATH')) {
      final libraryName =
          Platform.isWindows
              ? 'pdfium.dll'
              : Platform.isMacOS
              ? 'libpdfium.dylib'
              : 'libpdfium.so';
      for (final entity in build.listSync(recursive: true)) {
        if (entity is File && entity.uri.pathSegments.last == libraryName) {
          Pdfrx.pdfiumModulePath = entity.absolute.path;
          break;
        }
      }
    }
    await pdfrxInitialize(tmpPath: Directory.systemTemp.path);
  });

  testWidgets('renders a local PDF and navigates to the next page', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('stars-pdf-preview-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/two-pages.pdf')
      ..writeAsStringSync(_twoPagePdf());
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(body: LocalPdfFilePreview(filePath: file.path)),
      ),
    );
    await _waitFor(tester, () => find.text('1 / 2').evaluate().isNotEmpty);
    expect(find.byType(PdfViewer), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await _waitFor(tester, () => find.text('2 / 2').evaluate().isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('invalid PDFs show a safe error', (tester) async {
    final directory = Directory.systemTemp.createTempSync('stars-pdf-invalid-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/invalid.pdf')
      ..writeAsStringSync('invalid');
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(body: LocalPdfFilePreview(filePath: file.path)),
      ),
    );
    await _waitFor(tester, () => find.byType(ShadAlert).evaluate().isNotEmpty);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _waitFor(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 150 && !condition(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
  expect(condition(), isTrue);
}

String _twoPagePdf() {
  final buffer = StringBuffer('%PDF-1.4\n');
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 400] /Contents 5 0 R >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 400] /Contents 5 0 R >>',
    '<< /Length 0 >>\nstream\n\nendstream',
  ];
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(buffer.length);
    buffer.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = buffer.length;
  buffer.write('xref\n0 6\n0000000000 65535 f \n');
  for (final offset in offsets) {
    buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  buffer.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
  return buffer.toString();
}
