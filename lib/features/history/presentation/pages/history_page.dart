import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/singgah_event.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/features/history/presentation/bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<HistoryBloc, HistoryState>(
      listenWhen: (previous, current) => current.failure != null,
      listener: (context, state) {
        if (state.failure == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.failure == HistoryFailure.clear
                  ? l10n.deleteFailed
                  : l10n.errorLoadData,
            ),
          ),
        );
        context.read<HistoryBloc>().clearFailure();
      },
      builder: (context, state) {
        final groups = _group(state.events, DateTime.now());
        return PageScroll(
          children: [
            PageHeader(
              eyebrow: l10n.history,
              title: l10n.history,
              subtitle: l10n.historySubtitle,
              trailing: state.events.isEmpty
                  ? const SizedBox.shrink()
                  : OutlinedButton.icon(
                      onPressed: state.clearing
                          ? null
                          : () => _confirmClear(context),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: Text(l10n.clearHistory),
                    ),
            ),
            const SizedBox(height: 16),
            ToneChip(
              label: l10n.historyLocalOnly,
              color: context.singgah.success,
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 18),
            if (state.loading)
              const LoadingState()
            else if (state.failure == HistoryFailure.load)
              ErrorState(
                onRetry: () =>
                    context.read<HistoryBloc>().add(const HistoryStarted()),
              )
            else if (state.events.isEmpty)
              EmptyState(
                icon: Icons.timeline_rounded,
                title: l10n.noHistory,
                body: l10n.noHistoryBody,
              )
            else
              for (final group in groups) ...[
                SectionHeader(title: group.label(l10n)),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < group.events.length; i++) ...[
                        _EventRow(event: group.events[i]),
                        if (i != group.events.length - 1) const Divider(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            Text(
              l10n.historyPrivacy,
              style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ],
        );
      },
    );
  }

  List<_HistoryGroup> _group(List<SinggahEvent> events, DateTime now) {
    final buckets = <String, List<SinggahEvent>>{};
    for (final event in events) {
      final key = relativeDay(event.occurredAt, now);
      buckets.putIfAbsent(key, () => []).add(event);
    }
    return [
      for (final key in ['today', 'yesterday', 'soon', 'older'])
        if (buckets[key] != null) _HistoryGroup(key, buckets[key]!),
    ];
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
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
    final success = await context.read<HistoryBloc>().clearHistory();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.historyCleared)));
    }
  }
}

class _HistoryGroup {
  const _HistoryGroup(this.key, this.events);

  final String key;
  final List<SinggahEvent> events;

  String label(AppLocalizations l10n) => switch (key) {
    'today' => l10n.today,
    'yesterday' => l10n.yesterday,
    'soon' => l10n.thisWeek,
    _ => l10n.older,
  };
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final SinggahEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    final arrive = event.trigger == MissionTrigger.arrive;
    final tone = arrive ? colors.success : colors.navy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(
              arrive ? Icons.login_rounded : Icons.logout_rounded,
              size: 17,
              color: tone,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.placeName,
                  style: context.texts.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${arrive ? l10n.arrived : l10n.left} · '
                  '${formatDateShort(event.occurredAt, l10n.locale.languageCode)}',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            formatTime(event.occurredAt, l10n.locale.languageCode),
            style: AppTypography.numeric(fontSize: 12, color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
