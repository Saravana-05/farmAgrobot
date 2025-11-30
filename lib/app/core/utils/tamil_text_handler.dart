import 'dart:convert';

import 'package:flutter/material.dart';

class TamilTextHandler {
  /// Simple method to fix Tamil text encoding issues
  static String decodeTamilText(String text) {
    if (text.isEmpty) return text;
    
    try {
      // Fix double-encoded UTF-8 Tamil text
      final bytes = latin1.encode(text);
      return utf8.decode(bytes);
    } catch (e) {
      return text; // Return original if decoding fails
    }
  }
}

class TamilText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const TamilText(
    this.text, {
    Key? key,
    this.style,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Decode Tamil text
    final decodedText = TamilTextHandler.decodeTamilText(text);
    
    return Text(
      decodedText,
      style: (style ?? const TextStyle()).copyWith(
        fontFamily: 'NotoSansTamil', // Make sure you add this font to pubspec.yaml
        fontFamilyFallback: const ['Tamil Sangam MN', 'Latha', 'sans-serif'],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}