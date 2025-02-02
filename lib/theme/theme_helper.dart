import 'package:flutter/material.dart';

/// Tema renklerine kolay erişim için yardımcı sınıf
class ThemeHelper {
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Kullanım örnekleri:
  /// Container(
  ///   color: ThemeHelper.colorScheme(context).primary,
  /// )
  ///
  /// Text(
  ///   'Merhaba',
  ///   style: TextStyle(
  ///     color: ThemeHelper.colorScheme(context).onPrimary,
  ///   ),
  /// )
}
