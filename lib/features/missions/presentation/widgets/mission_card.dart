import 'package:flutter/material.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    this.place,
    this.onTap,
    this.onToggle,
    this.compact = false,
  });

  final SinggahMission mission;
  final Titik? place;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    final now = DateTime.now();
    final scheduled = mission.isScheduled(now);
    final tone = mission.isActive
        ? (scheduled ? colors.success : colors.navy)
        : colors.inkMuted;
    final status = !mission.isActive
        ? l10n.paused
        : scheduled
        ? l10n.nowActive
        : (!mission.runsOn(now.weekday)
              ? l10n.inactiveNow
              : l10n.outsideWindow);

    return AppCard(
      onTap: onTap,
      accent: mission.isActive ? tone : null,
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
                  mission.trigger == MissionTrigger.arrive
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
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
                      mission.title,
                      style: context.texts.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      place?.name ?? l10n.placeRequired,
                      style: context.texts.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onToggle != null)
                Switch.adaptive(value: mission.isActive, onChanged: onToggle)
              else
                ToneChip(label: status, color: tone),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ToneChip(
                label: mission.trigger == MissionTrigger.arrive
                    ? l10n.triggerArriveLong
                    : l10n.triggerLeaveLong,
                color: colors.accent,
                icon: Icons.my_location_rounded,
              ),
              ToneChip(
                label: l10n.daysLabel(mission.repeatDays),
                color: colors.navy,
                icon: Icons.event_repeat_rounded,
              ),
              if (!mission.hasFreeWindow)
                ToneChip(
                  label:
                      '${minutesToClock(mission.windowStartMinutes)}–${minutesToClock(mission.windowEndMinutes)}',
                  color: colors.info,
                  icon: Icons.schedule_rounded,
                ),
            ],
          ),
          if (mission.note.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              mission.note,
              style: context.texts.bodySmall?.copyWith(
                color: colors.inkMuted,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
