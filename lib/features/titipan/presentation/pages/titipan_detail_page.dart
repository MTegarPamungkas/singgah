import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';
import 'package:singgah/features/titipan/presentation/widgets/invite_actions.dart';

class TitipanDetailPage extends StatefulWidget {
  const TitipanDetailPage({super.key, required this.titipanId});

  final String titipanId;

  @override
  State<TitipanDetailPage> createState() => _TitipanDetailPageState();
}

class _TitipanDetailPageState extends State<TitipanDetailPage> {
  late Future<_DetailData?> _future;
  String? _inviteLink;
  bool _loadingLink = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData?> _load() async {
    final titipan = await getIt<GetTitipan>()(widget.titipanId);
    if (titipan == null) return null;
    final feed = await getIt<GetTitipanFeed>()();
    final user = getIt<AuthRepository>().currentUser;
    final recipients = feed.recipients
        .where((recipient) => recipient.titipanId == titipan.id)
        .toList(growable: false);
    final mine = recipients.where((recipient) => recipient.userId == user?.id);
    final owner = titipan.senderId == user?.id;
    final unread =
        !owner && mine.isNotEmpty && mine.every((r) => r.readAt == null);
    if (unread) {
      try {
        await getIt<MarkTitipanRead>()(titipan.id);
      } catch (_) {}
    }
    if (owner && titipan.inviteToken.isNotEmpty) {
      _inviteLink = await getIt<EnsureTitipanInviteLink>()(titipan);
    }
    return _DetailData(
      titipan: titipan,
      owner: owner,
      senderName: titipan.senderName,
      placeName: titipan.placeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<_DetailData?>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.back,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(l10n.titipan),
            actions: [
              if (data != null && data.owner)
                IconButton(
                  tooltip: l10n.delete,
                  onPressed: _deleting ? null : () => _delete(context),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: context.singgah.danger,
                  ),
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const LoadingState()
              : data == null
              ? PageScroll(
                  children: [
                    EmptyState(
                      icon: Icons.mark_email_read_outlined,
                      title: l10n.inviteInvalid,
                      action: FilledButton(
                        onPressed: () => context.go('/titipan'),
                        child: Text(l10n.back),
                      ),
                    ),
                  ],
                )
              : PageScroll(
                  maxWidth: 760,
                  top: 10,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(22),
                      accent: data.owner
                          ? context.singgah.accent
                          : context.singgah.success,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ToneChip(
                                label: data.owner
                                    ? l10n.sent
                                    : l10n.titipanFrom(data.senderName),
                                color: data.owner
                                    ? context.singgah.accent
                                    : context.singgah.success,
                                icon: data.owner
                                    ? Icons.send_outlined
                                    : Icons.person_outline_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            data.titipan.title,
                            style: context.texts.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data.titipan.body,
                            style: context.texts.bodyLarge?.copyWith(
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 10),
                          InfoRow(
                            icon: Icons.place_outlined,
                            label: l10n.titipanPlace,
                            value: data.placeName,
                          ),
                          InfoRow(
                            icon: Icons.my_location_rounded,
                            label: l10n.titipanWhen,
                            value: data.titipan.trigger == MissionTrigger.arrive
                                ? l10n.triggerArriveLong
                                : l10n.triggerLeaveLong,
                          ),
                          InfoRow(
                            icon: Icons.schedule_rounded,
                            label: l10n.createdAtLabel,
                            value: data.titipan.createdAt == null
                                ? '—'
                                : formatDateTime(
                                    data.titipan.createdAt!,
                                    l10n.locale.languageCode,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (data.owner) ...[
                      const SizedBox(height: 18),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  size: 18,
                                  color: context.singgah.accent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.inviteLink,
                                    style: context.texts.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.inviteLinkBody,
                              style: context.texts.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            if (_inviteLink != null)
                              InviteActions(
                                link: _inviteLink!,
                                title: data.titipan.title,
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _loadingLink ? null : _loadLink,
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: Text(l10n.inviteLink),
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Text(l10n.inviteLinkBody, style: context.texts.bodySmall),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Future<void> _loadLink() async {
    setState(() => _loadingLink = true);
    try {
      final titipan = await getIt<GetTitipan>()(widget.titipanId);
      if (titipan == null) return;
      final link = await getIt<EnsureTitipanInviteLink>()(titipan);
      if (!mounted) return;
      setState(() => _inviteLink = link);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _loadingLink = false);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.titipanDelete),
        content: Text(l10n.titipanDeleteBody),
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
    setState(() => _deleting = true);
    try {
      await getIt<DeleteTitipan>()(widget.titipanId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.titipanDeleted)));
      context.pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
      setState(() => _deleting = false);
    }
  }
}

class _DetailData {
  const _DetailData({
    required this.titipan,
    required this.owner,
    required this.senderName,
    required this.placeName,
  });

  final Titipan titipan;
  final bool owner;
  final String senderName;
  final String placeName;
}
