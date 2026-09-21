import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});
}

class Authenticated extends AuthState {
  final AppUser user;
  final String? successMessage;

  const Authenticated({required this.user, this.successMessage});
}

class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated({this.message});
}

class AuthPasswordResetSent extends AuthState {
  final String email;
  const AuthPasswordResetSent(this.email);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
