import 'package:flutter/material.dart';

import '../../theme.dart';

/// The icon family.
///
/// One family, filled rather than outlined: Material's rounded set, which
/// ships with Flutter so nothing is downloaded or bundled. Leaf green marks
/// the active state; everything else is mono. No emoji.
enum PgIcons {
  home,
  grid,
  scan,
  chart,
  person,
  search,
  droplet,
  dropletDouble,
  sun,
  sunLow,
  thermometer,
  leaf,
  bell,
  calendar,
  camera,
  cloud,
  cloudRain,
  moon,
  wind,
  lock,
  star,
  pin,
  clock,
  image,
  flash,
  refresh,
  check,
  close,
  plus,
  minus,
  chevronLeft,
  chevronRight,
  chevronDown,
  arrowRight,
  sliders,
  dots,
  bookmark,
  share,
  pencil,
  alertTriangle,
  alertCircle,
  searchAlert,
  wifiOff,
  pause,
  mail,
  eye,
  eyeOff,
  help,
  info;

  /// The filled glyph for this icon.
  IconData get data => switch (this) {
        PgIcons.home => Icons.home_rounded,
        PgIcons.grid => Icons.grid_view_rounded,
        PgIcons.scan => Icons.center_focus_strong_rounded,
        PgIcons.chart => Icons.insights_rounded,
        PgIcons.person => Icons.person_rounded,
        PgIcons.search => Icons.search_rounded,
        PgIcons.droplet => Icons.water_drop_rounded,
        PgIcons.dropletDouble => Icons.water_rounded,
        PgIcons.sun => Icons.wb_sunny_rounded,
        PgIcons.sunLow => Icons.wb_twilight_rounded,
        PgIcons.thermometer => Icons.thermostat_rounded,
        PgIcons.leaf => Icons.eco_rounded,
        PgIcons.bell => Icons.notifications_rounded,
        PgIcons.calendar => Icons.calendar_month_rounded,
        PgIcons.camera => Icons.photo_camera_rounded,
        PgIcons.cloud => Icons.cloud_rounded,
        PgIcons.cloudRain => Icons.cloudy_snowing,
        PgIcons.moon => Icons.dark_mode_rounded,
        PgIcons.wind => Icons.air_rounded,
        PgIcons.lock => Icons.lock_rounded,
        PgIcons.star => Icons.star_rounded,
        PgIcons.pin => Icons.location_on_rounded,
        PgIcons.clock => Icons.access_time_filled_rounded,
        PgIcons.image => Icons.image_rounded,
        PgIcons.flash => Icons.flash_on_rounded,
        PgIcons.refresh => Icons.refresh_rounded,
        PgIcons.check => Icons.check_rounded,
        PgIcons.close => Icons.close_rounded,
        PgIcons.plus => Icons.add_rounded,
        PgIcons.minus => Icons.remove_rounded,
        PgIcons.chevronLeft => Icons.chevron_left_rounded,
        PgIcons.chevronRight => Icons.chevron_right_rounded,
        PgIcons.chevronDown => Icons.expand_more_rounded,
        PgIcons.arrowRight => Icons.arrow_forward_rounded,
        PgIcons.sliders => Icons.tune_rounded,
        PgIcons.dots => Icons.more_horiz_rounded,
        PgIcons.bookmark => Icons.bookmark_rounded,
        PgIcons.share => Icons.share_rounded,
        PgIcons.pencil => Icons.edit_rounded,
        PgIcons.alertTriangle => Icons.warning_rounded,
        PgIcons.alertCircle => Icons.error_rounded,
        PgIcons.searchAlert => Icons.search_off_rounded,
        PgIcons.wifiOff => Icons.wifi_off_rounded,
        PgIcons.pause => Icons.pause_circle_filled_rounded,
        PgIcons.mail => Icons.email_rounded,
        PgIcons.eye => Icons.visibility_rounded,
        PgIcons.eyeOff => Icons.visibility_off_rounded,
        PgIcons.help => Icons.help_rounded,
        PgIcons.info => Icons.info_rounded,
      };
}

/// Draws a [PgIcons] glyph at [size], in [color].
class PgIcon extends StatelessWidget {
  const PgIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color = AppColors.ink,
    this.strokeWidth,
  });

  final PgIcons icon;
  final double size;
  final Color color;

  /// Kept for call sites written against the earlier outlined family; a
  /// filled glyph has no stroke, so it is ignored.
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Icon(icon.data, size: size, color: color),
    );
  }
}
