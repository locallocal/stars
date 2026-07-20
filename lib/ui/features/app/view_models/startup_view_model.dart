import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/profile_repository.dart';

class StartupViewModel extends ChangeNotifier {
  StartupViewModel({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;
  Profile? _profile;
  Object? _error;
  bool _isLoading = false;
  int _loadGeneration = 0;

  Profile? get profile => _profile;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final profile = await _profileRepository.getProfile();
      if (generation != _loadGeneration) return;
      _profile = profile;
    } catch (error) {
      if (generation != _loadGeneration) return;
      _error = error;
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
