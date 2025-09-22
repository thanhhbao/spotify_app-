import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  // Chế độ mặc định theo light/dark của thiết bị
  ThemeCubit() : super(ThemeMode.system);

  // Cập nhật chế độ sáng/tối
  void updateTheme(ThemeMode themeMode) => emit(themeMode);

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    // Chuyển đổi từ JSON sang ThemeMode
    final String? themeMode = json['themeMode'] as String?;
    if (themeMode == 'dark') {
      return ThemeMode.dark;
    } else if (themeMode == 'light') {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    // Chuyển đổi từ ThemeMode sang JSON
    switch (state) {
      case ThemeMode.dark:
        return {'themeMode': 'dark'};
      case ThemeMode.light:
        return {'themeMode': 'light'};
      case ThemeMode.system:
      default:
        return {'themeMode': 'system'};
    }
  }
}
