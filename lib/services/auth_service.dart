import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  AuthService(this._storage);

  bool get _isFirebaseConfigured => Firebase.apps.isNotEmpty;
  fb_auth.FirebaseAuth? get _fbAuth =>
      _isFirebaseConfigured ? fb_auth.FirebaseAuth.instance : null;

  Future<AppUser?> checkSession() async {
    // 1. Check Firebase current user
    if (_fbAuth?.currentUser != null) {
      final fbUser = _fbAuth!.currentUser!;
      final user = AppUser(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName?.isNotEmpty == true
            ? fbUser.displayName!
            : (fbUser.email?.split('@').first ?? 'User'),
        photoUrl: fbUser.photoURL,
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );
      await _storage.setCurrentUser(user);
      return user;
    }

    // 2. Check local stored user
    return _storage.getCurrentUser();
  }

  Future<AppUser> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (_fbAuth != null) {
      try {
        final credential = await _fbAuth!.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        final fbUser = credential.user!;
        final user = AppUser(
          id: fbUser.uid,
          email: fbUser.email ?? cleanEmail,
          displayName: fbUser.displayName?.isNotEmpty == true
              ? fbUser.displayName!
              : (cleanEmail.split('@').first),
          photoUrl: fbUser.photoURL,
          createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
        );
        await _storage.setCurrentUser(user);
        await _storage.saveUser(user);
        return user;
      } on fb_auth.FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth signIn failed: ${e.code} - ${e.message}');
        // If it's a genuine invalid-credential or user-not-found error, rethrow
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'user-disabled') {
          throw Exception(e.message ?? 'Invalid email or password.');
        }
        // Otherwise try fallback
      } catch (e) {
        debugPrint('Firebase login exception: $e');
      }
    }

    // Fallback: Local database authentication
    final users = _storage.getAllUsers();
    final found = users.firstWhere(
      (u) => (u['email'] as String).toLowerCase() == cleanEmail,
      orElse: () => <String, dynamic>{},
    );

    if (found.isEmpty) {
      throw Exception('No account found with this email.');
    }

    if (found['password'] != cleanPassword) {
      throw Exception('Incorrect password. Please try again.');
    }

    final user = AppUser.fromMap(found);
    await _storage.setCurrentUser(user);
    return user;
  }

  Future<AppUser> register(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty || cleanName.isEmpty) {
      throw Exception('Please fill in all fields.');
    }

    if (cleanPassword.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    if (_fbAuth != null) {
      try {
        final credential = await _fbAuth!.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        final fbUser = credential.user!;
        await fbUser.updateDisplayName(cleanName);

        final user = AppUser(
          id: fbUser.uid,
          email: cleanEmail,
          displayName: cleanName,
          createdAt: DateTime.now(),
        );
        await _storage.setCurrentUser(user);
        await _storage.saveUser(user, password: cleanPassword);
        return user;
      } on fb_auth.FirebaseAuthException catch (e) {
        debugPrint('Firebase register error: ${e.code} - ${e.message}');
        if (e.code == 'email-already-in-use') {
          throw Exception('An account with this email already exists.');
        } else if (e.code == 'invalid-email') {
          throw Exception('The email address is badly formatted.');
        } else if (e.code == 'weak-password') {
          throw Exception('Password is too weak.');
        }
      } catch (e) {
        debugPrint('Firebase register fallback triggered: $e');
      }
    }

    // Fallback: Local registration
    final users = _storage.getAllUsers();
    final exists = users.any(
      (u) => (u['email'] as String).toLowerCase() == cleanEmail,
    );

    if (exists) {
      throw Exception('An account with this email already exists.');
    }

    final user = AppUser(
      id: _uuid.v4(),
      email: cleanEmail,
      displayName: cleanName,
      createdAt: DateTime.now(),
    );

    await _storage.saveUser(user, password: cleanPassword);
    await _storage.setCurrentUser(user);
    return user;
  }

  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Please enter your email address.');
    }

    if (_fbAuth != null) {
      try {
        await _fbAuth!.sendPasswordResetEmail(email: cleanEmail);
        return;
      } on fb_auth.FirebaseAuthException catch (e) {
        debugPrint('Firebase password reset error: ${e.code} - ${e.message}');
        if (e.code == 'user-not-found') {
          throw Exception('No user found with this email.');
        }
      } catch (e) {
        debugPrint('Firebase password reset exception: $e');
      }
    }

    // Fallback: Verify email exists locally
    final users = _storage.getAllUsers();
    final found = users.any(
      (u) => (u['email'] as String).toLowerCase() == cleanEmail,
    );

    if (!found) {
      throw Exception('No account found with this email address.');
    }
  }

  Future<AppUser> updateProfile({
    required AppUser currentUser,
    required String displayName,
    String? bio,
    String? photoUrl,
  }) async {
    final updated = currentUser.copyWith(
      displayName: displayName.trim(),
      bio: bio?.trim(),
      photoUrl: photoUrl,
    );

    if (_fbAuth?.currentUser != null) {
      try {
        await _fbAuth!.currentUser!.updateDisplayName(displayName.trim());
        if (photoUrl != null) {
          await _fbAuth!.currentUser!.updatePhotoURL(photoUrl);
        }
      } catch (e) {
        debugPrint('Error updating Firebase user profile: $e');
      }
    }

    await _storage.saveUser(updated);
    await _storage.setCurrentUser(updated);
    return updated;
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters.');
    }

    if (_fbAuth?.currentUser != null) {
      try {
        await _fbAuth!.currentUser!.updatePassword(newPassword);
      } catch (e) {
        debugPrint('Firebase change password error: $e');
      }
    }

    final users = _storage.getAllUsers();
    final index = users.indexWhere(
      (u) => (u['email'] as String).toLowerCase() == email.toLowerCase(),
    );

    if (index >= 0) {
      if (users[index]['password'] != null &&
          users[index]['password'] != currentPassword) {
        throw Exception('Current password does not match.');
      }
      users[index]['password'] = newPassword;
      await _storage.saveUser(AppUser.fromMap(users[index]), password: newPassword);
    }
  }

  Future<void> logout() async {
    if (_fbAuth != null) {
      try {
        await _fbAuth!.signOut();
      } catch (e) {
        debugPrint('Firebase sign out error: $e');
      }
    }
    await _storage.setCurrentUser(null);
  }
}
