import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';

/// How the music sounds: speed, skipping silence and the equalizer.
class AudioSettings extends Equatable {
  const AudioSettings({
    this.speed = 1,
    this.skipSilence = false,
    this.equalizerOn = false,
    this.preset = EqualizerPreset.flat,
    this.customGains = const [0, 0, 0, 0, 0],
  });

  /// The speeds to pick from.
  static const List<double> speeds = [0.5, 0.75, 1, 1.25, 1.5, 2];

  static const defaults = AudioSettings();

  final double speed;
  final bool skipSilence;
  final bool equalizerOn;
  final EqualizerPreset preset;

  /// The [EqualizerPreset.custom] bars (dB per band of [equalizerBandsHz]).
  final List<double> customGains;

  /// The bars in use now.
  List<double> get gains =>
      preset == EqualizerPreset.custom ? customGains : preset.gains;

  AudioSettings copyWith({
    double? speed,
    bool? skipSilence,
    bool? equalizerOn,
    EqualizerPreset? preset,
    List<double>? customGains,
  }) => AudioSettings(
    speed: speed ?? this.speed,
    skipSilence: skipSilence ?? this.skipSilence,
    equalizerOn: equalizerOn ?? this.equalizerOn,
    preset: preset ?? this.preset,
    customGains: customGains ?? this.customGains,
  );

  @override
  List<Object?> get props => [
    speed,
    skipSilence,
    equalizerOn,
    preset,
    customGains,
  ];
}

/// The music's sound settings, saved across restarts. Applied to the
/// player by `AudioSettingsBinder`.
class AudioSettingsCubit extends HydratedCubit<AudioSettings> {
  AudioSettingsCubit() : super(AudioSettings.defaults);

  void setSpeed(double speed) {
    if (AudioSettings.speeds.contains(speed)) {
      emit(state.copyWith(speed: speed));
    }
  }

  void setSkipSilence(bool enabled) =>
      emit(state.copyWith(skipSilence: enabled));

  void setEqualizerOn(bool on) => emit(state.copyWith(equalizerOn: on));

  /// Picking a preset turns the equalizer on.
  void setPreset(EqualizerPreset preset) =>
      emit(state.copyWith(preset: preset, equalizerOn: true));

  /// Moves one bar: the sound becomes [EqualizerPreset.custom], starting
  /// from the bars showing.
  void setBand(int band, double db) {
    if (band < 0 || band >= equalizerBandsHz.length) return;
    final gains = [...state.gains];
    gains[band] = db.clamp(-equalizerMaxGainDb, equalizerMaxGainDb);
    emit(
      state.copyWith(
        preset: EqualizerPreset.custom,
        customGains: List.unmodifiable(gains),
        equalizerOn: true,
      ),
    );
  }

  @override
  AudioSettings? fromJson(Map<String, dynamic> json) {
    final speed = (json['speed'] as num?)?.toDouble();
    final gains = json['customGains'];
    return AudioSettings(
      speed: AudioSettings.speeds.contains(speed) ? speed! : 1,
      skipSilence: json['skipSilence'] == true,
      equalizerOn: json['equalizerOn'] == true,
      preset: EqualizerPreset.values.firstWhere(
        (p) => p.name == json['preset'],
        orElse: () => EqualizerPreset.flat,
      ),
      customGains:
          gains is List &&
              gains.length == equalizerBandsHz.length &&
              gains.every((g) => g is num)
          ? List.unmodifiable([
              for (final g in gains)
                (g as num).toDouble().clamp(
                  -equalizerMaxGainDb,
                  equalizerMaxGainDb,
                ),
            ])
          : AudioSettings.defaults.customGains,
    );
  }

  @override
  Map<String, dynamic>? toJson(AudioSettings state) => {
    'speed': state.speed,
    'skipSilence': state.skipSilence,
    'equalizerOn': state.equalizerOn,
    'preset': state.preset.name,
    'customGains': state.customGains,
  };
}
