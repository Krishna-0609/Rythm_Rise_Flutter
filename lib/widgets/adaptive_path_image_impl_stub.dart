import 'package:flutter/widgets.dart';

Widget buildAdaptivePathImage({
  required String path,
  required Widget fallback,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return SizedBox(width: width, height: height, child: fallback);
}
