import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/image_media_type.dart';

void main() {
  test('detects supported raster image signatures', () {
    expect(detectImageMediaType([0xFF, 0xD8, 0xFF]), 'image/jpeg');
    expect(
      detectImageMediaType([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      'image/png',
    );
    expect(
      detectImageMediaType([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]),
      'image/gif',
    );
    expect(detectImageMediaType([0x42, 0x4D]), 'image/bmp');
    expect(
      detectImageMediaType([
        0x52,
        0x49,
        0x46,
        0x46,
        0,
        0,
        0,
        0,
        0x57,
        0x45,
        0x42,
        0x50,
      ]),
      'image/webp',
    );
  });

  test('rejects SVG and malformed image signatures', () {
    expect(detectImageMediaType('<svg'.codeUnits), isNull);
    expect(detectImageMediaType([0x52, 0x49, 0x46, 0x46]), isNull);
    expect(detectImageMediaType(const []), isNull);
  });
}
