import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/domain/entities/social.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';

/// Friends and groups: request by email, accept, and build private groups that
/// can be used as direct Titipan recipients.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _email = TextEditingController();
  SocialSnapshot _snapshot = const SocialSnapshot();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  CloudGateway get _gateway => GetIt.instance<CloudGateway>();
  String get _me => GetIt.instance<AuthRepository>().currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _gateway.loadSocial();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Teman dan grup belum bisa dimuat.';
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tersimpan.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendRequest() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    await _run(
      () => _gateway.requestFriend(email),
      'Permintaan gagal dikirim.',
    );
    _email.clear();
  }

  Future<void> _createGroup() async {
    final friends = _snapshot.friendsFor(_me);
    final name = TextEditingController();
    final selected = <String>{};
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Grup baru'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nama grup',
                    hintText: 'Keluarga, Tim Kantor, …',
                  ),
                ),
                const SizedBox(height: 10),
                if (friends.isEmpty)
                  Text(
                    'Tambahkan teman dulu supaya bisa dimasukkan ke grup.',
                    style: context.texts.bodySmall,
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: friends
                            .map(
                              (link) => CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: selected.contains(link.otherId(_me)),
                                title: Text(link.otherName(_me)),
                                onChanged: (value) => setDialogState(() {
                                  final id = link.otherId(_me);
                                  value == true
                                      ? selected.add(id)
                                      : selected.remove(id);
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Buat grup'),
            ),
          ],
        ),
      ),
    );
    if (created != true) return;
    if (name.text.trim().isEmpty) return;
    await _run(
      () => _gateway.createGroup(name.text.trim(), selected.toList()),
      'Grup gagal dibuat.',
    );
    name.dispose();
  }

  Future<void> _confirmRemoveFriend(FriendLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus teman?'),
        content: Text(
          '${link.otherName(_me)} tidak akan bisa dikirimi Titipan langsung lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _gateway.removeFriend(link.id), 'Teman gagal dihapus.');
  }

  void _openChat({
    required String conversationId,
    required String title,
    required List<String> participants,
  }) {
    context.push(
      '/chat/$conversationId',
      extra: {'title': title, 'participants': participants},
    );
  }

  Future<void> _editGroup(FriendGroup group) async {
    final friends = _snapshot.friendsFor(_me);
    final isOwner = group.ownerId == _me;
    final name = TextEditingController(text: group.name);
    final selected = {...group.memberIds};
    final coOwners = {...group.coOwnerIds};
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${group.name}'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama grup'),
                ),
                const SizedBox(height: 10),
                Text('Anggota', style: context.texts.labelLarge),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: friends
                          .map(
                            (link) => CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: selected.contains(link.otherId(_me)),
                              title: Text(link.otherName(_me)),
                              onChanged: (value) => setDialogState(() {
                                final id = link.otherId(_me);
                                if (value == true) {
                                  selected.add(id);
                                } else {
                                  selected.remove(id);
                                  coOwners.remove(id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 8),
                  Text('Co-admin', style: context.texts.labelLarge),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: friends
                            .where(
                              (link) => selected.contains(link.otherId(_me)),
                            )
                            .map(
                              (link) => CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: coOwners.contains(link.otherId(_me)),
                                title: Text(link.otherName(_me)),
                                onChanged: (value) => setDialogState(() {
                                  final id = link.otherId(_me);
                                  value == true
                                      ? coOwners.add(id)
                                      : coOwners.remove(id);
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await _run(
      () => _gateway.updateGroup(
        group.id,
        name: name.text.trim().isEmpty ? group.name : name.text.trim(),
        memberIds: selected.toList(),
        coOwnerIds: isOwner ? coOwners.toList() : group.coOwnerIds,
      ),
      'Grup gagal diperbarui.',
    );
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final friends = _snapshot.friendsFor(_me);
    final incoming = _snapshot.incomingFor(_me);
    final outgoing = _snapshot.outgoingFor(_me);
    final groups = _snapshot.groupsFor(_me);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Teman & Grup'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: PageScroll(
        maxWidth: 760,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Tidak bisa memuat',
              body: _error!,
              action: FilledButton(
                onPressed: _load,
                child: const Text('Coba lagi'),
              ),
            )
          else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tambah teman', style: context.texts.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan email akun Singgah. Mereka harus menyetujui permintaanmu.',
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email teman',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _busy ? null : _sendRequest,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Kirim permintaan'),
                  ),
                ],
              ),
            ),
            if (incoming.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Permintaan masuk', style: context.texts.titleMedium),
              const SizedBox(height: 8),
              ...incoming.map(
                (link) => AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.requesterName.isEmpty
                                  ? link.requesterEmail
                                  : link.requesterName,
                              style: context.texts.titleSmall,
                            ),
                            Text(
                              link.requesterEmail,
                              style: context.texts.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => _gateway.respondFriendRequest(
                                  link.id,
                                  accept: false,
                                ),
                                'Gagal menolak permintaan.',
                              ),
                        child: const Text('Tolak'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => _gateway.respondFriendRequest(
                                  link.id,
                                  accept: true,
                                ),
                                'Gagal menerima permintaan.',
                              ),
                        child: const Text('Terima'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text('Teman', style: context.texts.titleMedium),
                ),
                Text('${friends.length}', style: context.texts.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            if (friends.isEmpty)
              AppCard(
                child: Text(
                  outgoing.isEmpty
                      ? 'Belum ada teman. Kirim permintaan lewat email di atas.'
                      : '${outgoing.length} permintaan menunggu persetujuan.',
                  style: context.texts.bodySmall,
                ),
              )
            else
              ...friends.map(
                (link) => AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(_initials(link.otherName(_me))),
                    ),
                    title: Text(link.otherName(_me)),
                    subtitle: Text(link.otherEmail(_me)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Chat',
                          onPressed: () => _openChat(
                            conversationId: dmConversationId(
                              _me,
                              link.otherId(_me),
                            ),
                            title: link.otherName(_me),
                            participants: [_me, link.otherId(_me)],
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                        ),
                        IconButton(
                          tooltip: 'Hapus teman',
                          onPressed: _busy
                              ? null
                              : () => _confirmRemoveFriend(link),
                          icon: const Icon(Icons.person_remove_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text('Grup', style: context.texts.titleMedium)),
                TextButton.icon(
                  onPressed: _busy ? null : _createGroup,
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('Grup baru'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (groups.isEmpty)
              AppCard(
                child: Text(
                  'Belum ada grup. Buat grup untuk mengirim Titipan ke beberapa teman sekaligus.',
                  style: context.texts.bodySmall,
                ),
              )
            else
              ...groups.map(
                (group) => AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.groups_rounded, size: 20),
                    ),
                    title: Text(group.name),
                    subtitle: Text(
                      '${group.memberIds.length} anggota'
                      '${group.coOwnerIds.isNotEmpty ? ' · ${group.coOwnerIds.length} co-admin' : ''}'
                      '${group.ownerId == _me ? ' · kamu pemilik' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Chat grup',
                          onPressed: () => _openChat(
                            conversationId: 'g_${group.id}',
                            title: group.name,
                            participants: group.chatParticipantIds,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                        ),
                        if (group.canEdit(_me))
                          IconButton(
                            tooltip: 'Edit grup',
                            onPressed: _busy ? null : () => _editGroup(group),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        if (group.ownerId == _me)
                          IconButton(
                            tooltip: 'Hapus grup',
                            onPressed: _busy
                                ? null
                                : () => _run(
                                    () => _gateway.deleteGroup(group.id),
                                    'Grup gagal dihapus.',
                                  ),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
