import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/responsive/app_breakpoints.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/features/places/presentation/bloc/places_bloc.dart';
import 'package:singgah/features/places/presentation/widgets/place_card.dart';

class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<PlacesBloc, PlacesState>(
      listenWhen: (previous, current) => current.failure != null,
      listener: (context, state) {
        if (state.failure == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.failure == PlacesFailure.delete
                  ? l10n.deleteFailed
                  : l10n.errorLoadData,
            ),
          ),
        );
        context.read<PlacesBloc>().clearFailure();
      },
      child: BlocBuilder<PlacesBloc, PlacesState>(
        builder: (context, state) {
          return PageScroll(
            children: [
              PageHeader(
                eyebrow: l10n.places,
                title: l10n.savedPlaces,
                subtitle: l10n.placesSubtitle,
                trailing: FilledButton.icon(
                  onPressed: () => context.push('/places/new'),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: Text(l10n.newPlace),
                ),
              ),
              const SizedBox(height: 22),
              if (state.loading)
                const LoadingState()
              else if (state.failure == PlacesFailure.load)
                ErrorState(
                  onRetry: () =>
                      context.read<PlacesBloc>().add(const PlacesStarted()),
                )
              else if (state.places.isEmpty)
                EmptyState(
                  icon: Icons.place_outlined,
                  title: l10n.noPlaces,
                  body: l10n.noPlacesBody,
                  action: FilledButton.icon(
                    onPressed: () => context.push('/places/new'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addPlace),
                  ),
                )
              else
                _PlacesGrid(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _PlacesGrid extends StatelessWidget {
  const _PlacesGrid({required this.state});

  final PlacesState state;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
    if (!wide) {
      return Column(
        children: [
          for (final place in state.places) ...[
            _PlaceRow(
              place: place,
              missionCount: state.missionCounts[place.id] ?? 0,
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final place in state.places)
              SizedBox(
                width: width,
                child: _PlaceRow(
                  place: place,
                  missionCount: state.missionCounts[place.id] ?? 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.missionCount});

  final Titik place;
  final int missionCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PlaceCard(
          place: place,
          missionCount: missionCount,
          onTap: () => context.push('/places/${place.id}/edit'),
        ),
        Positioned(right: 8, top: 8, child: _PlaceMenu(place: place)),
      ],
    );
  }
}

class _PlaceMenu extends StatelessWidget {
  const _PlaceMenu({required this.place});

  final Titik place;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.edit,
      icon: Icon(
        Icons.more_horiz_rounded,
        color: context.singgah.inkMuted,
        size: 20,
      ),
      onSelected: (value) async {
        if (value == 'edit') {
          context.push('/places/${place.id}/edit');
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.deletePlace),
            content: Text(l10n.deletePlaceBody),
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
        final success = await context.read<PlacesBloc>().deletePlace(place.id);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.placeDeleted)));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined, size: 18),
            title: Text(l10n.edit),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: context.singgah.danger,
            ),
            title: Text(l10n.delete),
          ),
        ),
      ],
    );
  }
}
