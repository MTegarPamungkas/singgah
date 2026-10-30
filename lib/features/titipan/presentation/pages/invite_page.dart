import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/core/widgets/singgah_mark.dart';
import 'package:singgah/features/titipan/presentation/bloc/invite_bloc.dart';

class InvitePage extends StatelessWidget {
  const InvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.close,
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: BlocBuilder<InviteBloc, InviteState>(
        builder: (context, state) {
          if (state.accepted && state.titipan != null) {
            final titipan = state.titipan!;
            return PageScroll(
              maxWidth: 560,
              children: [
                const SizedBox(height: 30),
                const Center(child: SinggahMark(size: 62)),
                const SizedBox(height: 24),
                Text(
                  l10n.inviteAccepted,
                  textAlign: TextAlign.center,
                  style: context.texts.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.inviteAccepted,
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 22),
                AppCard(
                  accent: context.singgah.success,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titipan.title, style: context.texts.titleLarge),
                      const SizedBox(height: 6),
                      Text(titipan.body, style: context.texts.bodyMedium),
                      const SizedBox(height: 10),
                      InfoRow(
                        icon: Icons.place_outlined,
                        label: l10n.titipanPlace,
                        value: titipan.placeName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/titipan/${titipan.id}'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.inviteOpen),
                ),
              ],
            );
          }
          final failure = state.failure;
          final message = switch (failure) {
            InviteFailure.invalid => l10n.inviteInvalid,
            InviteFailure.alreadyAccepted => l10n.inviteAlreadyAccepted,
            InviteFailure.network => l10n.connectionProblem,
            null => null,
          };
          return PageScroll(
            maxWidth: 560,
            children: [
              const SizedBox(height: 30),
              const Center(child: SinggahMark(size: 62)),
              const SizedBox(height: 24),
              Text(
                l10n.inviteTitle,
                textAlign: TextAlign.center,
                style: context.texts.displaySmall?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.titipanSubtitle,
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.singgah.inkMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              if (message != null)
                AppCard(
                  borderColor: context.singgah.danger.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: context.singgah.danger,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(message, style: context.texts.bodySmall),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: state.accepting || failure == InviteFailure.invalid
                    ? null
                    : () => context.read<InviteBloc>().accept(),
                icon: state.accepting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_read_outlined, size: 18),
                label: Text(
                  state.accepting ? l10n.acceptingInvite : l10n.acceptInvite,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.notNow),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.inviteLinkBody,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
