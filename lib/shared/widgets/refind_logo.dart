import 'package:flutter/material.dart';

/// The ReFind logo: the same picture that is used for the Android launcher icon.
///
/// The picture is square, so it always keeps its proportions: [size] is both
/// the width and the height. It is drawn as a rounded tile, like an app icon.
class ReFindLogo extends StatelessWidget {
  /// The one logo file for the whole app (registered in pubspec.yaml).
  static const String assetPath = 'assets/icon/launcher_icon.png';

  /// Width and height of the logo.
  final double size;

  /// Corner radius. If null, it is a quarter of [size].
  final double? borderRadius;

  /// Adds a soft shadow (used on the splash screen).
  final bool withShadow;

  const ReFindLogo({
    super.key,
    this.size = 64,
    this.borderRadius,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? size * 0.25);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    final logo = ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        // The file is 1024 px wide; decode it at the size it is shown at.
        cacheWidth: (size * pixelRatio).round(),
        semanticLabel: 'ReFind logo',
      ),
    );

    if (!withShadow) return logo;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: logo,
    );
  }
}
