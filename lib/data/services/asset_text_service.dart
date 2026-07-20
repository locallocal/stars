import 'package:flutter/services.dart';

typedef AssetTextLoader = Future<String> Function(String assetPath);

class AssetTextService {
  const AssetTextService({AssetTextLoader loader = _loadAsset})
    : _loader = loader;

  final AssetTextLoader _loader;

  Future<String> load(String assetPath) => _loader(assetPath);
}

Future<String> _loadAsset(String assetPath) => rootBundle.loadString(assetPath);
