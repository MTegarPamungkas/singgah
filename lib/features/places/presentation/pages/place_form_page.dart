import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/geo_point.dart';
import 'package:singgah/features/places/presentation/bloc/place_form_bloc.dart';
import 'package:singgah/features/places/presentation/pages/place_picker_page.dart';
import 'package:singgah/features/places/presentation/widgets/place_card.dart';
import 'package:singgah/features/places/presentation/widgets/singgah_map.dart';

class PlaceFormPage extends StatefulWidget {
  const PlaceFormPage({super.key});

  @override
  State<PlaceFormPage> createState() => _PlaceFormPageState();
}

class _PlaceFormPageState extends State<PlaceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<PlaceFormBloc, PlaceFormState>(
      listenWhen: (previous, current) =>
          previous.saved != current.saved ||
          previous.deleted != current.deleted ||
          previous.failure != current.failure,
      listener: (context, state) {
        if (state.saved || state.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.deleted ? l10n.placeDeleted : l10n.placeSaved,
              ),
            ),
          );
          context.pop();
          return;
        }
        final failure = state.failure;
        if (failure != null) {
          final message = switch (failure) {
            PlaceFormFailure.location => l10n.locationUnavailable,
            PlaceFormFailure.delete => l10n.deleteFailed,
            _ => l10n.errorSaveData,
          };
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
          context.read<PlaceFormBloc>().clearFailure();
        }
      },
      builder: (context, state) {
        if (!state.loading && !_seeded) {
          _seeded = true;
          _name.text = state.name;
          _address.text = state.address;
        }
        final coords = state.hasCoordinates
            ? GeoPoint(state.latitude!, state.longitude!)
            : null;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.back,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(state.editing ? l10n.editPlace : l10n.newPlace),
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
                    if (state.editing && state.deleting)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            onChanged: context.read<PlaceFormBloc>().setName,
                            decoration: InputDecoration(
                              labelText: l10n.placeName,
                              hintText: l10n.placeNameHint,
                              prefixIcon: const Icon(Icons.place_outlined),
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? l10n.placeNameRequired
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address,
                            minLines: 1,
                            maxLines: 2,
                            onChanged: context.read<PlaceFormBloc>().setAddress,
                            decoration: InputDecoration(
                              labelText: l10n.placeAddress,
                              hintText: l10n.placeAddressHint,
                              prefixIcon: const Icon(Icons.signpost_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _MapSection(
                            point: coords,
                            address: state.address,
                            locating: state.locating,
                            onPick: () => _pickOnMap(context),
                            onCurrent: () => context
                                .read<PlaceFormBloc>()
                                .useCurrentLocation(),
                          ),
                          const SizedBox(height: 20),
                          Text(l10n.radius, style: context.texts.titleMedium),
                          const SizedBox(height: 4),
                          Text(l10n.radiusHint, style: context.texts.bodySmall),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: state.radiusMeters.toDouble(),
                                  min: 100,
                                  max: 2000,
                                  divisions: 19,
                                  label: l10n.radiusValue(state.radiusMeters),
                                  onChanged: (value) => context
                                      .read<PlaceFormBloc>()
                                      .setRadius(value.round()),
                                ),
                              ),
                              SizedBox(
                                width: 76,
                                child: Text(
                                  l10n.radiusValue(state.radiusMeters),
                                  textAlign: TextAlign.end,
                                  style: AppTypography.numeric(
                                    fontSize: 13,
                                    color: context.singgah.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.iconLabel,
                            style: context.texts.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final icon in placeIcons)
                                _IconChoice(
                                  icon: icon,
                                  selected: state.iconKey == icon,
                                  onTap: () => context
                                      .read<PlaceFormBloc>()
                                      .setIcon(icon),
                                ),
                            ],
                          ),
                          const SizedBox(height: 26),
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
                            label: Text(l10n.savePlace),
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

  void _save(BuildContext context, PlaceFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!state.hasCoordinates) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.locationRequired)));
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<PlaceFormBloc>().save();
  }

  Future<void> _pickOnMap(BuildContext context) async {
    final result = await context.push<PlacePickResult>('/places/picker');
    if (result == null || !context.mounted) return;
    context.read<PlaceFormBloc>().setCoordinates(
      result.latitude,
      result.longitude,
      address: result.address,
      reverse: false,
    );
    if (_address.text.trim().isEmpty) {
      _address.text = result.address;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deletePlace),
        content: Text(context.l10n.deletePlaceBody),
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
      context.read<PlaceFormBloc>().delete();
    }
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.point,
    required this.address,
    required this.locating,
    required this.onPick,
    required this.onCurrent,
  });

  final GeoPoint? point;
  final String address;
  final bool locating;
  final VoidCallback onPick;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.singgah;
    if (point == null) {
      return AppCard(
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 34, color: colors.inkMuted),
            const SizedBox(height: 10),
            Text(l10n.locationRequired, style: context.texts.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.mapHint, style: context.texts.bodySmall),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onPick,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(l10n.pickOnMap),
                ),
                OutlinedButton.icon(
                  onPressed: locating ? null : onCurrent,
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(l10n.useMyLocation),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SinggahMap(center: point!, height: 230, interactive: false),
        const SizedBox(height: 10),
        Row(
          children: [
            if (address.trim().isNotEmpty)
              Expanded(
                child: Text(
                  address,
                  style: context.texts.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 17),
              label: Text(l10n.changePlace),
            ),
            IconButton(
              tooltip: l10n.useMyLocation,
              onPressed: locating ? null : onCurrent,
              icon: const Icon(Icons.my_location_rounded, size: 19),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.singgah;
    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surfaceMuted,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: selected ? colors.accent : colors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Icon(
          placeIcon(icon),
          color: selected ? colors.accent : colors.inkMuted,
          size: 21,
        ),
      ),
    );
  }
}
