import 'package:flutter/material.dart';

/// Logo W-Tech adattivo: versione scura su sfondo chiaro, bianca su sfondo scuro.
class WtechLogo extends StatelessWidget {
  /// Altezza del logo. La larghezza si adatta proporzionalmente.
  final double height;

  /// Se true usa il brandmark quadrato, altrimenti il logo orizzontale.
  final bool brandmarkOnly;

  const WtechLogo({super.key, this.height = 28, this.brandmarkOnly = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final String asset;
    if (brandmarkOnly) {
      asset = dark
          ? 'assets/images/logo/brandmark-w-tech_w.png'
          : 'assets/images/logo/brandmark-w-tech.png';
    } else {
      asset = dark
          ? 'assets/images/logo/logo-w-tech_w.png'
          : 'assets/images/logo/logo-w-tech.png';
    }
    return Image.asset(asset, height: height, fit: BoxFit.contain);
  }
}
