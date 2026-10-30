import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/features/missions/presentation/bloc/mission_form_bloc.dart';

class MissionFormPage extends StatefulWidget {
  const MissionFormPage({super.key});

  @override
  State<MissionFormPage> createState() => _MissionFormPageState();
}

class _MissionFormPageState extends State<MissionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<MissionFormBloc, MissionFormState>(
      listenWhen: (previous, current) =>
          previous.saved != current.saved ||
          previous.deleted != current.deleted ||
          previous.failure != current.failure,
      listener: (context, state) {
        if (state.saved || state.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.deleted ? l10n.missionDeleted : l10n.missionSaved,
              ),
            ),
          );
          context.pop();
          return;
        }
        final failure = state.failure;
        if (failure == null) return;
        final message = switch (failure) {
          MissionFormFailure.titleRequired => l10n.missionTitleRequired,
          MissionFormFailure.placeRequired => l10n.placeRequired,
          MissionFormFailure.windowInvalid => l10n.windowInvalid,
          MissionFormFailure.delete => l10n.deleteFailed,
          _ => l10n.errorSaveData,
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        context.read<MissionFormBloc>().clearFailure();
      },
      builder: (context, state) {
        if (!state.loading && !_seeded) {
          _seeded = true;
          _title.text = state.title;
          _note.text = state.note;
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.back,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(state.editing ? l10n.editMission : l10n.newMission),
            actions: [
              if (state.editing)
                IconButton(
                  tooltip: l10n.delete,
                  onPressed: state.deleting
                      ? null
                      : () => _confirmDelete(context),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: context.singgah.danger,
                  ),
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: state.loading
              ? const LoadingState()
              : PageScroll(
                  maxWidth: 760,
                  top: 10,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _title,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: context.read<MissionFormBloc>().setTitle,
                            decoration: InputDecoration(
                              labelText: l10n.missionTitle,
                              hintText: l10n.missionTitleHint,
                              prefixIcon: const Icon(Icons.bolt_outlined),
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? l10n.missionTitleRequired
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _note,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: context.read<MissionFormBloc>().setNote,
                            decoration: InputDecoration(
                              labelText: l10n.missionNote,
                              hintText: l10n.missionNoteHint,
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(
                            icon: Icons.place_outlined,
                            label: l10n.missionPlaceLabel,
                          ),
                          const SizedBox(height: 8),
                          if (state.places.isEmpty)
                            _NoPlacesCard(
                              onAdd: () => context.push('/places/new'),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: state.placeId.isEmpty
                                  ? null
                                  : state.placeId,
                              decoration: InputDecoration(
                                hintText: l10n.choosePlace,
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                              ),
                              items: [
                                for (final place in state.places)
                                  DropdownMenuItem(
                                    value: place.id,
                                    child: Text(
                                      place.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                final place = state.places.firstWhere(
                                  (item) => item.id == value,
                                );
                                context.read<MissionFormBloc>().setPlace(
                                  place.id,
                                  place.name,
                                );
                              },
                            ),
                          const SizedBox(height: 22),
                          _SectionLabel(
                            icon: Icons.my_location_rounded,
                            label: l10n.trigger,
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<MissionTrigger>(
                            segments: [
                              ButtonSegment(
                                value: MissionTrigger.arrive,
                                icon: const Icon(Icons.login_rounded, size: 17),
                                label: Text(l10n.triggerArrive),
                              ),
                              ButtonSegment(
                                value: MissionTrigger.leave,
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 17,
                                ),
                                label: Text(l10n.triggerLeave),
                              ),
                            ],
                            selected: {state.trigger},
                            onSelectionChanged: (value) => context
                                .read<MissionFormBloc>()
                                .setTrigger(value.first),
                            showSelectedIcon: false,
                          ),
                          const SizedBox(height: 22),
                          _SectionLabel(
                            icon: Icons.event_repeat_rounded,
                            label: l10n.repeat,
                          ),
                          const SizedBox(height: 8),
                          _RepeatPicker(state: state),
                          const SizedBox(height: 22),
                          _SectionLabel(
                            icon: Icons.schedule_rounded,
                            label: l10n.window,
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.windowHint, style: context.texts.bodySmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeField(
                                  label: l10n.pickTimeStart,
                                  minutes: state.windowStartMinutes,
                                  onPick: () => _pickTime(
                                    context,
                                    start: true,
                                    current: state.windowStartMinutes,
                                    end: state.windowEndMinutes,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TimeField(
                                  label: l10n.pickTimeEnd,
                                  minutes: state.windowEndMinutes,
                                  onPick: () => _pickTime(
                                    context,
                                    start: false,
                                    current: state.windowStartMinutes,
                                    end: state.windowEndMinutes,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: state.isActive,
                            onChanged: context
                                .read<MissionFormBloc>()
                                .setActive,
                            title: Text(l10n.active),
                            subtitle: Text(l10n.missionActiveHint),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: state.saving
                                ? null
                                : () => _save(context, state),
                            icon: state.saving
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(l10n.saveMission),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _save(BuildContext context, MissionFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<MissionFormBloc>().save();
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool start,
    required int current,
    required int end,
  }) async {
    final initial = TimeOfDay(hour: current ~/ 60, minute: current % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !context.mounted) return;
    final minutes = clockToMinutes(picked.hour, picked.minute);
    final bloc = context.read<MissionFormBloc>();
    if (start) {
      bloc.setWindow(minutes, end);
    } else {
      bloc.setWindow(current, minutes);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteMission),
        content: Text(context.l10n.deleteMissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<MissionFormBloc>().delete();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: context.singgah.accent),
        const SizedBox(width: 7),
        Text(label, style: context.texts.titleMedium),
      ],
    );
  }
}

class _NoPlacesCard extends StatelessWidget {
  const _NoPlacesCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.place_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.noPlacesBody,
              style: context.texts.bodySmall,
            ),
          ),
          TextButton(onPressed: onAdd, child: Text(context.l10n.addPlace)),
        ],
      ),
    );
  }
}

class _RepeatPicker extends StatelessWidget {
  const _RepeatPicker({required this.state});

  final MissionFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final everyDay = state.everyDay;
    final weekdays =
        state.repeatDays.length == 5 &&
        state.repeatDays.containsAll(const {1, 2, 3, 4, 5});
    final weekends =
        state.repeatDays.length == 2 &&
        state.repeatDays.containsAll(const {6, 7});
    final bloc = context.read<MissionFormBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.everyDay),
              selected: everyDay,
              onSelected: (_) => bloc.selectEveryDay(),
            ),
            ChoiceChip(
              label: Text(l10n.weekdays),
              selected: weekdays,
              onSelected: (_) => bloc.selectWeekdays(),
            ),
            ChoiceChip(
              label: Text(l10n.weekends),
              selected: weekends,
              onSelected: (_) => bloc.selectWeekends(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(l10n.weekday(day)),
                selected: state.repeatDays.contains(day),
                onSelected: (_) => bloc.toggleDay(day),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: context.singgah.surfaceElevated,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: context.singgah.line),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 18,
              color: context.singgah.accent,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.texts.bodySmall),
                  Text(
                    minutesToClock(minutes),
                    style: AppTypography.numeric(
                      fontSize: 15,
                      color: context.singgah.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
