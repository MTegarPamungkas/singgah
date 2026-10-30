import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';

class InviteActions extends StatelessWidget {
  const InviteActions({
    super.key,
    required this.link,
    this.title = '',
    this.compact = false,
  });

  final String link;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.singgah.surfaceMuted,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: context.singgah.line),
          ),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 17, color: context.singgah.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  link,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(l10n.shareInvite),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.inviteCopied)));
                },
                icon: const Icon(Icons.copy_rounded, size: 17),
                label: Text(l10n.copyInvite),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: title.trim().isEmpty
              ? '${l10n.inviteShareText}\n$link'
              : '${l10n.inviteShareText}\n\n${title.trim()}\n$link',
          subject: l10n.inviteTitle,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }
}
