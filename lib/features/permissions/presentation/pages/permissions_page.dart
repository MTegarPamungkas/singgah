import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/core/widgets/singgah_mark.dart';
import 'package:singgah/features/permissions/presentation/bloc/permissions_bloc.dart';
import 'package:singgah/features/settings/presentation/bloc/settings_bloc.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onboarding = !context.watch<SettingsBloc>().state.onboardingCompleted;
    return Scaffold(
      appBar: onboarding
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: l10n.back,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(l10n.permissions),
            ),
      body: BlocBuilder<PermissionsBloc, PermissionsState>(
        builder: (context, state) {
          return PageScroll(
            maxWidth: 640,
            top: onboarding ? 40 : 10,
            children: [
              if (onboarding) ...[
                const Center(child: SinggahMark(size: 58)),
                const SizedBox(height: 26),
              ],
              Text(
                l10n.onboardingEyebrow,
                textAlign: onboarding ? TextAlign.center : TextAlign.start,
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 2.4,
                  color: context.singgah.accent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.onboardingTitle,
                textAlign: onboarding ? TextAlign.center : TextAlign.start,
                style: context.texts.displaySmall?.copyWith(
                  fontSize: onboarding ? 30 : 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingBody,
                textAlign: onboarding ? TextAlign.center : TextAlign.start,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.singgah.inkMuted,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 24),
              if (state.loading)
                const LoadingState()
              else if (!AppConfig.supportsGeofencing)
                AppCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: 30,
                        color: context.singgah.info,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.geofenceWebTitle,
                        textAlign: TextAlign.center,
                        style: context.texts.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.permissionOnlyAndroid,
                        textAlign: TextAlign.center,
                        style: context.texts.bodySmall?.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                )
              else ...[
                _StepCard(
                  index: 1,
                  title: l10n.permissionStepLocation,
                  heading: l10n.permissionForeground,
                  body: l10n.permissionForegroundBody,
                  granted: state.foregroundGranted,
                  busy: state.busy,
                  onAllow: () => context.read<PermissionsBloc>().add(
                    const PermissionsForegroundRequested(),
                  ),
                ),
                const SizedBox(height: 10),
                _StepCard(
                  index: 2,
                  title: l10n.permissionStepBackground,
                  heading: l10n.permissionBackground,
                  body: l10n.permissionBackgroundBody,
                  granted: state.backgroundGranted,
                  busy: state.busy || !state.foregroundGranted,
                  onAllow: () => context.read<PermissionsBloc>().add(
                    const PermissionsBackgroundRequested(),
                  ),
                ),
                const SizedBox(height: 10),
                _StepCard(
                  index: 3,
                  title: l10n.permissionStepNotifications,
                  heading: l10n.permissionNotifications,
                  body: l10n.permissionNotificationsBody,
                  granted: state.notificationsGranted,
                  busy: state.busy,
                  onAllow: () => context.read<PermissionsBloc>().add(
                    const PermissionsNotificationRequested(),
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            state.serviceEnabled
                                ? Icons.gps_fixed_rounded
                                : Icons.gps_off_rounded,
                            size: 20,
                            color: state.serviceEnabled
                                ? context.singgah.success
                                : context.singgah.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.locationServices,
                                  style: context.texts.titleSmall,
                                ),
                                Text(
                                  state.serviceEnabled
                                      ? l10n.permissionGranted
                                      : l10n.gpsOffBody,
                                  style: context.texts.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (!state.serviceEnabled)
                            TextButton(
                              onPressed: () => context.read<PermissionsBloc>().add(
                                const PermissionsOpenLocationSettingsRequested(),
                              ),
                              child: Text(l10n.openSettings),
                            ),
                        ],
                      ),
                      if (state.summary.isActive) ...[
                        const Divider(height: 22),
                        Row(
                          children: [
                            Icon(
                              Icons.radar_rounded,
                              size: 20,
                              color: context.singgah.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.registeredGeofences(
                                  state.summary.registered,
                                ),
                                style: context.texts.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context
                                  .read<PermissionsBloc>()
                                  .add(const PermissionsRefreshRequested()),
                              child: Text(l10n.refresh),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.permissionExplanation,
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => context.read<PermissionsBloc>().add(
                    const PermissionsOpenSettingsRequested(),
                  ),
                  icon: const Icon(Icons.settings_outlined, size: 17),
                  label: Text(l10n.openSystemSettings),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _finish(context, onboarding),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(onboarding ? l10n.finishSetup : l10n.done),
              ),
              if (onboarding) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => _finish(context, onboarding),
                  child: Text(l10n.skipForNow),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _finish(BuildContext context, bool onboarding) async {
    final settings = context.read<SettingsBloc>().state;
    if (!settings.onboardingCompleted) {
      await context.read<SettingsBloc>().completeOnboarding();
    }
    if (!context.mounted) return;
    if (onboarding) {
      context.go('/home');
      return;
    }
    context.pop();
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.heading,
    required this.body,
    required this.granted,
    required this.busy,
    required this.onAllow,
  });

  final int index;
  final String title;
  final String heading;
  final String body;
  final bool granted;
  final bool busy;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = granted ? context.singgah.success : context.singgah.accent;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: granted
                ? Icon(Icons.check_rounded, size: 17, color: tone)
                : Text(
                    '$index',
                    style: context.texts.labelMedium?.copyWith(color: tone),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: context.texts.labelSmall),
                const SizedBox(height: 3),
                Text(heading, style: context.texts.titleSmall),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: context.texts.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 8),
                if (granted)
                  ToneChip(
                    label: l10n.permissionGranted,
                    color: tone,
                    icon: Icons.check_rounded,
                  )
                else
                  FilledButton.tonal(
                    onPressed: busy ? null : onAllow,
                    child: Text(l10n.allowNow),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
