import 'dart:io';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? path;
  final Widget fallback;
  final BoxFit fit;
  const ProductImage({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final src = path;
    if (src == null || src.isEmpty) return fallback;
    if (src.startsWith('http')) {
      return Image.network(src, fit: fit, errorBuilder: (_, __, ___) => fallback);
    }
    return Image.file(File(src), fit: fit, errorBuilder: (_, __, ___) => fallback);
  }
}