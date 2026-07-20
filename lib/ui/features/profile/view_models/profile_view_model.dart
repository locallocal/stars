import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required ProfileRepository profileRepository,
    required AttachmentRepository attachmentRepository,
  }) : _profileRepository = profileRepository,
       _attachmentRepository = attachmentRepository {
    _subscription = _profileRepository.changes.listen(_applyProfile);
  }

  final ProfileRepository _profileRepository;
  final AttachmentRepository _attachmentRepository;
  late final StreamSubscription<Profile> _subscription;
  Profile? _profile;
  Object? _error;
  bool _isLoading = false;

  Profile? get profile => _profile;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _applyProfile(await _profileRepository.getProfile(), notify: false);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(Profile profile) async {
    await _profileRepository.updateProfile(profile);
    _applyProfile(profile);
  }

  Future<String?> pickAvatar() => _attachmentRepository.selectImage();

  void _applyProfile(Profile profile, {bool notify = true}) {
    _profile = profile;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
