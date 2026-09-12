import 'dart:async';

import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

class ProfileViewModel extends DisposableChangeNotifier {
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
  AppFailure? _error;
  bool _isLoading = false;

  Profile? get profile => _profile;
  AppFailure? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (isDisposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final profile = await _profileRepository.getProfile();
      if (isDisposed) return;
      _applyProfile(profile, notify: false);
    } catch (error) {
      if (isDisposed) return;
      _error = AppFailure.from(error, code: 'profile_load_failed');
    } finally {
      if (!isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> save(Profile profile) async {
    if (isDisposed) return;
    await _profileRepository.updateProfile(profile);
    if (isDisposed) return;
    _applyProfile(profile);
  }

  Future<void> setShowExecutionStatus(bool value) async {
    var profile = _profile;
    if (profile == null) {
      await load();
      profile = _profile;
    }
    if (profile == null || profile.showExecutionStatus == value) return;
    await save(
      profile.copyWith(
        showExecutionStatus: value,
        modifyTimestamp: DateTime.now(),
      ),
    );
  }

  Future<void> setShowVerificationStatus(bool value) async {
    var profile = _profile;
    if (profile == null) {
      await load();
      profile = _profile;
    }
    if (profile == null || profile.showVerificationStatus == value) return;
    await save(
      profile.copyWith(
        showVerificationStatus: value,
        modifyTimestamp: DateTime.now(),
      ),
    );
  }

  Future<void> setStrictGroundingMode(bool value) async {
    var profile = _profile;
    if (profile == null) {
      await load();
      profile = _profile;
    }
    if (profile == null || profile.strictGroundingMode == value) return;
    await save(
      profile.copyWith(
        strictGroundingMode: value,
        modifyTimestamp: DateTime.now(),
      ),
    );
  }

  Future<String?> pickAvatar() => _attachmentRepository.selectImage();

  void _applyProfile(Profile profile, {bool notify = true}) {
    if (isDisposed) return;
    _profile = profile;
    if (notify) notifyListeners();
  }

  @override
  void disposeResources() {
    unawaited(_subscription.cancel());
  }
}
