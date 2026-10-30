import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/entities/geo_point.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/features/places/presentation/bloc/place_picker_bloc.dart';
import 'package:singgah/features/places/presentation/widgets/singgah_map.dart';

class PlacePickResult {
  const PlacePickResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;

  GeoPoint get point => GeoPoint(latitude, longitude);
}

class PlacePickerPage extends StatefulWidget {
  const PlacePickerPage({super.key, this.title});

  final String? title;

  @override
  State<PlacePickerPage> createState() => _PlacePickerPageState();
}

class _PlacePickerPageState extends State<PlacePickerPage> {
  static const GeoPoint _fallback = GeoPoint(-6.2088, 106.8456);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<PlacePickerBloc>(
      create: (_) => getIt<PlacePickerBloc>(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.title ?? l10n.pickOnMap),
            leading: IconButton(
              tooltip: l10n.back,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: BlocBuilder<PlacePickerBloc, PlacePickerState>(
            builder: (context, state) {
              final center = state.center ?? _fallback;
              return SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        onChanged: context.read<PlacePickerBloc>().setQuery,
                        onSubmitted: (_) =>
                            context.read<PlacePickerBloc>().search(),
                        decoration: InputDecoration(
                          hintText: l10n.searchPlaceHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: state.searching
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.clear,
                                  onPressed: () {
                                    _search.clear();
                                    context.read<PlacePickerBloc>().setQuery(
                                      '',
                                    );
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    if (state.results.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 188),
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            clip: true,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: state.results.length,
                              separatorBuilder: (_, _) => const Divider(),
                              itemBuilder: (context, index) {
                                final suggestion = state.results[index];
                                return ListTile(
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(
                                    suggestion.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    suggestion.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _finish(suggestion),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (state.error)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          state.rateLimited
                              ? l10n.naturalRateLimited
                              : l10n.searchError,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.singgah.danger,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) => SinggahMap(
                            center: center,
                            height: constraints.maxHeight,
                            onTap: context.read<PlacePickerBloc>().selectPoint,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: context.singgah.surface,
                        border: Border(
                          top: BorderSide(color: context.singgah.line),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 18,
                                color: context.singgah.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.address?.trim().isNotEmpty == true
                                      ? state.address!
                                      : l10n.mapHint,
                                  style: context.texts.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: state.locating
                                    ? null
                                    : () => context
                                          .read<PlacePickerBloc>()
                                          .useCurrentLocation(),
                                icon: const Icon(
                                  Icons.my_location_rounded,
                                  size: 16,
                                ),
                                label: Text(l10n.nearYou),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () =>
                                _finishPoint(center, state.address ?? ''),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(l10n.useThisPoint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _finish(PlaceSuggestion suggestion) {
    context.pop(
      PlacePickResult(
        name: suggestion.name,
        address: suggestion.address,
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
      ),
    );
  }

  void _finishPoint(GeoPoint point, String address) {
    context.pop(
      PlacePickResult(
        name: address.trim().isEmpty
            ? context.l10n.placeNameHint
            : address.split(',').first.trim(),
        address: address,
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
  }
}
