import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/singgah_event.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:singgah/features/home/presentation/bloc/home_bloc.dart';
import 'package:singgah/features/missions/presentation/widgets/mission_card.dart';
import 'package:singgah/features/titipan/presentation/widgets/titipan_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final now = DateTime.now();
        final name =
            context.watch<AuthBloc>().state.user?.displayName ?? l10n.demoUser;
        final greeting = switch (greetingKey(now)) {
          'morning' => l10n.greetingMorning,
          'afternoon' => l10n.greetingAfternoon,
          _ => l10n.greetingEvening,
        };
        final todays = state.todayMissions(now);
        final upNext = [...todays]
          ..sort((a, b) {
            final aInside = a.isInsideWindow(now) ? 0 : 1;
            final bInside = b.isInsideWindow(now) ? 0 : 1;
            if (aInside != bInside) return aInside - bInside;
            return a.windowStartMinutes.compareTo(b.windowStartMinutes);
          });
        final inbox = state.inbox.take(2).toList(growable: false);
        return RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(const HomeStarted());
          },
          child: PageScroll(
            children: [
              Text(
                greeting.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 2.2,
                  color: context.singgah.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: context.texts.displayMedium?.copyWith(height: 1.02),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.homeSubtitle,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.singgah.inkMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              if (state.failure)
                ErrorState(
                  onRetry: () =>
                      context.read<HomeBloc>().add(const HomeStarted()),
                )
              else if (state.loading)
                const LoadingState()
              else ...[
                _StatusBanner(state: state),
                const SizedBox(height: 16),
                _Metrics(state: state),
                const SizedBox(height: 24),
                SectionHeader(
                  title: l10n.nearestMissions,
                  eyebrow: l10n.todaySchedule,
                  action: TextButton(
                    onPressed: () => context.go('/missions'),
                    child: Text(l10n.viewAll),
                  ),
                ),
                if (upNext.isEmpty)
                  EmptyState(
                    icon: Icons.bolt_outlined,
                    title: l10n.noMissionsToday,
                    body: l10n.noMissionsBody,
                    compact: true,
                    action: FilledButton.tonalIcon(
                      onPressed: () => context.push('/missions/new'),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(l10n.createFirstMission),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final shown = upNext.take(wide ? 4 : 2).toList();
                      if (wide) {
                        final width = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final mission in shown)
                              SizedBox(
                                width: width,
                                child: MissionCard(
                                  mission: mission,
                                  place: state.placesById[mission.placeId],
                                  compact: true,
                                  onTap: () => context.push(
                                    '/missions/${mission.id}/edit',
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          for (final mission in shown) ...[
                            MissionCard(
                              mission: mission,
                              place: state.placesById[mission.placeId],
                              compact: true,
                              onTap: () =>
                                  context.push('/missions/${mission.id}/edit'),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: l10n.quickActions,
                  action: FilledButton.tonalIcon(
                    onPressed: () => context.push('/natural'),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: Text(l10n.quickNatural),
                  ),
                ),
                _QuickActions(),
                const SizedBox(height: 24),
                if (inbox.isNotEmpty) ...[
                  SectionHeader(
                    title: l10n.recentTitipan,
                    action: TextButton(
                      onPressed: () => context.go('/titipan'),
                      child: Text(l10n.viewAll),
                    ),
                  ),
                  for (final titipan in inbox) ...[
                    TitipanCard(
                      titipan: titipan,
                      inbox: true,
                      unread: true,
                      onTap: () => context.push('/titipan/${titipan.id}'),
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                ],
                SectionHeader(
                  title: l10n.recentHistory,
                  action: TextButton(
                    onPressed: () => context.go('/history'),
                    child: Text(l10n.viewAll),
                  ),
                ),
                if (state.events.isEmpty)
                  EmptyState(
                    icon: Icons.timeline_rounded,
                    title: l10n.noHistory,
                    body: l10n.noHistoryBody,
                    compact: true,
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < state.events.take(4).length;
                          i++
                        ) ...[
                          _EventLine(event: state.events.take(4).elementAt(i)),
                          if (i != state.events.take(4).length - 1)
                            const Divider(),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                AppCard(
                  background: context.singgah.navySoft,
                  borderColor: context.singgah.navy.withValues(alpha: 0.25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: context.singgah.navy,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.privacyCardTitle,
                              style: context.texts.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.privacyCardBody,
                              style: context.texts.bodySmall?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    if (kIsWeb) {
      return _line(
        context,
        icon: Icons.language_rounded,
        tone: colors.info,
        title: l10n.geofenceWebTitle,
        body: l10n.geofenceWebBody,
      );
    }
    if (!state.summary.isActive) {
      return _line(
        context,
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
    return _line(
      context,
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

  Widget _line(
    BuildContext context, {
    required IconData icon,
    required Color tone,
    required String title,
    required String body,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: AppRadius.allLg,
        border: Border.all(color: tone.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: tone),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: context.texts.bodySmall?.copyWith(height: 1.45),
                ),
                if (action != null) ...[const SizedBox(height: 2), action],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    final tiles = [
      MetricTile(
        label: l10n.activeMissions,
        value: '${state.activeMissions.length}',
        icon: Icons.bolt_rounded,
        tone: colors.accent,
      ),
      MetricTile(
        label: l10n.places,
        value: '${state.places.length}',
        icon: Icons.place_rounded,
        tone: colors.navy,
      ),
      MetricTile(
        label: l10n.locationReminders,
        value: '${state.summary.registered}',
        icon: Icons.radar_rounded,
        tone: colors.success,
      ),
      MetricTile(
        label: l10n.titipan,
        value: '${state.unreadInbox}',
        icon: Icons.mark_email_unread_rounded,
        tone: colors.warning,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tile in tiles)
                SizedBox(width: (constraints.maxWidth - 8) / 2, child: tile),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              Expanded(child: tiles[i]),
              if (i != tiles.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    final actions = [
      _QuickAction(
        label: l10n.quickPlace,
        icon: Icons.add_location_alt_outlined,
        tone: colors.navy,
        onTap: () => context.push('/places/new'),
      ),
      _QuickAction(
        label: l10n.quickMission,
        icon: Icons.bolt_outlined,
        tone: colors.accent,
        onTap: () => context.push('/missions/new'),
      ),
      _QuickAction(
        label: l10n.quickTitipan,
        icon: Icons.edit_note_rounded,
        tone: colors.success,
        onTap: () => context.push('/titipan/new'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 520
            ? constraints.maxWidth
            : (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: AppCard(
                  onTap: action.onTap,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: action.tone.withValues(alpha: 0.12),
                          borderRadius: AppRadius.allMd,
                        ),
                        child: Icon(action.icon, size: 17, color: action.tone),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          action.label,
                          style: context.texts.titleSmall,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: context.singgah.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.event});

  final SinggahEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final arrive = event.trigger == MissionTrigger.arrive;
    final tone = arrive ? context.singgah.success : context.singgah.navy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            arrive ? Icons.login_rounded : Icons.logout_rounded,
            size: 17,
            color: tone,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              event.placeName,
              style: context.texts.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatTime(event.occurredAt, l10n.locale.languageCode),
            style: context.texts.bodySmall,
          ),
        ],
      ),
    );
  }
}
