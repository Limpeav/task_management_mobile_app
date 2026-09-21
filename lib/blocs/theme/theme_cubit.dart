import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/storage_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final StorageService _storage;

  ThemeCubit(this._storage)
      : super(_storage.isDarkMode() ? ThemeMode.dark : ThemeMode.light);

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _storage.setDarkMode(newMode == ThemeMode.dark);
    emit(newMode);
  }

  void setTheme(ThemeMode mode) {
    _storage.setDarkMode(mode == ThemeMode.dark);
    emit(mode);
  }
}
