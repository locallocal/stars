import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/repositories/model_log_repository.dart';
import 'package:stars/ui/features/chat/view_models/model_log_view_model.dart';

import '../../../../support/fake_model_log_repository.dart';

void main() {
  late FakeModelLogRepository repository;
  late ModelLogViewModel vm;
  late List<Uri> opened;
  late List<String> copied;
  setUp(() {
    repository = FakeModelLogRepository();
    opened = [];
    copied = [];
    vm = ModelLogViewModel(
      chatId: 'chat-a',
      repository: repository,
      openDirectory: (uri) async {
        opened.add(uri);
        return true;
      },
      copyText: (text) async {
        copied.add(text);
      },
    );
  });
  tearDown(() async {
    vm.dispose();
    await repository.dispose();
  });

  test('loads, persists and forwards folder actions', () async {
    await vm.load();
    expect(vm.settings?.enabled, isFalse);
    await vm.setEnabled(true);
    expect(vm.settings?.enabled, isTrue);
    await vm.copyPath();
    expect(copied, [repository.settings.directoryPath]);
    expect(vm.pathCopied, isTrue);
    await vm.openDirectory();
    expect(repository.directoryRequests, 1);
    expect(opened.single, Uri.directory(repository.settings.directoryPath));
  });

  test(
    'failed saves keep the old value and repeated clicks are ignored',
    () async {
      await vm.load();
      repository.failSave = true;
      repository.pendingSave = Completer<void>();
      final save = vm.setEnabled(true);
      expect(vm.busy, isTrue);
      await vm.setEnabled(false);
      expect(repository.saves, 1);
      repository.pendingSave!.complete();
      await save;
      expect(vm.busy, isFalse);
      expect(vm.settings?.enabled, isFalse);
      expect(vm.error, ModelLogActionError.save);
      repository.failSave = false;
      await vm.setEnabled(true);
      expect(vm.error, isNull);
      expect(vm.settings?.enabled, isTrue);
    },
  );

  test('load failure can be retried and disk failures update live', () async {
    repository.failLoad = true;
    await vm.load();
    expect(vm.error, ModelLogActionError.load);
    repository.failLoad = false;
    await vm.load();
    expect(vm.error, isNull);
    repository.controller.add(
      ModelLogSettings(
        enabled: true,
        directoryPath: repository.settings.directoryPath,
        writeFailed: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(vm.settings?.writeFailed, isTrue);
  });

  test('unsupported folder opening is reported', () async {
    vm.dispose();
    vm = ModelLogViewModel(
      chatId: 'chat-a',
      repository: repository,
      openDirectory: (_) async => false,
      copyText: (_) async {},
    );
    await vm.load();
    await vm.openDirectory();
    expect(vm.error, ModelLogActionError.open);
  });

  test('completion after disposal does not notify a removed screen', () async {
    await vm.load();
    repository.pendingSave = Completer<void>();
    final save = vm.setEnabled(true);
    vm.dispose();
    repository.pendingSave!.complete();
    await save;
  });
}
