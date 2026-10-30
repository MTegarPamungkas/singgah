import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/domain/entities/app_settings.dart';
import 'package:singgah/domain/entities/sync_status.dart';
import 'package:singgah/domain/usecases/device_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:singgah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:singgah/features/sync/presentation/bloc/sync_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    final user = context.watch<AuthBloc>().state.user;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.settings),
      ),
      body: PageScroll(
        maxWidth: 820,
        top: 10,
        children: [
          _AccountCard(
            name: user?.displayName ?? l10n.demoUser,
            email: user?.email ?? l10n.demoModeBody,
            initials: user?.initials ?? '?',
            demo: user?.isDemo ?? true,
            onProfile: () => context.push('/profile'),
          ),
          const SizedBox(height: 16),
          _Section(title: l10n.appearance, icon: Icons.palette_outlined),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Label(l10n.theme),
                const SizedBox(height: 8),
                SegmentedButton<AppThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (value) =>
                      context.read<SettingsBloc>().setThemeMode(value.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                _Label(l10n.language),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'id', label: Text('Bahasa Indonesia')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {settings.localeCode},
                  onSelectionChanged: (value) =>
                      context.read<SettingsBloc>().setLocale(value.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(title: l10n.privacy, icon: Icons.lock_outline_rounded),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: settings.biometricLock,
                  onChanged: (value) => _setBiometric(context, value),
                  title: Text(l10n.biometricLock),
                  subtitle: Text(l10n.biometricBody),
                  secondary: const Icon(Icons.fingerprint_rounded),
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  value: settings.keepHistory,
                  onChanged: (value) =>
                      context.read<SettingsBloc>().setKeepHistory(value),
                  title: Text(l10n.keepHistoryLabel),
                  subtitle: Text(l10n.keepHistoryBody),
                  secondary: const Icon(Icons.timeline_rounded),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.my_location_rounded),
                  title: Text(l10n.defaultRadius),
                  subtitle: Text(
                    l10n.radiusHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    l10n.radiusValue(settings.defaultRadiusMeters),
                    style: AppTypography.numeric(
                      fontSize: 13,
                      color: context.singgah.accent,
                    ),
                  ),
                  onTap: () =>
                      _pickRadius(context, settings.defaultRadiusMeters),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l10n.permissions),
                  subtitle: Text(l10n.permissionsBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/permissions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(title: l10n.sync, icon: Icons.cloud_sync_outlined),
          const _SyncCard(),
          const SizedBox(height: 16),
          _Section(title: l10n.account, icon: Icons.person_outline_rounded),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l10n.editProfile),
                  subtitle: Text(l10n.profileSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.exportData),
                  subtitle: Text(l10n.exportDataBody),
                  onTap: () => _export(context),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: context.singgah.danger,
                  ),
                  title: Text(
                    l10n.deleteAccountData,
                    style: TextStyle(color: context.singgah.danger),
                  ),
                  subtitle: Text(l10n.deleteAccountDataBody),
                  onTap: () => _clearLocal(context),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: context.singgah.danger,
                  ),
                  title: Text(
                    l10n.signOut,
                    style: TextStyle(color: context.singgah.danger),
                  ),
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(title: l10n.about, icon: Icons.info_outline_rounded),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppConfig.hasAppwrite
                            ? context.singgah.success.withValues(alpha: 0.12)
                            : context.singgah.accentSoft,
                        borderRadius: AppRadius.allPill,
                      ),
                      child: Text(
                        AppConfig.hasAppwrite
                            ? l10n.cloudConnected
                            : l10n.cloudDemo,
                        style: context.texts.labelSmall?.copyWith(
                          color: AppConfig.hasAppwrite
                              ? context.singgah.success
                              : context.singgah.accent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) => Text(
                        '${l10n.version} ${snapshot.data?.version ?? '1.0.0'}',
                        style: context.texts.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.madeFor,
                  style: context.texts.bodySmall?.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setBiometric(BuildContext context, bool value) async {
    final l10n = context.l10n;
    if (value) {
      final available = await getIt<CheckBiometrics>()();
      if (!available) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.biometricUnavailable)));
        return;
      }
    }
    if (!context.mounted) return;
    context.read<SettingsBloc>().setBiometric(value);
  }

  Future<void> _pickRadius(BuildContext context, int current) async {
    var value = current.toDouble();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.defaultRadius),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.radiusValue(value.round()),
                style: AppTypography.numeric(
                  fontSize: 22,
                  color: context.singgah.accent,
                ),
              ),
              Slider(
                value: value,
                min: 100,
                max: 2000,
                divisions: 19,
                onChanged: (next) => setState(() => value = next),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(value.round()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    context.read<SettingsBloc>().setRadius(result);
  }

  Future<void> _signOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthBloc>().signOut();
    if (!context.mounted) return;
    context.go('/auth');
  }

  Future<void> _clearLocal(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountData),
        content: Text(l10n.deleteAccountDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await getIt<LocalStore>().clearUserData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.dataCleared)));
  }

  Future<void> _export(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final places = await getIt<GetPlaces>()();
      final missions = await getIt<GetMissions>()();
      final feed = await getIt<GetTitipanFeed>()();
      final payload = jsonEncode({
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'places': [
          for (final place in places)
            {
              'name': place.name,
              'address': place.address,
              'latitude': place.latitude,
              'longitude': place.longitude,
              'radius_meters': place.radiusMeters,
            },
        ],
        'missions': [
          for (final mission in missions)
            {
              'title': mission.title,
              'note': mission.note,
              'trigger': mission.trigger.name,
              'repeat_days': (mission.repeatDays.toList()..sort()),
              'window_start': minutesToClock(mission.windowStartMinutes),
              'window_end': minutesToClock(mission.windowEndMinutes),
              'active': mission.isActive,
            },
        ],
        'titipan': [
          for (final titipan in feed.titipans)
            {
              'title': titipan.title,
              'body': titipan.body,
              'place': titipan.placeName,
              'trigger': titipan.trigger.name,
            },
        ],
      });
      await SharePlus.instance.share(
        ShareParams(text: payload, subject: 'Singgah export'),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorSaveData)));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 17, color: context.singgah.accent),
          const SizedBox(width: 7),
          Text(title, style: context.texts.titleMedium),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.texts.labelMedium?.copyWith(
        color: context.singgah.inkMuted,
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.demo,
    required this.onProfile,
  });

  final String name;
  final String email;
  final String initials;
  final bool demo;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.singgah;
    return AppCard(
      onTap: onProfile,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colors.accentSoft,
            child: Text(
              initials,
              style: context.texts.titleMedium?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.texts.titleLarge),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: context.texts.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ToneChip(
            label: demo ? context.l10n.demoMode : context.l10n.cloudConnected,
            color: demo ? colors.accent : colors.success,
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<SyncBloc, SyncStatus>(
      builder: (context, status) {
        final colors = context.singgah;
        final (label, tone) = switch (status.phase) {
          SyncPhase.demo => (l10n.demoMode, colors.accent),
          SyncPhase.syncing => (l10n.syncing, colors.info),
          SyncPhase.offline => (l10n.offline, colors.inkMuted),
          SyncPhase.error => (l10n.connectionProblem, colors.danger),
          SyncPhase.idle => (
            status.pendingCount > 0
                ? l10n.pendingChanges(status.pendingCount)
                : l10n.synced,
            status.pendingCount > 0 ? colors.accent : colors.success,
          ),
        };
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: status.isBusy
                        ? CircularProgressIndicator(strokeWidth: 2, color: tone)
                        : Icon(
                            Icons.cloud_done_outlined,
                            size: 20,
                            color: tone,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: context.texts.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          status.lastSyncedAt == null
                              ? l10n.neverSynced
                              : l10n.lastSync(
                                  formatDateTime(
                                    status.lastSyncedAt!,
                                    l10n.locale.languageCode,
                                  ),
                                ),
                          style: context.texts.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: status.isBusy
                        ? null
                        : () => context.read<SyncBloc>().syncNow(),
                    child: Text(l10n.syncNow),
                  ),
                ],
              ),
              if (status.phase == SyncPhase.offline) ...[
                const SizedBox(height: 8),
                Text(l10n.syncOfflineBody, style: context.texts.bodySmall),
              ],
            ],
          ),
        );
      },
    );
  }
}
