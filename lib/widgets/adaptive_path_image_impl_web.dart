import 'package:flutter/widgets.dart';

Widget buildAdaptivePathImage({
  required String path,
  required Widget fallback,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return SizedBox(width: width, height: height, child: fallback);
  }

  return Image.network(
    trimmed,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback,
  );
}
