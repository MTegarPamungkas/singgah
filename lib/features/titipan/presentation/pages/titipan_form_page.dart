import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/social.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/features/titipan/presentation/bloc/titipan_form_bloc.dart';
import 'package:singgah/features/titipan/presentation/widgets/invite_actions.dart';

class TitipanFormPage extends StatefulWidget {
  const TitipanFormPage({super.key});

  @override
  State<TitipanFormPage> createState() => _TitipanFormPageState();
}

class _TitipanFormPageState extends State<TitipanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _recipient = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _recipient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<TitipanFormBloc, TitipanFormState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.savedId != current.savedId,
      listener: (context, state) {
        if (state.savedId != null && state.savedId != _lastSavedId) {
          _lastSavedId = state.savedId;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.titipanSaved)));
          return;
        }
        final failure = state.failure;
        if (failure == null) return;
        final message = switch (failure) {
          TitipanFormFailure.titleRequired => l10n.missionTitleRequired,
          TitipanFormFailure.bodyRequired => l10n.titipanMessage,
          TitipanFormFailure.placeRequired => l10n.placeRequired,
          TitipanFormFailure.link => l10n.shareFailed,
          TitipanFormFailure.directSend => l10n.shareFailed,
          TitipanFormFailure.save => l10n.errorSaveData,
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        context.read<TitipanFormBloc>().clearFailure();
      },
      builder: (context, state) {
        if (!state.loading && !_seeded) {
          _seeded = true;
          _title.text = state.title;
          _body.text = state.body;
          _recipient.text = state.recipientHint;
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.back,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(l10n.newTitipan),
          ),
          body: state.loading
              ? const LoadingState()
              : PageScroll(
                  maxWidth: 760,
                  top: 10,
                  children: [
                    if (state.savedId != null)
                      _SavedPanel(state: state)
                    else
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _title,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: context
                                  .read<TitipanFormBloc>()
                                  .setTitle,
                              decoration: InputDecoration(
                                labelText: l10n.titipanTitle,
                                hintText: l10n.titipanTitleHint,
                                prefixIcon: const Icon(
                                  Icons.mark_email_unread_outlined,
                                ),
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? l10n.missionTitleRequired
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _body,
                              minLines: 3,
                              maxLines: 6,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: context
                                  .read<TitipanFormBloc>()
                                  .setBody,
                              decoration: InputDecoration(
                                labelText: l10n.titipanMessage,
                                hintText: l10n.titipanMessageHint,
                                alignLabelWithHint: true,
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? l10n.titipanMessage
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.titipanPlace,
                              style: context.texts.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (state.places.isEmpty)
                              AppCard(
                                child: Row(
                                  children: [
                                    const Icon(Icons.place_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.noPlacesBody,
                                        style: context.texts.bodySmall,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.push('/places/new'),
                                      child: Text(l10n.addPlace),
                                    ),
                                  ],
                                ),
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
                                  context.read<TitipanFormBloc>().setPlace(
                                    place,
                                  );
                                },
                              ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.titipanTrigger,
                              style: context.texts.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<MissionTrigger>(
                              segments: [
                                ButtonSegment(
                                  value: MissionTrigger.arrive,
                                  icon: const Icon(
                                    Icons.login_rounded,
                                    size: 17,
                                  ),
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
                                  .read<TitipanFormBloc>()
                                  .setTrigger(value.first),
                              showSelectedIcon: false,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _recipient,
                              onChanged: context
                                  .read<TitipanFormBloc>()
                                  .setRecipient,
                              decoration: InputDecoration(
                                labelText:
                                    '${l10n.titipanRecipient} (${l10n.optional})',
                                hintText: l10n.titipanRecipientHint,
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
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
                              label: Text(l10n.leaveNote),
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

  String? _lastSavedId;

  void _save(BuildContext context, TitipanFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<TitipanFormBloc>().save();
  }
}

class _SavedPanel extends StatelessWidget {
  const _SavedPanel({required this.state});

  final TitipanFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          accent: context.singgah.success,
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: context.singgah.success,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.titipanSaved, style: context.texts.titleMedium),
                    const SizedBox(height: 3),
                    Text(l10n.inviteLinkBody, style: context.texts.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(l10n.inviteLink, style: context.texts.titleMedium),
        const SizedBox(height: 8),
        if (state.inviteLink != null)
          InviteActions(link: state.inviteLink!, title: state.title)
        else
          OutlinedButton.icon(
            onPressed: context.read<TitipanFormBloc>().loadLink,
            icon: const Icon(Icons.link_rounded, size: 18),
            label: Text(l10n.inviteLink),
          ),
        const SizedBox(height: 18),
        if (state.socialSent)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${state.directCount} penerima langsung dikirimi Titipan.',
              style: context.texts.bodySmall,
            ),
          ),
        OutlinedButton.icon(
          onPressed: state.socialSending
              ? null
              : () => _openDirectSend(context),
          icon: state.socialSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.group_add_outlined, size: 18),
          label: Text(
            state.socialSending ? 'Mengirim…' : 'Kirim langsung ke teman/grup',
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(onPressed: () => context.pop(), child: Text(l10n.done)),
      ],
    );
  }

  Future<void> _openDirectSend(BuildContext context) async {
    final gateway = GetIt.instance<CloudGateway>();
    final me = GetIt.instance<AuthRepository>().currentUser?.id ?? '';
    SocialSnapshot snapshot;
    try {
      snapshot = await gateway.loadSocial();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teman/grup belum bisa dimuat.')),
      );
      return;
    }
    if (!context.mounted) return;

    final friends = snapshot.friendsFor(me);
    final groups = snapshot.groupsFor(me);
    if (friends.isEmpty && groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada teman atau grup. Tambahkan dulu di menu Teman.',
          ),
        ),
      );
      return;
    }

    final result =
        await showModalBottomSheet<
          ({List<String> friends, List<String> groups})
        >(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) {
            final selectedFriends = <String>{};
            final selectedGroups = <String>{};
            return StatefulBuilder(
              builder: (context, setModalState) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Kirim ke', style: context.texts.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih teman atau grup. Mereka langsung menerima Titipan ini.',
                        style: context.texts.bodySmall,
                      ),
                      if (friends.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('Teman', style: context.texts.labelLarge),
                        ...friends.map(
                          (link) => CheckboxListTile(
                            value: selectedFriends.contains(link.otherId(me)),
                            onChanged: (value) => setModalState(() {
                              final id = link.otherId(me);
                              value == true
                                  ? selectedFriends.add(id)
                                  : selectedFriends.remove(id);
                            }),
                            title: Text(link.otherName(me)),
                            subtitle: Text(link.otherEmail(me)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      if (groups.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Grup', style: context.texts.labelLarge),
                        ...groups.map(
                          (group) => CheckboxListTile(
                            value: selectedGroups.contains(group.id),
                            onChanged: (value) => setModalState(() {
                              value == true
                                  ? selectedGroups.add(group.id)
                                  : selectedGroups.remove(group.id);
                            }),
                            title: Text(group.name),
                            subtitle: Text('${group.memberIds.length} anggota'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed:
                            selectedFriends.isEmpty && selectedGroups.isEmpty
                            ? null
                            : () => Navigator.of(sheetContext).pop((
                                friends: selectedFriends.toList(),
                                groups: selectedGroups.toList(),
                              )),
                        child: const Text('Kirim Titipan'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

    if (result == null || !context.mounted) return;
    context.read<TitipanFormBloc>().sendDirect(
      friendIds: result.friends,
      groupIds: result.groups,
    );
  }
}
