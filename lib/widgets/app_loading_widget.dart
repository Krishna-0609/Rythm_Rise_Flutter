import 'package:flutter/material.dart';

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/Splash Animation.gif', height: height),
    );
  }
}
