import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/ui/features/app/view_models/app_view_model.dart';

void main() {
  test(
    'profile changes update conversation presentation preferences',
    () async {
      final repository = _FakeProfileRepository();
      addTearDown(repository.dispose);
      final initialProfile = _profile(
        showExecutionStatus: true,
        strictGroundingMode: false,
      );
      final viewModel = AppViewModel(
        initialProfile: initialProfile,
        profileRepository: repository,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.showExecutionStatus, isTrue);
      expect(viewModel.strictGroundingMode, isFalse);

      repository.publish(
        _profile(showExecutionStatus: false, strictGroundingMode: true),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.showExecutionStatus, isFalse);
      expect(viewModel.strictGroundingMode, isTrue);
    },
  );
}

Profile _profile({
  required bool showExecutionStatus,
  required bool strictGroundingMode,
}) => Profile(
  name: 'Test User',
  avatar: '',
  fontSize: 16,
  themeMode: 1,
  language: 'zh_CN',
  showExecutionStatus: showExecutionStatus,
  strictGroundingMode: strictGroundingMode,
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

class _FakeProfileRepository implements ProfileRepository {
  final StreamController<Profile> _changes =
      StreamController<Profile>.broadcast();

  @override
  Stream<Profile> get changes => _changes.stream;

  void publish(Profile profile) => _changes.add(profile);

  @override
  Future<Profile> getProfile() async =>
      _profile(showExecutionStatus: true, strictGroundingMode: false);

  @override
  Future<void> updateProfile(Profile profile) async => publish(profile);

  Future<void> dispose() => _changes.close();
}
