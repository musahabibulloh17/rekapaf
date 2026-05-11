import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  const LoadingIndicator({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'lib/loading.gif',
        width: size,
        height: size,
      ),
    );
  }
}
