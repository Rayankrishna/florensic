import 'package:flutter/widgets.dart';

/// The design is drawn at 390 × 844 (iPhone 14). These helpers keep the
/// proportions of the specification without pinning the layout to one device.
class Responsive {
  const Responsive._();

  static const double designWidth = 390;

  /// Scales a design-space value to the current width, with sane bounds so
  /// small phones stay legible and large ones do not balloon.
  static double scale(BuildContext context, double value,
      {double min = 0.88, double max = 1.16}) {
    final width = MediaQuery.sizeOf(context).width;
    final factor = (width / designWidth).clamp(min, max);
    return value * factor;
  }

  /// Text scaling is left to the platform, but very large settings are capped
  /// so cards keep their shape.
  static double textScale(BuildContext context, {double cap = 1.25}) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler.scale(1).clamp(1.0, cap);
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  static bool isShort(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 700;
}
