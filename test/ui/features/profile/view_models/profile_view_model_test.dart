import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/ui/features/profile/view_models/profile_view_model.dart';

void main() {
  test('persists conversation presentation preferences', () async {
    final repository = _ProfileRepository(_profile());
    addTearDown(repository.dispose);
    final viewModel = ProfileViewModel(
      profileRepository: repository,
      attachmentRepository: const _UnusedAttachmentRepository(),
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();
    await viewModel.setShowVerificationStatus(false);
    await viewModel.setShowExecutionStatus(false);
    await viewModel.setStrictGroundingMode(true);

    expect(repository.profile.showVerificationStatus, isFalse);
    expect(repository.profile.showExecutionStatus, isFalse);
    expect(repository.profile.strictGroundingMode, isTrue);
    expect(repository.updateCount, 3);
    expect(viewModel.profile, same(repository.profile));

    await viewModel.setShowVerificationStatus(false);
    await viewModel.setShowExecutionStatus(false);
    await viewModel.setStrictGroundingMode(true);

    expect(repository.updateCount, 3);
  });
}

Profile _profile() => Profile(
  name: 'Test User',
  avatar: '',
  fontSize: 16,
  themeMode: 1,
  language: 'zh_CN',
  showVerificationStatus: true,
  showExecutionStatus: true,
  strictGroundingMode: false,
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

final class _ProfileRepository implements ProfileRepository {
  _ProfileRepository(this.profile);

  final StreamController<Profile> _changes =
      StreamController<Profile>.broadcast();
  Profile profile;
  int updateCount = 0;

  @override
  Stream<Profile> get changes => _changes.stream;

  @override
  Future<Profile> getProfile() async => profile;

  @override
  Future<void> updateProfile(Profile value) async {
    profile = value;
    updateCount++;
    _changes.add(value);
  }

  Future<void> dispose() => _changes.close();
}

final class _UnusedAttachmentRepository implements AttachmentRepository {
  const _UnusedAttachmentRepository();

  @override
  Future<String?> captureImage() async => null;

  @override
  Future<String?> selectFile() async => null;

  @override
  Future<String?> selectImage() async => null;
}
