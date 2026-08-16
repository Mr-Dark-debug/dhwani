import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.wordmark = false});
  final double size;
  final bool wordmark;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Dhwani',
    image: true,
    child: Image.asset(
      wordmark
          ? 'assets/branding/dhwani_wordmark.png'
          : 'assets/branding/dhwani_logo.png',
      width: wordmark ? size * 3.8 : size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(Icons.graphic_eq_rounded, size: size),
    ),
  );
}
