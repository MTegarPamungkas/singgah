import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/app/app_maintenance.dart';
import 'package:singgah/app/invite_intent.dart';
import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/responsive/app_breakpoints.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/singgah_mark.dart';
import 'package:singgah/domain/entities/sync_status.dart';
import 'package:singgah/domain/services/deep_link_service.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:singgah/features/sync/presentation/bloc/sync_bloc.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  Timer? _maintenanceTimer;
  bool _maintenanceRunning = false;
  StreamSubscription<String>? _inviteSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runMaintenance());
    _maintenanceTimer = Timer.periodic(
      const Duration(minutes: 20),
      (_) => _runMaintenance(),
    );
    _listenForInvites();
  }

  Future<void> _listenForInvites() async {
    final links = getIt<DeepLinkService>();
    final initial = await links.initialInviteToken();
    if (initial != null) _openInvite(initial);
    _inviteSubscription = links.inviteTokens.listen(_openInvite);
  }

  void _openInvite(String token) {
    if (!mounted) return;
    if (!getIt<AuthBloc>().state.signedIn) {
      InviteIntent.remember(token);
      return;
    }
    context.push('/invite/$token');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runMaintenance();
  }

  Future<void> _runMaintenance() async {
    if (!mounted || _maintenanceRunning) return;
    _maintenanceRunning = true;
    try {
      await getIt<AppMaintenance>().run();
    } catch (_) {
      // Maintenance never blocks the user.
    } finally {
      _maintenanceRunning = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _maintenanceTimer?.cancel();
    _inviteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usesSide = context.usesSideNavigation;
    final index = widget.navigationShell.currentIndex;
    final destinations = _destinations(context.l10n);
    return Scaffold(
      body: Row(
        children: [
          if (usesSide)
            _SideNavigation(
              index: index,
              destinations: destinations,
              expanded: MediaQuery.sizeOf(context).width >= 1180,
              onSelect: _onSelect,
            ),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    title: destinations[index].label,
                    eyebrow: context.l10n.appName,
                    compact: !usesSide,
                    onSettings: () => context.push('/settings'),
                    onProfile: () => context.push('/profile'),
                  ),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: usesSide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _onSelect,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  void _onSelect(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  List<_Destination> _destinations(AppLocalizations l10n) => [
    _Destination(
      label: l10n.home,
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
    ),
    _Destination(
      label: l10n.places,
      icon: Icons.place_outlined,
      selectedIcon: Icons.place_rounded,
    ),
    _Destination(
      label: l10n.missions,
      icon: Icons.bolt_outlined,
      selectedIcon: Icons.bolt_rounded,
    ),
    _Destination(
      label: l10n.titipan,
      icon: Icons.mark_email_unread_outlined,
      selectedIcon: Icons.mark_email_unread_rounded,
    ),
    _Destination(
      label: l10n.history,
      icon: Icons.timeline_outlined,
      selectedIcon: Icons.timeline_rounded,
    ),
  ];
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.eyebrow,
    required this.compact,
    required this.onSettings,
    required this.onProfile,
  });

  final String title;
  final String eyebrow;
  final bool compact;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final edge = compact ? 16.0 : 28.0;
    final width = MediaQuery.sizeOf(context).width;
    final showSyncChip = width >= 380;
    final showNatural = width >= 560;
    return Container(
      padding: EdgeInsets.fromLTRB(
        edge,
        compact ? 12 : 16,
        edge,
        compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: context.singgah.background.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: context.singgah.line.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Row(
        children: [
          if (compact) ...[
            const SinggahMark(size: 34, showShadow: false),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 1.8,
                    fontSize: 8,
                    color: context.singgah.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: compact
                      ? context.texts.titleLarge?.copyWith(fontSize: 20)
                      : context.texts.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (showSyncChip) ...[const _SyncChip(), const SizedBox(width: 4)],
          if (showNatural)
            IconButton(
              tooltip: context.l10n.quickNatural,
              onPressed: () => context.push('/natural'),
              icon: const Icon(Icons.auto_awesome_rounded),
            ),
          IconButton(
            tooltip: context.l10n.openSettings,
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final name = state.user?.displayName ?? context.l10n.demoUser;
              return Tooltip(
                message: name,
                child: InkWell(
                  onTap: onProfile,
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: context.singgah.accentSoft,
                    child: Text(
                      state.user?.initials ?? '?',
                      style: context.texts.labelMedium?.copyWith(
                        color: context.singgah.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.index,
    required this.destinations,
    required this.expanded,
    required this.onSelect,
  });

  final int index;
  final List<_Destination> destinations;
  final bool expanded;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 224 : 84,
      decoration: BoxDecoration(
        color: context.singgah.surface,
        border: Border(right: BorderSide(color: context.singgah.line)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 18 : 20,
                20,
                expanded ? 18 : 20,
                22,
              ),
              child: expanded
                  ? Row(
                      children: [
                        const SinggahMark(size: 38),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConfig.appName.toUpperCase(),
                                style: context.texts.labelSmall?.copyWith(
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                  color: context.singgah.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.taglineShort,
                                style: context.texts.bodySmall?.copyWith(
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(child: SinggahMark(size: 38)),
            ),
            for (var i = 0; i < destinations.length; i++)
              _NavItem(
                destination: destinations[i],
                selected: i == index,
                expanded: expanded,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12),
              child: const Divider(),
            ),
            _SettingsItem(expanded: expanded),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 14 : 10,
                8,
                expanded ? 14 : 10,
                16,
              ),
              child: const _SyncChip(side: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? context.singgah.accent
        : context.singgah.inkMuted;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 9, vertical: 3),
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? context.singgah.accentSoft : Colors.transparent,
            borderRadius: AppRadius.allMd,
            border: Border.all(
              color: selected
                  ? context.singgah.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 20,
                      color: foreground,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        style: context.texts.labelLarge?.copyWith(
                          color: selected
                              ? context.singgah.ink
                              : context.singgah.inkMuted,
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.singgah.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                )
              : Tooltip(
                  message: destination.label,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 21,
                    color: foreground,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 9, vertical: 2),
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: () => context.push('/settings'),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 12,
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: context.singgah.inkMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.settings,
                      style: context.texts.labelLarge?.copyWith(
                        color: context.singgah.inkMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                )
              : Tooltip(
                  message: context.l10n.settings,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 21,
                    color: context.singgah.inkMuted,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({this.side = false});

  final bool side;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncStatus>(
      builder: (context, status) {
        final l10n = context.l10n;
        final (label, icon, tone) = switch (status.phase) {
          SyncPhase.demo => (
            l10n.demoMode,
            Icons.science_outlined,
            context.singgah.accent,
          ),
          SyncPhase.syncing => (
            l10n.syncing,
            Icons.sync_rounded,
            context.singgah.info,
          ),
          SyncPhase.offline => (
            l10n.offline,
            Icons.cloud_off_rounded,
            context.singgah.inkMuted,
          ),
          SyncPhase.error => (
            l10n.connectionProblem,
            Icons.error_outline_rounded,
            context.singgah.danger,
          ),
          SyncPhase.idle =>
            status.pendingCount > 0
                ? (
                    '${status.pendingCount}',
                    Icons.cloud_upload_outlined,
                    context.singgah.accent,
                  )
                : (
                    l10n.synced,
                    Icons.cloud_done_outlined,
                    context.singgah.success,
                  ),
        };
        return Tooltip(
          message: l10n.syncNow,
          child: InkWell(
            borderRadius: AppRadius.allPill,
            onTap: status.isBusy
                ? null
                : () => context.read<SyncBloc>().syncNow(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: side ? 9 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.1),
                borderRadius: AppRadius.allPill,
                border: Border.all(color: tone.withValues(alpha: 0.24)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status.isBusy)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.7,
                        color: tone,
                      ),
                    )
                  else
                    Icon(icon, size: 13, color: tone),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: side ? 120 : 80),
                    child: Text(
                      label,
                      style: context.texts.labelSmall?.copyWith(
                        color: tone,
                        fontSize: 8.5,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
