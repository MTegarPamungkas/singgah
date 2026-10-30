import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/features/missions/presentation/bloc/missions_bloc.dart';
import 'package:singgah/features/missions/presentation/widgets/mission_card.dart';

class MissionsPage extends StatelessWidget {
  const MissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<MissionsBloc, MissionsState>(
      listenWhen: (previous, current) => current.failure != null,
      listener: (context, state) {
        if (state.failure == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.failure == MissionsFailure.delete
                  ? l10n.deleteFailed
                  : l10n.errorLoadData,
            ),
          ),
        );
        context.read<MissionsBloc>().clearFailure();
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<MissionsBloc>().add(const MissionsStarted());
          },
          child: PageScroll(
            children: [
              PageHeader(
                eyebrow: l10n.missions,
                title: l10n.activeMissions,
                subtitle: l10n.missionsSubtitle,
                trailing: FilledButton.icon(
                  onPressed: () => context.push('/missions/new'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.newMission),
                ),
              ),
              const SizedBox(height: 18),
              _GeofenceBanner(state: state),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<MissionFilter>(
                      segments: [
                        ButtonSegment(
                          value: MissionFilter.all,
                          label: Text(l10n.filterAll),
                        ),
                        ButtonSegment(
                          value: MissionFilter.active,
                          label: Text(l10n.filterActive),
                        ),
                        ButtonSegment(
                          value: MissionFilter.paused,
                          label: Text(l10n.filterPaused),
                        ),
                      ],
                      selected: {state.filter},
                      onSelectionChanged: (value) =>
                          context.read<MissionsBloc>().setFilter(value.first),
                      showSelectedIcon: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.loading)
                const LoadingState()
              else if (state.failure == MissionsFailure.load)
                ErrorState(
                  onRetry: () =>
                      context.read<MissionsBloc>().add(const MissionsStarted()),
                )
              else if (state.filtered.isEmpty)
                EmptyState(
                  icon: Icons.bolt_outlined,
                  title: l10n.noMissions,
                  body: state.places.isEmpty
                      ? l10n.noPlacesBody
                      : l10n.noMissionsBody,
                  action: FilledButton.icon(
                    onPressed: () => state.places.isEmpty
                        ? context.push('/places/new')
                        : context.push('/missions/new'),
                    icon: Icon(
                      state.places.isEmpty
                          ? Icons.add_location_alt_outlined
                          : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(
                      state.places.isEmpty
                          ? l10n.addPlace
                          : l10n.createFirstMission,
                    ),
                  ),
                )
              else
                for (final mission in state.filtered) ...[
                  MissionCard(
                    mission: mission,
                    place: state.placesById[mission.placeId],
                    onTap: () => context.push('/missions/${mission.id}/edit'),
                    onToggle: (value) => context.read<MissionsBloc>().toggle(
                      mission.copyWith(isActive: value),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _GeofenceBanner extends StatelessWidget {
  const _GeofenceBanner({required this.state});

  final MissionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    if (kIsWeb || !AppConfig.supportsGeofencing) {
      return _Banner(
        icon: Icons.language_rounded,
        tone: colors.info,
        title: l10n.geofenceWebTitle,
        body: l10n.geofenceWebBody,
      );
    }
    if (state.summary.skipped > 0) {
      return _Banner(
        icon: Icons.warning_amber_rounded,
        tone: colors.warning,
        title: l10n.geofenceLimitReached,
        body: l10n.registeredGeofences(state.summary.registered),
      );
    }
    if (!state.summary.isActive) {
      return _Banner(
        icon: Icons.location_off_outlined,
        tone: colors.warning,
        title: l10n.locationPausedTitle,
        body: l10n.locationPausedBody,
        action: TextButton(
          onPressed: () => context.push('/permissions'),
          child: Text(l10n.managePermissions),
        ),
      );
    }
    return _Banner(
      icon: Icons.radar_rounded,
      tone: colors.success,
      title: l10n.registeredGeofences(state.summary.registered),
      body: l10n.locationRemindersBody,
      action: TextButton(
        onPressed: () => context.push('/permissions'),
        child: Text(l10n.permissions),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: AppRadius.allLg,
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.titleSmall),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: context.texts.bodySmall?.copyWith(height: 1.45),
                ),
                if (action != null) ...[const SizedBox(height: 4), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
