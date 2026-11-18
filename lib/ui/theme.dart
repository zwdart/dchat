import 'package:flutter/material.dart';

import '../core/models.dart';

class AppColors {
  final Color background;
  final Color sidebar;
  final Color panel;
  final Color text;
  final Color muted;
  final Color faint;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color bubbleIn;
  final Color bubbleOut;

  const AppColors({
    required this.background,
    required this.sidebar,
    required this.panel,
    required this.text,
    required this.muted,
    required this.faint,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.bubbleIn,
    required this.bubbleOut,
  });

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    sidebar: Color(0xFFF3F3F7),
    panel: Color(0xFFF7F7FA),
    text: Color(0xFF1D1D1F),
    muted: Color(0xFF6E6E78),
    faint: Color(0xFF9A9AA4),
    border: Color(0xFFE4E4EA),
    accent: Color(0xFF4C6FFF),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFE5484D),
    bubbleIn: Color(0xFFF1F1F5),
    bubbleOut: Color(0xFF4C6FFF),
  );

  static const dark = AppColors(
    background: Color(0xFF141416),
    sidebar: Color(0xFF1B1B1F),
    panel: Color(0xFF232327),
    text: Color(0xFFF5F5F7),
    muted: Color(0xFFA0A0AB),
    faint: Color(0xFF72727E),
    border: Color(0xFF2E2E34),
    accent: Color(0xFF7088FF),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFFF6369),
    bubbleIn: Color(0xFF25252B),
    bubbleOut: Color(0xFF3F58D8),
  );
}

AppColors appColors(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

ThemeData buildAppTheme({
  required Brightness brightness,
  TargetPlatform? platform,
}) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: Colors.white,
    surface: c.background,
    onSurface: c.text,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    platform: platform,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: c.text,
      displayColor: c.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: c.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: c.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.sidebar,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accent.withValues(alpha: 0.16),
      height: 66,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.panel,
      hintStyle: TextStyle(color: c.faint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.4),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.muted,
      textColor: c.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      contentTextStyle: TextStyle(color: c.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.accent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.faint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.accent.withValues(alpha: 0.35)
            : c.border,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
  );
}

Color presenceColor(Presence status, AppColors c) {
  switch (status) {
    case Presence.online:
      return const Color(0xFF32C46B);
    case Presence.away:
      return const Color(0xFFF5A524);
    case Presence.busy:
      return const Color(0xFFE5484D);
    case Presence.dnd:
      return const Color(0xFFC026D3);
    case Presence.invisible:
      return c.faint;
    case Presence.offline:
      return c.faint;
  }
}

Color avatarColor(String seed, AppColors c) {
  const palette = [
    Color(0xFF4C6FFF),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
  ];
  if (seed.isEmpty) return c.faint;
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}
