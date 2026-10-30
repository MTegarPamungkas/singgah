import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.isDemo = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool isDemo;
  final DateTime? createdAt;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.substring(0, 1).toUpperCase()
        : '';
    return '$first$last';
  }

  AppUser copyWith({String? displayName, String? avatarUrl, bool? isDemo}) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    avatarUrl,
    isDemo,
    createdAt,
  ];
}
