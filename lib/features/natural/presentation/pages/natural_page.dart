import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/natural_draft.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/features/natural/presentation/bloc/natural_bloc.dart';
import 'package:singgah/features/places/presentation/pages/place_picker_page.dart';

class NaturalPage extends StatefulWidget {
  const NaturalPage({super.key});

  @override
  State<NaturalPage> createState() => _NaturalPageState();
}

class _NaturalPageState extends State<NaturalPage> {
  final _text = TextEditingController();
  final _title = TextEditingController();
  String? _parsedRaw;

  @override
  void dispose() {
    _text.dispose();
    _title.dispose();
    super.dispose();
  }

  void _reset() {
    _parsedRaw = null;
    _text.clear();
    _title.clear();
    context.read<NaturalBloc>().reset();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<NaturalBloc, NaturalState>(
      listenWhen: (previous, current) =>
          previous.saved != current.saved ||
          previous.failure != current.failure ||
          previous.draft != current.draft,
      listener: (context, state) {
        final draft = state.draft;
        if (draft != null && draft.rawText != _parsedRaw) {
          _parsedRaw = draft.rawText;
          _title.text = draft.title;
        }
        if (state.saved) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.naturalSaved)));
          context.go('/home');
          return;
        }
        final failure = state.failure;
        if (failure == null) return;
        final message = switch (failure) {
          NaturalFailure.empty => l10n.naturalEmpty,
          NaturalFailure.tooLong => l10n.naturalTooLong,
          NaturalFailure.rateLimited => l10n.naturalRateLimited,
          NaturalFailure.noPlace => l10n.naturalNoPlace,
          NaturalFailure.unavailable => l10n.aiUnavailable,
          NaturalFailure.save => l10n.errorSaveData,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: failure == NaturalFailure.unavailable
                ? SnackBarAction(
                    label: l10n.tryManual,
                    onPressed: () => context.push('/missions/new'),
                  )
                : null,
          ),
        );
        context.read<NaturalBloc>().clearFailure();
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.back,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: PageScroll(
            maxWidth: 760,
            children: [
              PageHeader(
                eyebrow: l10n.quickNatural,
                title: l10n.naturalTitle,
                subtitle: l10n.naturalSubtitle,
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _text,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: context.read<NaturalBloc>().setText,
                      decoration: InputDecoration(
                        hintText: l10n.naturalHint,
                        labelText: l10n.naturalTitle,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FilledButton.icon(
                      onPressed: state.parsing
                          ? null
                          : () => context.read<NaturalBloc>().parse(),
                      icon: state.parsing
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        state.parsing ? l10n.parsingNatural : l10n.parseNatural,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 13,
                          color: context.singgah.inkMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.aiServerNote,
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.draft != null) ...[
                const SizedBox(height: 20),
                _ReviewCard(state: state, title: _title, onReset: _reset),
              ],
              if (state.draft == null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/missions/new'),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: Text(l10n.tryManual),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.state,
    required this.title,
    required this.onReset,
  });

  final NaturalState state;
  final TextEditingController title;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = state.draft!;
    return AppCard(
      accent: context.singgah.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.naturalReview, style: context.texts.titleLarge),
                    const SizedBox(height: 3),
                    Text(
                      l10n.naturalAiBadge,
                      style: context.texts.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              ToneChip(
                label: l10n.naturalConfidence(draft.confidencePercent),
                color: context.singgah.success,
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.naturalReviewBody, style: context.texts.bodySmall),
          const SizedBox(height: 14),
          TextField(
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: context.read<NaturalBloc>().setTitle,
            decoration: InputDecoration(
              labelText: l10n.missionTitle,
              prefixIcon: const Icon(Icons.bolt_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _PlaceSection(state: state),
          const SizedBox(height: 16),
          Text(l10n.trigger, style: context.texts.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<MissionTrigger>(
            segments: [
              ButtonSegment(
                value: MissionTrigger.arrive,
                label: Text(l10n.triggerArrive),
              ),
              ButtonSegment(
                value: MissionTrigger.leave,
                label: Text(l10n.triggerLeave),
              ),
            ],
            selected: {draft.trigger},
            onSelectionChanged: (value) =>
                context.read<NaturalBloc>().setTrigger(value.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          _ScheduleFields(draft: draft),
          if (draft.note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              draft.note,
              style: context.texts.bodySmall?.copyWith(
                color: context.singgah.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: state.saving
                ? null
                : () => context.read<NaturalBloc>().save(),
            icon: state.saving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(l10n.naturalApprove),
          ),
          TextButton(
            onPressed: state.saving ? null : onReset,
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _PlaceSection extends StatelessWidget {
  const _PlaceSection({required this.state});

  final NaturalState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    final selected = state.selectedPlace;
    final suggestion = state.suggestion;
    final draft = state.draft!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.naturalPlaceTitle,
                style: context.texts.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => _searchPlace(context),
              icon: const Icon(Icons.search_rounded, size: 16),
              label: Text(l10n.naturalPlaceSearch),
            ),
          ],
        ),
        if (state.places.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: selected?.id,
            decoration: InputDecoration(
              hintText: l10n.choosePlace,
              prefixIcon: const Icon(Icons.place_outlined),
            ),
            items: [
              for (final place in state.places)
                DropdownMenuItem(
                  value: place.id,
                  child: Text(place.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              final place = state.places.firstWhere((item) => item.id == value);
              context.read<NaturalBloc>().selectPlace(place);
            },
          ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          _PlaceHint(
            icon: Icons.check_circle_outline_rounded,
            color: colors.success,
            title: l10n.naturalMatchedPlace,
            body: selected.name,
          ),
        ] else if (suggestion != null) ...[
          const SizedBox(height: 8),
          _PlaceHint(
            icon: Icons.add_location_alt_outlined,
            color: colors.accent,
            title: l10n.naturalNewPlace,
            body: '${suggestion.name} · ${suggestion.address}',
          ),
        ] else ...[
          const SizedBox(height: 8),
          _PlaceHint(
            icon: Icons.info_outline_rounded,
            color: colors.warning,
            title: l10n.naturalNoPlace,
            body: draft.placeName.isEmpty
                ? l10n.placeNameHint
                : draft.placeName,
          ),
        ],
      ],
    );
  }

  Future<void> _searchPlace(BuildContext context) async {
    final result = await context.push<PlacePickResult>('/places/picker');
    if (result == null || !context.mounted) return;
    context.read<NaturalBloc>().selectSuggestion(
      PlaceSuggestion(
        name: result.name,
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      ),
    );
  }
}

class _PlaceHint extends StatelessWidget {
  const _PlaceHint({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.texts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  body,
                  style: context.texts.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleFields extends StatelessWidget {
  const _ScheduleFields({required this.draft});

  final NaturalDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<NaturalBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.repeat, style: context.texts.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(l10n.weekday(day)),
                selected: draft.repeatDays.contains(day),
                onSelected: (_) {
                  final next = Set<int>.from(draft.repeatDays);
                  if (!next.add(day)) next.remove(day);
                  bloc.setRepeatDays(next);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimeChip(
                label: l10n.pickTimeStart,
                minutes: draft.windowStartMinutes,
                onPick: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: draft.windowStartMinutes ~/ 60,
                      minute: draft.windowStartMinutes % 60,
                    ),
                  );
                  if (picked == null) return;
                  bloc.setWindow(
                    clockToMinutes(picked.hour, picked.minute),
                    draft.windowEndMinutes,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TimeChip(
                label: l10n.pickTimeEnd,
                minutes: draft.windowEndMinutes,
                onPick: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: draft.windowEndMinutes ~/ 60,
                      minute: draft.windowEndMinutes % 60,
                    ),
                  );
                  if (picked == null) return;
                  bloc.setWindow(
                    draft.windowStartMinutes,
                    clockToMinutes(picked.hour, picked.minute),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.minutes,
    required this.onPick,
  });

  final String label;
  final int minutes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.singgah.surfaceMuted,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: context.singgah.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.texts.bodySmall),
            Text(
              minutesToClock(minutes),
              style: AppTypography.numeric(
                fontSize: 14,
                color: context.singgah.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
