import 'package:flutter/material.dart';

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height;
    final loaderHeight = height.clamp(120.0, availableHeight * 0.24);

    return SizedBox.expand(
      child: Center(
        child: Image.asset(
          'assets/Splash Animation.gif',
          height: loaderHeight,
        ),
      ),
    );
  }
}
