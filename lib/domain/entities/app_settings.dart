import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.localeCode = 'id',
    this.biometricLock = false,
    this.onboardingCompleted = false,
    this.locationRemindersEnabled = true,
    this.defaultRadiusMeters = 150,
    this.keepHistory = true,
  });

  final AppThemeMode themeMode;
  final String localeCode;
  final bool biometricLock;
  final bool onboardingCompleted;
  final bool locationRemindersEnabled;
  final int defaultRadiusMeters;
  final bool keepHistory;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? localeCode,
    bool? biometricLock,
    bool? onboardingCompleted,
    bool? locationRemindersEnabled,
    int? defaultRadiusMeters,
    bool? keepHistory,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      biometricLock: biometricLock ?? this.biometricLock,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      locationRemindersEnabled:
          locationRemindersEnabled ?? this.locationRemindersEnabled,
      defaultRadiusMeters: defaultRadiusMeters ?? this.defaultRadiusMeters,
      keepHistory: keepHistory ?? this.keepHistory,
    );
  }

  Map<String, dynamic> toMap() => {
    'theme_mode': themeMode.name,
    'locale_code': localeCode,
    'biometric_lock': biometricLock,
    'onboarding_completed': onboardingCompleted,
    'location_reminders_enabled': locationRemindersEnabled,
    'default_radius_meters': defaultRadiusMeters,
    'keep_history': keepHistory,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final theme = map['theme_mode']?.toString();
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.name == theme,
        orElse: () => AppThemeMode.system,
      ),
      localeCode: map['locale_code']?.toString() == 'en' ? 'en' : 'id',
      biometricLock: map['biometric_lock'] == true,
      onboardingCompleted: map['onboarding_completed'] == true,
      locationRemindersEnabled: map['location_reminders_enabled'] != false,
      defaultRadiusMeters:
          int.tryParse(map['default_radius_meters']?.toString() ?? '') ?? 150,
      keepHistory: map['keep_history'] != false,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    localeCode,
    biometricLock,
    onboardingCompleted,
    locationRemindersEnabled,
    defaultRadiusMeters,
    keepHistory,
  ];
}
