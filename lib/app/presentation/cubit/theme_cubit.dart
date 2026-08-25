import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required SharedPreferences preferences})
    : _preferences = preferences,
      super(_decode(preferences.getString(_storageKey)));

  static const _storageKey = 'theme_mode_v1';

  final SharedPreferences _preferences;

  /// Cycles system → light → dark → system, so a single AppBar icon can
  /// drive the whole tri-state toggle without extra UI chrome.
  void cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    emit(next);
    // Best-effort persistence: the UI has already switched optimistically,
    // so a failed write just means the preference won't survive a restart.
    unawaited(
      _preferences
          .setString(_storageKey, _encode(next))
          .catchError((_) => false),
    );
  }

  static ThemeMode _decode(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
