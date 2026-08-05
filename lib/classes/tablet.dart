import 'package:flutter/cupertino.dart';

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PillColorMapper extends ColorMapper {
  final Color baseColor;

  const PillColorMapper(this.baseColor);

  Color substitute(String? id, String elementName, String attributeName, Color color) {
    // Define the exact reference hex codes used in your SVG template files
    const refTop = Color(0xFFFF0000); // Red
    const refLight = Color(0xFF00FF00); // Green
    const refDark = Color(0xFF00FF); // Blue
    const refLine = Color(0xFFFF00FF); // Magenta

    if (color == refTop) {
      return baseColor;
    }
    if (color == refLight) {
      return HSLColor.fromColor(
        baseColor,
      ).withLightness((HSLColor.fromColor(baseColor).lightness - 0.12).clamp(0.0, 1.0)).toColor();
    }
    if (color == refDark) {
      return HSLColor.fromColor(
        baseColor,
      ).withLightness((HSLColor.fromColor(baseColor).lightness - 0.24).clamp(0.0, 1.0)).toColor();
    }
    if (color == refLine) {
      return HSLColor.fromColor(
        baseColor,
      ).withLightness((HSLColor.fromColor(baseColor).lightness - 0.40).clamp(0.0, 1.0)).toColor();
    }

    return color;
  }
}

class PillColorHelper {
  static Color getTopFaceColor(Color baseColor) => baseColor;

  static Color getLightSideColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }

  static Color getDarkSideColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.24).clamp(0.0, 1.0)).toColor();
  }

  static Color getLineColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.40).clamp(0.0, 1.0)).toColor();
  }
}

class TabletShape {
  static Future<String> colorizeSvgAsset(String assetPath, Color baseColor) async {
    String rawSvg = await rootBundle.loadString(assetPath);

    final topColor = baseColor;
    final lightSide = PillColorHelper.getLightSideColor(baseColor);
    final darkSide = PillColorHelper.getDarkSideColor(baseColor);
    final lineColor = PillColorHelper.getLineColor(baseColor);

    String toHex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    return rawSvg
        .replaceAll('VAR_TOP', toHex(topColor))
        .replaceAll('VAR_LIGHT', toHex(lightSide))
        .replaceAll('VAR_DARK', toHex(darkSide))
        .replaceAll('VAR_LINE', toHex(lineColor));
  }

  // static Future<String> colorizeSvgAsset(String assetPath, Color baseColor) async {
  //   // 1. Load the raw SVG string from disk/assets
  //   String rawSvg = await rootBundle.loadString(assetPath);
  //
  //   // 2. Derive your shaded colors
  //   final topColor = baseColor;
  //   final lightSide = PillColorHelper.getLightSideColor(baseColor);
  //   final darkSide = PillColorHelper.getDarkSideColor(baseColor);
  //   final lineColor = PillColorHelper.getLineColor(baseColor);
  //
  //   // Helper to convert Color to hex string (#RRGGBB)
  //   String toHex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  //   // 3. Inject a <style> block at the top of the SVG to color-code your point classes consistently across all shapes
  //   final styleBlock =
  //       '''
  //   <style>
  //     .pill-top { fill: ${toHex(topColor)}; }
  //     .pill-side-light { fill: ${toHex(lightSide)}; }
  //     .pill-side-dark { fill: ${toHex(darkSide)}; }
  //     .pill-line { fill: none; stroke: ${toHex(lineColor)}; stroke-width: 4; stroke-linejoin: round; stroke-linecap: round; }
  //   </style>
  // ''';
  //
  //   // Insert style right after <svg ...> opening tag
  //   return rawSvg.replaceFirst(RegExp(r'<svg[^>]*>'), '${RegExp(r'<svg[^>]*>').stringMatch(rawSvg)}$styleBlock');
  // }
}
