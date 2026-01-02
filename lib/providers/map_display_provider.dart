import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapDisplayState {
  final bool showBiomes;
  final bool showElevation;
  final bool showTemperature;
  final bool showPrecipitation;
  final bool showRivers;
  final bool showBorders;
  final bool showCultures;
  final bool showNames;
  final bool showWater;

  const MapDisplayState({
    this.showBiomes = true,
    this.showElevation = false,
    this.showTemperature = false,
    this.showPrecipitation = false,
    this.showRivers = true,
    this.showBorders = true,
    this.showCultures = false,
    this.showNames = false,
    this.showWater = true,
  });

  MapDisplayState copyWith({
    bool? showBiomes,
    bool? showElevation,
    bool? showTemperature,
    bool? showPrecipitation,
    bool? showRivers,
    bool? showBorders,
    bool? showCultures,
    bool? showNames,
    bool? showWater,
  }) {
    return MapDisplayState(
      showBiomes: showBiomes ?? this.showBiomes,
      showElevation: showElevation ?? this.showElevation,
      showTemperature: showTemperature ?? this.showTemperature,
      showPrecipitation: showPrecipitation ?? this.showPrecipitation,
      showRivers: showRivers ?? this.showRivers,
      showBorders: showBorders ?? this.showBorders,
      showCultures: showCultures ?? this.showCultures,
      showNames: showNames ?? this.showNames,
      showWater: showWater ?? this.showWater,
    );
  }
}

class MapDisplayNotifier extends Notifier<MapDisplayState> {
  @override
  MapDisplayState build() => const MapDisplayState();

  void toggleBiomes() => state = state.copyWith(showBiomes: !state.showBiomes);
  void toggleElevation() =>
      state = state.copyWith(showElevation: !state.showElevation);
  void toggleTemperature() =>
      state = state.copyWith(showTemperature: !state.showTemperature);
  void togglePrecipitation() =>
      state = state.copyWith(showPrecipitation: !state.showPrecipitation);
  void toggleRivers() => state = state.copyWith(showRivers: !state.showRivers);
  void toggleBorders() =>
      state = state.copyWith(showBorders: !state.showBorders);
  void toggleCultures() =>
      state = state.copyWith(showCultures: !state.showCultures);
  void toggleNames() => state = state.copyWith(showNames: !state.showNames);
  void toggleWater() => state = state.copyWith(showWater: !state.showWater);
}

final mapDisplayProvider =
    NotifierProvider<MapDisplayNotifier, MapDisplayState>(
      () => MapDisplayNotifier(),
    );
