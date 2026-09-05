import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/ui/features/app/view_models/startup_view_model.dart';

void main() {
  test(
    'publishes optional capability degradation without blocking startup',
    () async {
      var attempts = 0;
      final viewModel = StartupViewModel(
        profileRepository: _ProfileRepository(),
        capabilityInitializer: () async {
          attempts += 1;
          return StartupCapabilitiesReport([
            StartupCapabilityStatus(
              id: 'online_skill_catalog',
              required: false,
              state:
                  attempts == 1
                      ? StartupCapabilityState.degraded
                      : StartupCapabilityState.available,
              diagnosticCode:
                  attempts == 1
                      ? 'online_skill_catalog_initialization_failed'
                      : '',
              retryable: attempts == 1,
            ),
          ]);
        },
      );
      addTearDown(viewModel.dispose);
      final firstReportPublished = Completer<void>();
      viewModel.addListener(() {
        if (viewModel.capabilitiesReport.isDegraded &&
            !firstReportPublished.isCompleted) {
          firstReportPublished.complete();
        }
      });

      await viewModel.load();
      await firstReportPublished.future;

      expect(viewModel.profile, isNotNull);
      expect(viewModel.error, isNull);
      expect(viewModel.capabilitiesReport.isDegraded, isTrue);
      expect(viewModel.capabilitiesReport.issues.single.retryable, isTrue);

      await viewModel.retryCapabilities();
      expect(viewModel.capabilitiesReport.isDegraded, isFalse);
    },
  );

  test('renders the app before capability initialization completes', () async {
    final capabilityStarted = Completer<void>();
    final finishCapabilityInitialization =
        Completer<StartupCapabilitiesReport>();
    final viewModel = StartupViewModel(
      profileRepository: _ProfileRepository(),
      capabilityInitializer: () {
        capabilityStarted.complete();
        return finishCapabilityInitialization.future;
      },
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();

    expect(viewModel.profile, isNotNull);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.error, isNull);
    await capabilityStarted.future;
    expect(finishCapabilityInitialization.isCompleted, isFalse);

    final reportPublished = Completer<void>();
    viewModel.addListener(() {
      if (viewModel.capabilitiesReport.isDegraded &&
          !reportPublished.isCompleted) {
        reportPublished.complete();
      }
    });
    finishCapabilityInitialization.complete(
      StartupCapabilitiesReport([
        const StartupCapabilityStatus(
          id: 'online_skill_catalog',
          required: false,
          state: StartupCapabilityState.degraded,
          diagnosticCode: 'catalog_unavailable',
          retryable: true,
        ),
      ]),
    );
    await reportPublished.future;

    expect(
      viewModel.capabilitiesReport.issues.single.id,
      'online_skill_catalog',
    );
  });

  test(
    'awaits required Agent Run recovery before loading the profile',
    () async {
      final recovery = Completer<void>();
      var profileLoads = 0;
      final viewModel = StartupViewModel(
        profileRepository: _ProfileRepository(
          onLoad: () {
            profileLoads += 1;
          },
        ),
        recoveryInitializer: () => recovery.future,
      );
      addTearDown(viewModel.dispose);

      final load = viewModel.load();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isLoading, isTrue);
      expect(profileLoads, 0);

      recovery.complete();
      await load;
      expect(profileLoads, 1);
      expect(viewModel.profile, isNotNull);
    },
  );

  test('fails startup closed when Agent Run recovery fails', () async {
    var profileLoads = 0;
    final viewModel = StartupViewModel(
      profileRepository: _ProfileRepository(
        onLoad: () {
          profileLoads += 1;
        },
      ),
      recoveryInitializer: () => Future<void>.error(StateError('corrupt')),
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();

    expect(profileLoads, 0);
    expect(viewModel.profile, isNull);
    expect(viewModel.error?.code, 'startup_required_failed');
  });
}

final class _ProfileRepository implements ProfileRepository {
  _ProfileRepository({this.onLoad});

  final void Function()? onLoad;

  @override
  Stream<Profile> get changes => const Stream.empty();

  @override
  Future<Profile> getProfile() async {
    onLoad?.call();
    return Profile(
      name: 'Tester',
      avatar: '',
      fontSize: 16,
      themeMode: 0,
      language: 'en',
      createTimestamp: DateTime(2026),
      modifyTimestamp: DateTime(2026),
    );
  }

  @override
  Future<void> updateProfile(Profile profile) async {}
}
