import 'package:flutter/foundation.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

@immutable
class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? token;
  final String? user;
  final int? userId;
  final String? role;
  final int? listaPreciosId;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.errorMessage,
    this.token,
    this.user,
    this.userId,
    this.role,
    this.listaPreciosId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearError = false,
    String? token,
    String? user,
    int? userId,
    String? role,
    int? listaPreciosId,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      token: token ?? this.token,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      listaPreciosId: listaPreciosId ?? this.listaPreciosId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthState &&
        other.status == status &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => status.hashCode ^ errorMessage.hashCode;
}