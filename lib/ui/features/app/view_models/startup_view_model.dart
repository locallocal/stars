import 'dart:async';

import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

class StartupViewModel extends DisposableChangeNotifier {
  StartupViewModel({
    required ProfileRepository profileRepository,
    Future<StartupCapabilitiesReport> Function()? capabilityInitializer,
  }) : _profileRepository = profileRepository,
       _capabilityInitializer = capabilityInitializer;

  final ProfileRepository _profileRepository;
  final Future<StartupCapabilitiesReport> Function()? _capabilityInitializer;
  Profile? _profile;
  AppFailure? _error;
  StartupCapabilitiesReport _capabilitiesReport =
      StartupCapabilitiesReport.empty;
  bool _isLoading = false;
  int _loadGeneration = 0;
  int _capabilityGeneration = 0;

  Profile? get profile => _profile;
  AppFailure? get error => _error;
  StartupCapabilitiesReport get capabilitiesReport => _capabilitiesReport;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;

  Future<void> load() async {
    if (isDisposed) return;
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();
    var profileLoaded = false;
    try {
      final profile = await _profileRepository.getProfile();
      if (isDisposed || generation != _loadGeneration) return;
      _profile = profile;
      profileLoaded = true;
    } catch (error) {
      if (isDisposed || generation != _loadGeneration) return;
      _error = AppFailure.from(error, code: 'startup_required_failed');
    } finally {
      if (!isDisposed && generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }

    // A usable profile is the only requirement for rendering the app. Slow
    // cache hydration, file validation, or network catalog refreshes must not
    // keep the user on the startup screen.
    if (!profileLoaded || isDisposed || generation != _loadGeneration) return;
    final capabilityGeneration = ++_capabilityGeneration;
    unawaited(
      _initializeCapabilities(
        loadGeneration: generation,
        capabilityGeneration: capabilityGeneration,
      ),
    );
  }

  Future<void> retryCapabilities() async {
    if (_capabilityInitializer == null || isDisposed) return;
    final capabilityGeneration = ++_capabilityGeneration;
    await _initializeCapabilities(
      loadGeneration: _loadGeneration,
      capabilityGeneration: capabilityGeneration,
    );
  }

  Future<void> _initializeCapabilities({
    required int loadGeneration,
    required int capabilityGeneration,
  }) async {
    late final StartupCapabilitiesReport capabilitiesReport;
    try {
      capabilitiesReport =
          await _capabilityInitializer?.call() ??
          StartupCapabilitiesReport.empty;
    } on Object catch (error) {
      final failure = AppFailure.from(
        error,
        code: 'startup_capability_initialization_failed',
      );
      capabilitiesReport = StartupCapabilitiesReport([
        StartupCapabilityStatus(
          id: 'capability_initializer',
          required: false,
          state: StartupCapabilityState.degraded,
          diagnosticCode: failure.code,
          retryable: failure.retryable,
        ),
      ]);
    }
    if (isDisposed ||
        loadGeneration != _loadGeneration ||
        capabilityGeneration != _capabilityGeneration) {
      return;
    }
    _capabilitiesReport = capabilitiesReport;
    notifyListeners();
  }
}
