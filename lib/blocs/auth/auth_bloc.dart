import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(const AuthInitial()) {
    on<AuthCheckSessionRequested>(_onCheckSession);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthUpdateProfileRequested>(_onUpdateProfile);
    on<AuthChangePasswordRequested>(_onChangePassword);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckSession(
    AuthCheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.checkSession();
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));
    try {
      final user = await _authService.login(event.email, event.password);
      emit(Authenticated(user: user));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(msg));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));
    try {
      final user = await _authService.register(
        event.name,
        event.email,
        event.password,
      );
      emit(Authenticated(user: user, successMessage: 'Account created successfully!'));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(msg));
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending reset instructions...'));
    try {
      await _authService.sendPasswordReset(event.email);
      emit(AuthPasswordResetSent(event.email));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(msg));
    }
  }

  Future<void> _onUpdateProfile(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;
    final currentUser = (state as Authenticated).user;

    emit(const AuthLoading(message: 'Updating profile...'));
    try {
      final updated = await _authService.updateProfile(
        currentUser: currentUser,
        displayName: event.displayName,
        bio: event.bio,
        photoUrl: event.photoUrl,
      );
      emit(Authenticated(user: updated, successMessage: 'Profile updated successfully!'));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(msg));
      // Re-emit previous authenticated user state
      emit(Authenticated(user: currentUser));
    }
  }

  Future<void> _onChangePassword(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;
    final currentUser = (state as Authenticated).user;

    emit(const AuthLoading(message: 'Updating password...'));
    try {
      await _authService.changePassword(
        email: currentUser.email,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(Authenticated(user: currentUser, successMessage: 'Password changed successfully!'));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(msg));
      emit(Authenticated(user: currentUser));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(const Unauthenticated(message: 'Logged out successfully'));
  }
}
