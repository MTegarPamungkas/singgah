import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/sync_status.dart';
import 'package:singgah/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:singgah/features/titipan/presentation/bloc/titipan_bloc.dart';
import 'package:singgah/features/titipan/presentation/widgets/titipan_card.dart';

class TitipanPage extends StatelessWidget {
  const TitipanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<TitipanBloc, TitipanState>(
      listenWhen: (previous, current) => current.failure != null,
      listener: (context, state) {
        if (state.failure == null) return;
        final message = switch (state.failure!) {
          TitipanFailure.delete => l10n.deleteFailed,
          TitipanFailure.read => l10n.errorSaveData,
          TitipanFailure.link => l10n.shareFailed,
          TitipanFailure.load => l10n.errorLoadData,
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        context.read<TitipanBloc>().clearFailure();
      },
      builder: (context, state) {
        final items = state.visible;
        return RefreshIndicator(
          onRefresh: () async => context.read<TitipanBloc>().refresh(),
          child: PageScroll(
            children: [
              PageHeader(
                eyebrow: l10n.titipan,
                title: state.tab == TitipanTab.inbox ? l10n.inbox : l10n.sent,
                subtitle: l10n.titipanSubtitle,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Teman & Grup',
                      onPressed: () => context.push('/friends'),
                      icon: const Icon(Icons.people_outline_rounded),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: () => context.push('/titipan/new'),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: Text(l10n.newTitipan),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<TitipanTab>(
                      segments: [
                        ButtonSegment(
                          value: TitipanTab.inbox,
                          icon: const Icon(Icons.inbox_outlined, size: 17),
                          label: Text(
                            state.unreadCount > 0
                                ? '${l10n.inbox} · ${state.unreadCount}'
                                : l10n.inbox,
                          ),
                        ),
                        ButtonSegment(
                          value: TitipanTab.sent,
                          icon: const Icon(Icons.send_outlined, size: 17),
                          label: Text(l10n.sent),
                        ),
                      ],
                      selected: {state.tab},
                      onSelectionChanged: (value) =>
                          context.read<TitipanBloc>().setTab(value.first),
                      showSelectedIcon: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 13,
                    color: context.singgah.inkMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: BlocBuilder<SyncBloc, SyncStatus>(
                      builder: (context, status) {
                        final realtime =
                            status.phase != SyncPhase.offline &&
                            status.phase != SyncPhase.demo;
                        return Text(
                          realtime
                              ? l10n.titipanRealtime
                              : l10n.titipanNoRealtime,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 10.5,
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.refresh,
                    onPressed: () => context.read<TitipanBloc>().refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (state.loading)
                const LoadingState()
              else if (state.failure == TitipanFailure.load)
                ErrorState(
                  onRetry: () =>
                      context.read<TitipanBloc>().add(const TitipanStarted()),
                )
              else if (items.isEmpty)
                EmptyState(
                  icon: state.tab == TitipanTab.inbox
                      ? Icons.inbox_outlined
                      : Icons.outbox_outlined,
                  title: state.tab == TitipanTab.inbox
                      ? l10n.noInbox
                      : l10n.noSent,
                  body: state.tab == TitipanTab.inbox
                      ? l10n.noInboxBody
                      : l10n.noSentBody,
                  action: FilledButton.icon(
                    onPressed: () => context.push('/titipan/new'),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(l10n.leaveNote),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 2 : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final titipan in items)
                          SizedBox(
                            width: width,
                            child: TitipanCard(
                              titipan: titipan,
                              inbox: state.tab == TitipanTab.inbox,
                              unread:
                                  state.tab == TitipanTab.inbox &&
                                  state.isUnread(titipan),
                              accepted: state.isAccepted(titipan),
                              onTap: () =>
                                  context.push('/titipan/${titipan.id}'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
