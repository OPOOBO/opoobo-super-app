import 'package:flutter/material.dart';

class OpooboWordmark extends StatelessWidget {
  final bool isDark;

  const OpooboWordmark({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/opoobo_wordmark_2xl.png',
      height: 28,
      fit: BoxFit.contain,
    );
  }
}
