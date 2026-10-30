import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/responsive/app_breakpoints.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/core/widgets/singgah_mark.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.submitting != current.submitting,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        final message = switch (failure) {
          AuthFailure.invalidCredentials => l10n.authInvalid,
          AuthFailure.emailInUse => l10n.authEmailInUse,
          AuthFailure.emailNotConfirmed => l10n.authEmailNotConfirmed,
          AuthFailure.emailRateLimit => l10n.authRateLimited,
          AuthFailure.network => l10n.authNetwork,
          AuthFailure.cloudNotConfigured => l10n.authCloudMissing,
          AuthFailure.demoDisabled => l10n.tryDemo,
          AuthFailure.oauthRedirect => l10n.authGoogleBrowser,
          AuthFailure.generic => l10n.authErrorGeneric,
        };
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 20,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(flex: 5, child: _AuthHero()),
                            const SizedBox(width: 56),
                            Expanded(
                              flex: 4,
                              child: _buildCard(context, state, l10n),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const _AuthHero(compact: true),
                            const SizedBox(height: 26),
                            _buildCard(context, state, l10n),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    AuthState state,
    AppLocalizations l10n,
  ) {
    final busy = state.submitting;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _signUp ? l10n.createAccount : l10n.welcomeBack,
              style: context.texts.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.authSubtitle,
              style: context.texts.bodySmall?.copyWith(height: 1.55),
            ),
            if (!state.isConfigured) ...[
              const SizedBox(height: 16),
              _CloudNotice(text: l10n.authCloudMissing),
            ],
            const SizedBox(height: 20),
            if (_signUp) ...[
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  labelText: l10n.displayName,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? l10n.authNameRequired : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty || !email.contains('@')) {
                  return l10n.authEmailRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(context, state),
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  (value ?? '').length < 6 ? l10n.authPasswordRequired : null,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: busy ? null : () => _submit(context, state),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_signUp ? l10n.createAccount : l10n.signIn),
            ),
            if (state.isConfigured && AppConfig.googleAuthEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l10n.orDivider, style: context.texts.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => context.read<AuthBloc>().signInWithGoogle(),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                label: Text(l10n.continueWithGoogle),
              ),
            ],
            if (!state.isConfigured) ...[
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () => context.read<AuthBloc>().continueAsDemo(),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: Text(l10n.tryDemo),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.demoModeBody,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _signUp ? l10n.haveAccount : l10n.noAccount,
                  style: context.texts.bodySmall,
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => _signUp = !_signUp),
                  child: Text(_signUp ? l10n.signIn : l10n.signUp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context, AuthState state) {
    if (state.submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final bloc = context.read<AuthBloc>();
    if (_signUp) {
      bloc.signUpWithEmail(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
    } else {
      bloc.signInWithEmail(_email.text.trim(), _password.text);
    }
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SinggahMark(size: 46),
            const SizedBox(width: 12),
            Text(
              AppConfig.appName.toUpperCase(),
              style: context.texts.labelLarge?.copyWith(
                letterSpacing: 3.4,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: context.singgah.ink,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 22 : 34),
        Text(
          l10n.tagline,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style:
              (compact
                      ? context.texts.displaySmall
                      : context.texts.displayLarge)
                  ?.copyWith(height: 1.02, fontSize: compact ? 32 : null),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.authSubtitle,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: context.texts.bodyMedium?.copyWith(
            color: context.singgah.inkMuted,
            height: 1.65,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 26),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ToneChip(
                label: l10n.places,
                color: context.singgah.navy,
                icon: Icons.place_outlined,
              ),
              ToneChip(
                label: l10n.missions,
                color: context.singgah.accent,
                icon: Icons.bolt_outlined,
              ),
              ToneChip(
                label: l10n.titipan,
                color: context.singgah.success,
                icon: Icons.mark_email_unread_outlined,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CloudNotice extends StatelessWidget {
  const _CloudNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.singgah.warningSoft,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: context.singgah.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: context.singgah.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodySmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
