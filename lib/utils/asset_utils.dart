import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';

class AssetUtils {
  static final Random _random = Random();
  static Map<String, List<String>>? _assetCache;

  /// Loads the asset manifest and caches it.
  /// Should be called once at app startup or lazily.
  static Future<void> _ensureManifestLoaded(BuildContext context) async {
    if (_assetCache != null) return;

    try {
      final manifestContent = await DefaultAssetBundle.of(
        context,
      ).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      _assetCache = {'all': manifestMap.keys.toList()};
    } catch (e) {
      debugPrint("Error loading AssetManifest: $e");
      _assetCache = {'all': []};
    }
  }

  /// Finds all assets that match the base name pattern.
  /// e.g. "female_thief" matches "female_thief.png", "female_thief_2.png"
  static Future<List<String>> getVariations(
    BuildContext context,
    String basePath,
  ) async {
    await _ensureManifestLoaded(context);

    final allAssets = _assetCache?['all'] ?? [];
    final results = <String>[];

    // Normalize basePath (remove extension if present)
    String baseWithoutExt = basePath;
    String extension = ".png";
    if (basePath.toLowerCase().endsWith('.png')) {
      baseWithoutExt = basePath.substring(0, basePath.length - 4);
    } else if (basePath.toLowerCase().endsWith('.jpg')) {
      baseWithoutExt = basePath.substring(0, basePath.length - 4);
      extension = ".jpg";
    }

    // Search for matches: baseWithoutExt + (.png OR _N.png)
    for (final asset in allAssets) {
      if (!asset.startsWith(baseWithoutExt)) continue;

      // Exact match
      if (asset == "$baseWithoutExt$extension") {
        results.add(asset);
        continue;
      }

      // Numbered variations: base_2.png, base_12.png
      final suffix = asset.substring(baseWithoutExt.length);
      if (suffix.startsWith('_') && suffix.endsWith(extension)) {
        final numberPart = suffix.substring(1, suffix.length - extension.length);
        if (int.tryParse(numberPart) != null) {
          results.add(asset);
        }
      }
    }

    // Fallback: return the base path so the UI never gets an empty list.
    if (results.isEmpty) {
      results.add(basePath);
    }

    return results;
  }

  /// Returns a random variation of the asset.
  static Future<String> getRandomVariation(
    BuildContext context,
    String basePath,
  ) async {
    final variations = await getVariations(context, basePath);
    if (variations.isEmpty) return basePath;
    return variations[_random.nextInt(variations.length)];
  }
}
