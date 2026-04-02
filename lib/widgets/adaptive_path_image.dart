import 'package:flutter/widgets.dart';

import 'adaptive_path_image_impl_stub.dart'
    if (dart.library.html) 'adaptive_path_image_impl_web.dart'
    if (dart.library.io) 'adaptive_path_image_impl_io.dart'
    as impl;

class AdaptivePathImage extends StatelessWidget {
  const AdaptivePathImage({
    super.key,
    required this.path,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return impl.buildAdaptivePathImage(
      path: path,
      fallback: fallback,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
