import 'dart:async';

import 'package:flutter/material.dart';

import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/singgah_mark.dart';
import 'package:singgah/domain/entities/app_settings.dart';
import 'package:singgah/domain/usecases/device_usecases.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:singgah/features/settings/presentation/bloc/settings_bloc.dart';

/// Keeps Notes and history behind the device biometric gate when the user has
/// explicitly enabled it. If biometrics are unavailable the app stays usable
/// instead of trapping the user behind an unlock screen.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool _checkingAvailability = false;
  DateTime? _lastUnlockAt;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<AppSettings>? _settingsSubscription;

  bool get _shouldLock =>
      getIt<AuthBloc>().state.signedIn &&
      getIt<SettingsBloc>().state.biometricLock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = getIt<AuthBloc>().stream.listen((_) => _maybeLock());
    _settingsSubscription = getIt<SettingsBloc>().stream.listen(
      (_) => _maybeLock(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLock());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _shouldLock && !_locked) {
      setState(() => _locked = true);
      return;
    }
    if (state == AppLifecycleState.resumed && !_locked) {
      _maybeLock();
    }
  }

  Future<void> _maybeLock() async {
    if (!mounted || _locked || _authenticating || _checkingAvailability) {
      return;
    }
    if (!_shouldLock) return;
    final unlockedAt = _lastUnlockAt;
    if (unlockedAt != null &&
        DateTime.now().difference(unlockedAt).inSeconds < 2) {
      return;
    }
    _checkingAvailability = true;
    final available = await getIt<CheckBiometrics>()();
    _checkingAvailability = false;
    if (!mounted || !available || !_shouldLock) return;
    setState(() => _locked = true);
    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_authenticating || !mounted) return;
    setState(() => _authenticating = true);
    final success = await getIt<UnlockWithBiometrics>()(
      reason: context.l10n.biometricReason,
    );
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (success) {
        _locked = false;
        _lastUnlockAt = DateTime.now();
      }
    });
  }

  Future<void> _signOut() async {
    await getIt<AuthBloc>().signOut();
    if (!mounted) return;
    setState(() => _locked = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _LockScreen(
              authenticating: _authenticating,
              onUnlock: _authenticate,
              onSignOut: _signOut,
            ),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.authenticating,
    required this.onUnlock,
    required this.onSignOut,
  });

  final bool authenticating;
  final VoidCallback onUnlock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AbsorbPointer(
      absorbing: authenticating,
      child: Material(
        color: context.singgah.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SinggahMark(size: 68),
                    const SizedBox(height: 24),
                    Text(
                      l10n.locked.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: context.texts.displaySmall?.copyWith(
                        fontSize: 30,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.biometricSubtitle,
                      textAlign: TextAlign.center,
                      style: context.texts.bodyMedium?.copyWith(
                        color: context.singgah.inkMuted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: authenticating ? null : onUnlock,
                        icon: authenticating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded, size: 20),
                        label: Text(
                          authenticating ? l10n.loading : l10n.unlock,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: authenticating ? null : onSignOut,
                      child: Text(l10n.signOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
