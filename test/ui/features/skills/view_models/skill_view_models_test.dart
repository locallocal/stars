import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/catalog_controller.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/ui/features/bots/view_models/bot_skill_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_skill_view_model.dart';
import 'package:stars/ui/features/skills/view_models/skill_library_view_model.dart';

void main() {
  test(
    'library imports the selected source and publishes installed Skills',
    () async {
      final repository = _FakeSkillRepository([_skill('one')]);
      final picker = _FakeSkillPickerRepository(
        const SkillImportSource(
          kind: SkillImportKind.directory,
          path: '/picked/two',
        ),
      );
      final viewModel = SkillLibraryViewModel(
        skillRepository: repository,
        pickerRepository: picker,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load();

      expect(viewModel.skills.map((skill) => skill.name), ['one']);

      final imported = await viewModel.importDirectory();

      expect(repository.installedSources.single.path, '/picked/two');
      expect(imported?.name, 'two');
      expect(viewModel.lastImported?.id, 'user:two');
      expect(viewModel.isImporting, isFalse);
    },
  );

  test('library merges and loads read-only bundled Skills', () async {
    final bundled = _bundledSkillContent();
    final repository = _FakeSkillRepository([_skill('one')]);
    final viewModel = SkillLibraryViewModel(
      skillRepository: repository,
      pickerRepository: const _FakeSkillPickerRepository(null),
      bundledSkillLoader: () async => [bundled],
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();

    expect(viewModel.skills.map((skill) => skill.id), [
      'system:conversation-history',
      'user:one',
    ]);
    expect(
      await viewModel.loadContent('system:conversation-history'),
      same(bundled),
    );

    await viewModel.uninstall('system:conversation-history');

    expect(viewModel.skills.first.id, 'system:conversation-history');
  });

  test('library publishes immutable list snapshots', () async {
    final catalog = _FakeSkillCatalogController([_catalogUpdate('one')]);
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([_skill('one')]),
      pickerRepository: const _FakeSkillPickerRepository(null),
      catalogService: catalog,
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();
    final skillsSnapshot = viewModel.skills;
    final updatesSnapshot = viewModel.availableUpdates;

    expect(() => viewModel.skills.clear(), throwsUnsupportedError);
    expect(() => viewModel.filteredSkills.clear(), throwsUnsupportedError);
    expect(() => viewModel.paginatedSkills.clear(), throwsUnsupportedError);
    expect(() => updatesSnapshot.clear(), throwsUnsupportedError);

    catalog.updates.add(_catalogUpdate('two'));

    expect(skillsSnapshot, hasLength(1));
    expect(updatesSnapshot, hasLength(1));
    await viewModel.load();
    expect(viewModel.availableUpdates, hasLength(2));
    expect(updatesSnapshot, hasLength(1));
  });

  test('library searches Skill names and installation metadata', () async {
    final repository = _FakeSkillRepository([
      _skill('Release Notes', description: 'Create polished changelogs'),
      _skill('Code Review', description: 'Find concise improvements'),
    ]);
    final viewModel = SkillLibraryViewModel(
      skillRepository: repository,
      pickerRepository: const _FakeSkillPickerRepository(null),
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    viewModel.search('  release  ');
    expect(viewModel.filteredSkills.map((skill) => skill.name), [
      'Release Notes',
    ]);

    viewModel.search('CONCISE');
    expect(viewModel.filteredSkills.map((skill) => skill.name), [
      'Code Review',
    ]);

    viewModel.search('user:release notes');
    expect(viewModel.filteredSkills.map((skill) => skill.name), [
      'Release Notes',
    ]);

    viewModel.search('file:///Code Review');
    expect(viewModel.filteredSkills.map((skill) => skill.name), [
      'Code Review',
    ]);

    viewModel.search('missing');
    expect(viewModel.filteredSkills, isEmpty);

    viewModel.clearSearch();
    expect(viewModel.query, isEmpty);
    expect(viewModel.filteredSkills, hasLength(2));
  });

  test('library refresh discovers Skills installed outside the page', () async {
    final repository = _FakeSkillRepository([_skill('one')]);
    final viewModel = SkillLibraryViewModel(
      skillRepository: repository,
      pickerRepository: const _FakeSkillPickerRepository(null),
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    repository.replaceSilently([_skill('one'), _skill('from-chat')]);
    expect(viewModel.skills.map((skill) => skill.name), ['one']);

    await viewModel.refresh();

    expect(viewModel.skills.map((skill) => skill.name), ['one', 'from-chat']);
  });

  test(
    'library paginates, resets on search, and corrects removed pages',
    () async {
      final repository = _FakeSkillRepository([
        for (var index = 1; index <= 12; index += 1)
          _skill(
            'Skill $index',
            description: index <= 6 ? 'Alpha group' : 'Beta group',
          ),
      ]);
      final viewModel = SkillLibraryViewModel(
        skillRepository: repository,
        pickerRepository: const _FakeSkillPickerRepository(null),
        pageSize: 5,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load();

      expect(viewModel.currentPage, 1);
      expect(viewModel.totalPages, 3);
      expect(viewModel.paginatedSkills.map((skill) => skill.name), [
        'Skill 1',
        'Skill 2',
        'Skill 3',
        'Skill 4',
        'Skill 5',
      ]);
      expect(viewModel.hasPreviousPage, isFalse);
      expect(viewModel.hasNextPage, isTrue);

      viewModel.nextPage();
      viewModel.nextPage();
      expect(viewModel.currentPage, 3);
      expect(viewModel.paginatedSkills.map((skill) => skill.name), [
        'Skill 11',
        'Skill 12',
      ]);
      expect(viewModel.hasNextPage, isFalse);

      viewModel.search('beta');
      expect(viewModel.currentPage, 1);
      expect(viewModel.totalPages, 2);
      expect(viewModel.paginatedSkills.map((skill) => skill.name), [
        'Skill 7',
        'Skill 8',
        'Skill 9',
        'Skill 10',
        'Skill 11',
      ]);

      viewModel.clearSearch();
      viewModel.nextPage();
      viewModel.nextPage();
      await viewModel.uninstall('user:Skill 12');
      await Future<void>.delayed(Duration.zero);
      await viewModel.uninstall('user:Skill 11');
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.currentPage, 2);
      expect(viewModel.totalPages, 2);
      expect(viewModel.paginatedSkills.map((skill) => skill.name), [
        'Skill 6',
        'Skill 7',
        'Skill 8',
        'Skill 9',
        'Skill 10',
      ]);
    },
  );

  test('bot Skills can be added, disabled, enabled, and removed', () async {
    final skillRepository = _FakeSkillRepository([_skill('one')]);
    final bindingRepository = _FakeBindingRepository();
    final viewModel = BotSkillViewModel(
      botId: 'bot-1',
      skillRepository: skillRepository,
      bindingRepository: bindingRepository,
      supportsAutoActivation: true,
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    expect(viewModel.addedSkills, isEmpty);
    expect(viewModel.availableSkills.map((skill) => skill.id), ['user:one']);

    await viewModel.addSkill('user:one');
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.addedSkills.map((skill) => skill.id), ['user:one']);
    expect(
      bindingRepository.bindings.single.activationMode,
      SkillActivationMode.auto,
    );

    await viewModel.setEnabled('user:one', false);
    await Future<void>.delayed(Duration.zero);
    expect(bindingRepository.bindings, hasLength(1));
    expect(bindingRepository.bindings.single.enabled, isFalse);
    expect(viewModel.bindingFor('user:one')?.enabled, isFalse);

    await viewModel.setEnabled('user:one', true);

    await viewModel.removeSkill('user:one');
    await Future<void>.delayed(Duration.zero);
    expect(bindingRepository.bindings, isEmpty);
    expect(viewModel.addedSkills, isEmpty);
    expect(viewModel.availableSkills.map((skill) => skill.id), ['user:one']);
  });

  test(
    'bundled bot Skills can be added, disabled, enabled, and removed',
    () async {
      final bundled = _bundledSkillContent();
      final bindingRepository = _FakeBindingRepository();
      final viewModel = BotSkillViewModel(
        botId: 'bot-1',
        skillRepository: _FakeSkillRepository(const []),
        bindingRepository: bindingRepository,
        bundledSkillLoader: () async => [bundled],
        supportsAutoActivation: true,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load();

      expect(viewModel.addedSkills, isEmpty);
      expect(viewModel.availableSkills.map((skill) => skill.id), [
        conversationHistorySkillId,
      ]);

      await viewModel.addSkill(conversationHistorySkillId);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.addedSkills.map((skill) => skill.id), [
        conversationHistorySkillId,
      ]);
      expect(bindingRepository.bindings.single.enabled, isTrue);

      await viewModel.setEnabled(conversationHistorySkillId, false);
      await Future<void>.delayed(Duration.zero);
      expect(
        viewModel.bindingFor(conversationHistorySkillId)?.enabled,
        isFalse,
      );

      await viewModel.setEnabled(conversationHistorySkillId, true);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.bindingFor(conversationHistorySkillId)?.enabled, isTrue);

      await viewModel.removeSkill(conversationHistorySkillId);
      await Future<void>.delayed(Duration.zero);
      expect(bindingRepository.bindings, isEmpty);
      expect(viewModel.availableSkills.map((skill) => skill.id), [
        conversationHistorySkillId,
      ]);
    },
  );

  test('bot Skill added and available lists paginate independently', () async {
    final skillRepository = _FakeSkillRepository([
      for (var index = 1; index <= 13; index += 1) _skill('Skill $index'),
    ]);
    final timestamp = DateTime(2026, 7, 26);
    final bindingRepository = _FakeBindingRepository([
      for (var index = 1; index <= 7; index += 1)
        BotSkillBinding(
          botId: 'bot-1',
          skillId: 'user:Skill $index',
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
    ]);
    final viewModel = BotSkillViewModel(
      botId: 'bot-1',
      skillRepository: skillRepository,
      bindingRepository: bindingRepository,
      supportsAutoActivation: true,
      pageSize: 5,
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    expect(viewModel.totalAddedPages, 2);
    expect(viewModel.paginatedAddedSkills.map((skill) => skill.name), [
      'Skill 1',
      'Skill 2',
      'Skill 3',
      'Skill 4',
      'Skill 5',
    ]);
    viewModel.nextAddedPage();
    expect(viewModel.currentAddedPage, 2);
    expect(viewModel.paginatedAddedSkills.map((skill) => skill.name), [
      'Skill 6',
      'Skill 7',
    ]);

    expect(viewModel.totalAvailablePages, 2);
    expect(viewModel.paginatedAvailableSkills.map((skill) => skill.name), [
      'Skill 8',
      'Skill 9',
      'Skill 10',
      'Skill 11',
      'Skill 12',
    ]);
    viewModel.nextAvailablePage();
    expect(viewModel.paginatedAvailableSkills.single.name, 'Skill 13');

    await viewModel.removeSkill('user:Skill 7');
    await Future<void>.delayed(Duration.zero);
    await viewModel.removeSkill('user:Skill 6');
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.currentAddedPage, 1);
    expect(viewModel.totalAddedPages, 1);
    expect(viewModel.paginatedAddedSkills, hasLength(5));
    expect(viewModel.currentAvailablePage, 2);
    expect(viewModel.paginatedAvailableSkills.map((skill) => skill.name), [
      'Skill 11',
      'Skill 12',
      'Skill 13',
    ]);
  });

  test(
    'bot Skill picker searches names and descriptions and resets pagination',
    () async {
      final viewModel = BotSkillViewModel(
        botId: 'bot-1',
        skillRepository: _FakeSkillRepository([
          _skill('Release Notes', description: 'Create polished changelogs'),
          _skill('Code Review', description: 'Find concise improvements'),
          _skill('Research'),
          _skill('Translation'),
        ]),
        bindingRepository: _FakeBindingRepository(),
        supportsAutoActivation: true,
        pageSize: 2,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load();

      viewModel.nextAvailablePage();
      expect(viewModel.currentAvailablePage, 2);

      viewModel.searchAvailableSkills('  release  ');
      expect(viewModel.currentAvailablePage, 1);
      expect(viewModel.totalAvailablePages, 1);
      expect(viewModel.paginatedAvailableSkills.map((skill) => skill.name), [
        'Release Notes',
      ]);

      viewModel.searchAvailableSkills('CONCISE');
      expect(viewModel.paginatedAvailableSkills.map((skill) => skill.name), [
        'Code Review',
      ]);

      viewModel.searchAvailableSkills('missing');
      expect(viewModel.paginatedAvailableSkills, isEmpty);
      expect(viewModel.currentAvailablePage, 0);

      viewModel.clearAvailableSearch();
      expect(viewModel.availableQuery, isEmpty);
      expect(viewModel.totalAvailablePages, 2);
      expect(viewModel.paginatedAvailableSkills.map((skill) => skill.name), [
        'Release Notes',
        'Code Review',
      ]);
    },
  );

  test(
    'bot exposes Skills only while automatic activation is supported',
    () async {
      final skillRepository = _FakeSkillRepository([_skill('auto')]);
      final bindingRepository = _FakeBindingRepository();
      final viewModel = BotSkillViewModel(
        botId: 'bot-1',
        skillRepository: skillRepository,
        bindingRepository: bindingRepository,
        skillToolProvider: _AutoProvider(),
      );
      addTearDown(viewModel.dispose);
      await viewModel.load();
      await viewModel.addSkill('user:auto');

      expect(viewModel.supportsAutoActivation, isTrue);
      expect(
        viewModel.bindingFor('user:auto')?.activationMode,
        SkillActivationMode.auto,
      );
      viewModel.updateSupportsAutoActivation(false);
      expect(viewModel.skills, isEmpty);
      expect(viewModel.addedSkills, isEmpty);
      expect(viewModel.availableSkills, isEmpty);
      expect(viewModel.bindings, isEmpty);
    },
  );

  test('chat Skill catalog is empty for unsupported models', () async {
    final skillRepository = _FakeSkillRepository([
      _skill('first'),
      _skill('second'),
      _skill('disabled'),
      _skill('unbound'),
    ]);
    final timestamp = DateTime(2026, 7, 26);
    final bindingRepository = _FakeBindingRepository([
      BotSkillBinding(
        botId: 'bot-1',
        skillId: 'user:first',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      BotSkillBinding(
        botId: 'bot-1',
        skillId: 'user:second',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      BotSkillBinding(
        botId: 'bot-1',
        skillId: 'user:disabled',
        enabled: false,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ]);
    final viewModel = ChatSkillViewModel(
      botId: 'bot-1',
      skillRepository: skillRepository,
      bindingRepository: bindingRepository,
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    expect(viewModel.availableSkills, isEmpty);

    final supportedViewModel = ChatSkillViewModel(
      botId: 'bot-1',
      skillRepository: skillRepository,
      bindingRepository: bindingRepository,
      supportsAutoActivation: true,
    );
    addTearDown(supportedViewModel.dispose);
    await supportedViewModel.load();
    expect(supportedViewModel.availableSkills.map((skill) => skill.id), [
      'user:first',
      'user:second',
    ]);
  });

  test('chat Skill catalog includes only enabled bundled bindings', () async {
    final bundled = _bundledSkillContent();
    final timestamp = DateTime(2026, 7, 26);
    final bindingRepository = _FakeBindingRepository([
      BotSkillBinding(
        botId: 'bot-1',
        skillId: conversationHistorySkillId,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ]);
    final viewModel = ChatSkillViewModel(
      botId: 'bot-1',
      skillRepository: _FakeSkillRepository(const []),
      bindingRepository: bindingRepository,
      bundledSkillLoader: () async => [bundled],
      supportsAutoActivation: true,
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    expect(viewModel.availableSkills.map((skill) => skill.id), [
      conversationHistorySkillId,
    ]);

    await bindingRepository.save(
      bindingRepository.bindings.single.copyWith(
        enabled: false,
        updatedAt: timestamp.add(const Duration(minutes: 1)),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.availableSkills, isEmpty);
  });
}

final class _AutoProvider extends AiProvider {
  _AutoProvider()
    : super(
        Bot(
          id: 'bot-1',
          name: 'Bot',
          avatar: '',
          provider: 'test',
          baseURL: '',
          apiKey: '',
          apiType: Bot.apiTypeOpenAI,
          model: 'test',
          systemPrompt: '',
          createTimestamp: DateTime(2026),
          modifyTimestamp: DateTime(2026),
        ),
      );

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

SkillDescriptor _skill(String name, {String? description}) {
  final timestamp = DateTime(2026, 7, 26);
  return SkillDescriptor(
    id: 'user:$name',
    name: name,
    description: description ?? '$name description',
    version: '1.0.0',
    scope: SkillScope.user,
    sourceUri: 'file:///$name',
    rootPath: '/skills/$name',
    contentDigest: 'digest-$name',
    trustState: SkillTrustState.userReviewed,
    validationStatus: SkillValidationStatus.valid,
    compatibility: '',
    installedAt: timestamp,
    updatedAt: timestamp,
  );
}

OnlineSkillCatalogEntry _catalogUpdate(String name) => OnlineSkillCatalogEntry(
  id: 'user:$name',
  catalogId: 'catalog',
  name: name,
  description: '$name update',
  version: '2.0.0',
  publisherId: 'publisher',
  archiveUri: Uri.parse('https://example.com/$name.zip'),
  archiveDigest: 'archive-$name',
  contentDigest: 'content-$name',
);

SkillContent _bundledSkillContent() {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: conversationHistorySkillId,
      name: 'conversation-history',
      description: 'Search exact messages from the current conversation.',
      version: '1',
      scope: SkillScope.bundled,
      sourceUri: 'asset:///conversation-history/SKILL.md',
      rootPath: 'assets/skills/system/conversation-history',
      contentDigest: 'system-digest',
      trustState: SkillTrustState.bundledTrusted,
      validationStatus: SkillValidationStatus.valid,
      compatibility: 'Stars',
      installedAt: timestamp,
      updatedAt: timestamp,
      requestedToolNames: conversationHistoryToolNames,
    ),
    instructions: 'Query conversation history when exact context is needed.',
    files: const ['SKILL.md'],
  );
}

final class _FakeSkillRepository implements SkillRepository {
  _FakeSkillRepository(List<SkillDescriptor> initial)
    : _skills = List<SkillDescriptor>.of(initial);

  final StreamController<List<SkillDescriptor>> _changes =
      StreamController<List<SkillDescriptor>>.broadcast();
  final List<SkillImportSource> installedSources = [];
  List<SkillDescriptor> _skills;

  void replaceSilently(List<SkillDescriptor> skills) {
    _skills = List<SkillDescriptor>.of(skills);
  }

  @override
  Stream<List<SkillDescriptor>> get changes => _changes.stream;

  @override
  Future<SkillDescriptor?> getById(String id) async =>
      _skills.where((skill) => skill.id == id).firstOrNull;

  @override
  Future<List<SkillDescriptor>> getInstalled({
    bool forceRefresh = false,
  }) async => List<SkillDescriptor>.unmodifiable(_skills);

  @override
  Future<SkillDescriptor> install(SkillImportSource source) async {
    installedSources.add(source);
    final name = source.path.split('/').last;
    final skill = _skill(name);
    _skills = [..._skills, skill];
    _changes.add(List<SkillDescriptor>.unmodifiable(_skills));
    return skill;
  }

  @override
  Future<SkillContent> load(String skillId, {String? contentDigest}) async {
    return SkillContent(
      descriptor: (await getById(skillId))!,
      instructions: 'Instructions.',
    );
  }

  @override
  Future<SkillResourceContent> readResource(
    String skillId,
    String relativePath, {
    String? contentDigest,
  }) => throw UnsupportedError('Resource reading is not used in this test.');

  @override
  Future<void> uninstall(String skillId) async {
    _skills = _skills.where((skill) => skill.id != skillId).toList();
    _changes.add(List<SkillDescriptor>.unmodifiable(_skills));
  }
}

final class _FakeSkillPickerRepository implements SkillPickerRepository {
  const _FakeSkillPickerRepository(this.source);

  final SkillImportSource? source;

  @override
  Future<SkillImportSource?> pickDirectory() async => source;

  @override
  Future<SkillImportSource?> pickZipArchive() async => source;
}

final class _FakeSkillCatalogController implements SkillCatalogController {
  _FakeSkillCatalogController(this.updates);

  final List<OnlineSkillCatalogEntry> updates;

  @override
  Future<List<OnlineSkillCatalogEntry>> availableUpdates() async => updates;

  @override
  Future<void> applyAutomaticUpdates() async {}

  @override
  Future<SkillDescriptor> install(OnlineSkillCatalogEntry entry) {
    throw UnimplementedError();
  }

  @override
  Future<List<OnlineSkillCatalogEntry>> refresh(SkillCatalogSource catalog) {
    throw UnimplementedError();
  }

  @override
  Future<void> refreshConfiguredCatalogs() async {}
}

final class _FakeBindingRepository implements BotSkillBindingRepository {
  _FakeBindingRepository([List<BotSkillBinding> initial = const []])
    : bindings = List<BotSkillBinding>.of(initial);

  final StreamController<void> _changes = StreamController<void>.broadcast();
  List<BotSkillBinding> bindings;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<BotSkillBinding>> getForBot(String botId) async =>
      List<BotSkillBinding>.unmodifiable(
        bindings.where((binding) => binding.botId == botId),
      );

  @override
  Future<void> remove(String botId, String skillId) async {
    bindings =
        bindings
            .where(
              (binding) => binding.botId != botId || binding.skillId != skillId,
            )
            .toList();
    _changes.add(null);
  }

  @override
  Future<void> save(BotSkillBinding binding) async {
    bindings = [
      ...bindings.where(
        (item) =>
            item.botId != binding.botId || item.skillId != binding.skillId,
      ),
      binding,
    ];
    _changes.add(null);
  }
}
