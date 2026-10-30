import 'package:flutter/material.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titipan.dart';

class TitipanCard extends StatelessWidget {
  const TitipanCard({
    super.key,
    required this.titipan,
    required this.inbox,
    this.unread = false,
    this.accepted = false,
    this.onTap,
    this.compact = false,
  });

  final Titipan titipan;
  final bool inbox;
  final bool unread;
  final bool accepted;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    final tone = unread ? colors.accent : colors.navy;
    return AppCard(
      onTap: onTap,
      accent: unread ? colors.accent : null,
      padding: EdgeInsets.all(compact ? 14 : 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: AppRadius.allMd,
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  size: 19,
                  color: tone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titipan.title,
                      style: context.texts.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      inbox
                          ? l10n.titipanFrom(titipan.senderName)
                          : l10n.titipanTo(
                              titipan.recipientHint.trim().isEmpty
                                  ? l10n.inviteLink
                                  : titipan.recipientHint,
                            ),
                      style: context.texts.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (unread)
                ToneChip(label: l10n.titipanNewBadge, color: colors.accent)
              else if (!inbox)
                ToneChip(
                  label: accepted ? l10n.titipanAccepted : l10n.titipanPending,
                  color: accepted ? colors.success : colors.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 14, color: colors.inkMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  titipan.placeName,
                  style: context.texts.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ToneChip(
                label: titipan.trigger == MissionTrigger.arrive
                    ? l10n.triggerArrive
                    : l10n.triggerLeave,
                color: colors.accent,
                icon: Icons.my_location_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
