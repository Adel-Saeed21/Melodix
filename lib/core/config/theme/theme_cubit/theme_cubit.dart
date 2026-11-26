import 'package:material_ui/material_ui.dart';

import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(initial);

  /// The look Melodix comes with.
  static const ThemeMode initial = ThemeMode.dark;

  void updateTheme(ThemeMode mode) => emit(mode);

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    return ThemeMode.values[json['theme'] as int];
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    return {'theme': state.index};
  }
}
