import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

abstract final class AppRadius {
  static const Radius sm = Radius.circular(10);
  static const Radius md = Radius.circular(14);
  static const Radius lg = Radius.circular(20);
  static const Radius xl = Radius.circular(28);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius allSm = BorderRadius.all(sm);
  static const BorderRadius allMd = BorderRadius.all(md);
  static const BorderRadius allLg = BorderRadius.all(lg);
  static const BorderRadius allXl = BorderRadius.all(xl);
  static const BorderRadius allPill = BorderRadius.all(pill);
}

@immutable
class SinggahColors extends ThemeExtension<SinggahColors> {
  const SinggahColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.navy,
    required this.navySoft,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.shadow,
    required this.mapTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color navy;
  final Color navySoft;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color shadow;
  final Color mapTint;

  @override
  SinggahColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? navy,
    Color? navySoft,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? shadow,
    Color? mapTint,
  }) {
    return SinggahColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      line: line ?? this.line,
      navy: navy ?? this.navy,
      navySoft: navySoft ?? this.navySoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      shadow: shadow ?? this.shadow,
      mapTint: mapTint ?? this.mapTint,
    );
  }

  @override
  SinggahColors lerp(covariant SinggahColors? other, double t) {
    if (other == null) return this;
    return SinggahColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      navySoft: Color.lerp(navySoft, other.navySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      mapTint: Color.lerp(mapTint, other.mapTint, t)!,
    );
  }
}

extension SinggahThemeContext on BuildContext {
  SinggahColors get singgah => Theme.of(this).extension<SinggahColors>()!;

  ColorScheme get scheme => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;
}

class AppTypography {
  AppTypography._();

  static const String sans = 'PlusJakartaSans';
  static const String serifFamily = 'InstrumentSerif';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle serif({
    double? fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    bool italic = false,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle numeric({
    double? fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: tabular,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const SinggahColors _dark = SinggahColors(
    background: Color(0xFF06101C),
    surface: Color(0xFF0C1A2A),
    surfaceElevated: Color(0xFF122337),
    surfaceMuted: Color(0xFF172C43),
    ink: Color(0xFFE9F0F7),
    inkMuted: Color(0xFF9EB0C4),
    line: Color(0xFF223A53),
    navy: Color(0xFF8CC0F2),
    navySoft: Color(0xFF122C46),
    accent: Color(0xFFFF9A5A),
    accentSoft: Color(0xFF3A2114),
    onAccent: Color(0xFF261006),
    success: Color(0xFF6FD3A0),
    successSoft: Color(0xFF103124),
    warning: Color(0xFFF2C14E),
    warningSoft: Color(0xFF33280D),
    danger: Color(0xFFFF8A80),
    dangerSoft: Color(0xFF3A1714),
    info: Color(0xFF84BEEA),
    shadow: Color(0x99000000),
    mapTint: Color(0xFF081726),
  );

  static const SinggahColors _light = SinggahColors(
    background: Color(0xFFF2F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE8EEF5),
    ink: Color(0xFF0A1A2F),
    inkMuted: Color(0xFF56677C),
    line: Color(0xFFD6DFEA),
    navy: Color(0xFF0D2A47),
    navySoft: Color(0xFFE1EAF4),
    accent: Color(0xFFC94F0E),
    accentSoft: Color(0xFFFDE9DC),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF12734A),
    successSoft: Color(0xFFDCF2E7),
    warning: Color(0xFF8A5A00),
    warningSoft: Color(0xFFFBEDC8),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFFBE3E1),
    info: Color(0xFF1F5D8C),
    shadow: Color(0x1A0A1A2F),
    mapTint: Color(0xFFEAF0F7),
  );

  static ThemeData get darkTheme => _theme(_dark, Brightness.dark);

  static ThemeData get lightTheme => _theme(_light, Brightness.light);

  static ThemeData _theme(SinggahColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final textTheme = TextTheme(
      displayLarge: AppTypography.serif(
        fontSize: 58,
        height: 0.98,
        letterSpacing: -0.6,
        color: colors.ink,
      ),
      displayMedium: AppTypography.serif(
        fontSize: 44,
        height: 1.0,
        letterSpacing: -0.4,
        color: colors.ink,
      ),
      displaySmall: AppTypography.serif(
        fontSize: 34,
        height: 1.05,
        letterSpacing: -0.2,
        color: colors.ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.1,
        letterSpacing: -0.9,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.15,
        letterSpacing: -0.6,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 21,
        height: 1.2,
        letterSpacing: -0.35,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.3,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15.5,
        height: 1.6,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w400,
        color: colors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: colors.ink,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: colors.inkMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 13.5,
        height: 1.2,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      labelMedium: TextStyle(
        fontSize: 11.5,
        height: 1.2,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
        color: colors.inkMuted,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        height: 1.2,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
        color: colors.inkMuted,
      ),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      primaryContainer: colors.accentSoft,
      onPrimaryContainer: isDark
          ? const Color(0xFFFFD9BF)
          : const Color(0xFF4A1A02),
      secondary: colors.navy,
      onSecondary: isDark ? const Color(0xFF04121F) : Colors.white,
      secondaryContainer: colors.navySoft,
      onSecondaryContainer: colors.navy,
      tertiary: colors.success,
      onTertiary: isDark ? const Color(0xFF062817) : Colors.white,
      tertiaryContainer: colors.successSoft,
      onTertiaryContainer: isDark
          ? const Color(0xFFB2F0CD)
          : const Color(0xFF07452B),
      error: colors.danger,
      onError: isDark ? const Color(0xFF2A0805) : Colors.white,
      errorContainer: colors.dangerSoft,
      onErrorContainer: isDark
          ? const Color(0xFFFFCDC7)
          : const Color(0xFF5F120D),
      surface: colors.surface,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.surfaceMuted,
      onSurfaceVariant: colors.inkMuted,
      outline: colors.line,
      outlineVariant: colors.line.withValues(alpha: 0.65),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: colors.ink,
      onInverseSurface: colors.background,
      inversePrimary: colors.accentSoft,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: AppTypography.sans,
      textTheme: textTheme,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerColor: colors.line,
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: 0.24),
        selectionHandleColor: colors.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: colors.accent),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.danger),
        border: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        prefixIconColor: colors.inkMuted,
        suffixIconColor: colors.inkMuted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          disabledBackgroundColor: colors.surfaceMuted,
          disabledForegroundColor: colors.inkMuted,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: colors.line),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.inkMuted,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        selectedColor: colors.accentSoft,
        disabledColor: colors.surfaceMuted,
        side: BorderSide(color: colors.line),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall!.copyWith(
            fontSize: 9.5,
            letterSpacing: 0.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? colors.ink : colors.inkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? colors.accent : colors.inkMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentSoft,
        selectedIconTheme: IconThemeData(color: colors.accent),
        unselectedIconTheme: IconThemeData(color: colors.inkMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.inkMuted,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: AppRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.65),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.xl),
        ),
        showDragHandle: true,
        dragHandleColor: colors.line,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.background,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colors.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        insetPadding: const EdgeInsets.all(16),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: AppRadius.allSm,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.background),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceMuted,
        circularTrackColor: colors.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.onAccent;
          return colors.inkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return colors.surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.line,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return colors.accentSoft;
            return colors.surfaceElevated;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return colors.accent;
            return colors.inkMuted;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: colors.line)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: colors.surfaceMuted,
        headerForegroundColor: colors.ink,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.surfaceElevated,
        dialBackgroundColor: colors.surfaceMuted,
        hourMinuteColor: colors.surfaceMuted,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.line),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.inkMuted,
        textColor: colors.ink,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
