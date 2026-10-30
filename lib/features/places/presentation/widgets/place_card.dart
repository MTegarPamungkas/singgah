import 'package:flutter/material.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/titik.dart';

IconData placeIcon(String key) => switch (key) {
  'home' => Icons.home_rounded,
  'work' => Icons.work_rounded,
  'store' => Icons.storefront_rounded,
  'school' => Icons.school_rounded,
  'favorite' => Icons.favorite_rounded,
  'gym' => Icons.fitness_center_rounded,
  _ => Icons.place_rounded,
};

const List<String> placeIcons = [
  'pin',
  'home',
  'work',
  'store',
  'school',
  'favorite',
  'gym',
];

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.missionCount = 0,
    this.onTap,
    this.compact = false,
  });

  final Titik place;
  final int missionCount;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 14 : 17),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(
              placeIcon(place.iconKey),
              size: 21,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: context.texts.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  place.address.trim().isEmpty
                      ? l10n.radiusLabel(place.radiusMeters)
                      : place.address,
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (missionCount > 0) ...[
                  const SizedBox(height: 6),
                  ToneChip(
                    label: l10n.placeHasMissions(missionCount),
                    color: colors.navy,
                    icon: Icons.bolt_rounded,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: colors.inkMuted),
        ],
      ),
    );
  }
}
