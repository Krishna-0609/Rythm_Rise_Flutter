import 'dart:io';

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

  if (_looksLikeRemoteImage(trimmed)) {
    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  return Image.file(
    File(trimmed),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback,
  );
}

bool _looksLikeRemoteImage(String value) {
  final normalized = value.toLowerCase();
  return normalized.startsWith('http://') || normalized.startsWith('https://');
}
