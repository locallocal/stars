import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/catalog_controller.dart';
import 'package:stars/domain/repositories/skill_ecosystem_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/use_cases/test_skill_description.dart';

typedef SkillTestBotLoader = Future<List<Bot>> Function();
typedef SkillTestProviderFactory = AiProvider Function(Bot bot);

final class SkillLibraryViewModel extends ChangeNotifier {
  static const int defaultPageSize = 10;

  SkillLibraryViewModel({
    required SkillRepository skillRepository,
    required SkillPickerRepository pickerRepository,
    SkillEcosystemRepository? ecosystemRepository,
    SkillScriptCatalogController? scriptCatalogService,
    SkillCatalogController? catalogService,
    BundledSkillLoader? bundledSkillLoader,
    SkillTestBotLoader? testBotLoader,
    SkillTestProviderFactory? testProviderFactory,
    TestSkillDescription testSkillDescription = const TestSkillDescription(),
    this.pageSize = defaultPageSize,
  }) : _skillRepository = skillRepository,
       _pickerRepository = pickerRepository,
       _ecosystemRepository = ecosystemRepository,
       _scriptCatalogService = scriptCatalogService,
       _catalogService = catalogService,
       _bundledSkillLoader = bundledSkillLoader,
       _testBotLoader = testBotLoader,
       _testProviderFactory = testProviderFactory,
       _testSkillDescription = testSkillDescription,
       assert(
         (testBotLoader == null) == (testProviderFactory == null),
         'Skill testing requires both a Bot loader and Provider factory.',
       ),
       assert(pageSize > 0) {
    _changesSubscription = _skillRepository.changes.listen((skills) {
      if (_disposed) return;
      _applyInstalledSkills(skills);
      unawaited(_refreshEcosystemState());
    });
  }

  final SkillRepository _skillRepository;
  final SkillPickerRepository _pickerRepository;
  final SkillEcosystemRepository? _ecosystemRepository;
  final SkillScriptCatalogController? _scriptCatalogService;
  final SkillCatalogController? _catalogService;
  final BundledSkillLoader? _bundledSkillLoader;
  final SkillTestBotLoader? _testBotLoader;
  final SkillTestProviderFactory? _testProviderFactory;
  final TestSkillDescription _testSkillDescription;
  final int pageSize;
  late final StreamSubscription<List<SkillDescriptor>> _changesSubscription;

  List<SkillDescriptor> _skills = const [];
  List<SkillDescriptor> _installedSkills = const [];
  Map<String, SkillContent> _bundledContents = const {};
  List<SkillDescriptor> _filteredSkills = const [];
  String _query = '';
  int _pageIndex = 0;
  bool _isLoading = false;
  bool _isImporting = false;
  AppFailure? _error;
  SkillDescriptor? _lastImported;
  SkillSandboxStatus? _sandboxStatus;
  Set<String> _scriptToolSkillIds = const {};
  Set<String> _scriptEnabledSkillIds = const {};
  List<OnlineSkillCatalogEntry> _availableUpdates = const [];
  List<SkillCatalogSource> _configuredCatalogs = const [];
  bool _isRefreshingCatalogs = false;
  bool _disposed = false;

  List<SkillDescriptor> get skills => _skills;
  List<SkillDescriptor> get filteredSkills => _filteredSkills;
  List<SkillDescriptor> get paginatedSkills {
    if (_filteredSkills.isEmpty) return const [];
    final start = _pageIndex * pageSize;
    final proposedEnd = start + pageSize;
    final end =
        proposedEnd < _filteredSkills.length
            ? proposedEnd
            : _filteredSkills.length;
    return List<SkillDescriptor>.unmodifiable(
      _filteredSkills.getRange(start, end),
    );
  }

  String get query => _query;
  int get currentPage => totalPages == 0 ? 0 : _pageIndex + 1;
  int get totalPages =>
      _filteredSkills.isEmpty
          ? 0
          : (_filteredSkills.length + pageSize - 1) ~/ pageSize;
  bool get hasPreviousPage => _pageIndex > 0;
  bool get hasNextPage => _pageIndex + 1 < totalPages;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  AppFailure? get error => _error;
  SkillDescriptor? get lastImported => _lastImported;
  SkillSandboxStatus? get sandboxStatus => _sandboxStatus;
  List<OnlineSkillCatalogEntry> get availableUpdates => _availableUpdates;
  bool get isRefreshingCatalogs => _isRefreshingCatalogs;
  bool get hasConfiguredCatalogs => _configuredCatalogs.isNotEmpty;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  bool hasScriptTools(String skillId) => _scriptToolSkillIds.contains(skillId);

  bool isScriptEnabled(String skillId) =>
      _scriptEnabledSkillIds.contains(skillId);

  Future<List<Bot>> loadTestBots() async {
    final loadBots = _testBotLoader;
    final createProvider = _testProviderFactory;
    if (loadBots == null || createProvider == null) return const [];
    final bots = await loadBots();
    return List<Bot>.unmodifiable(
      bots.where((bot) {
        final configured = bot.configuredSupportsAutomaticSkillActivation;
        if (configured != null) return configured;
        try {
          return createProvider(
            bot,
          ).capabilities.supportsAutomaticSkillActivation;
        } on Object {
          return false;
        }
      }),
    );
  }

  Future<SkillDescriptionTestReport> testDescription({
    required Bot bot,
    required SkillDescriptor skill,
    required List<SkillDescriptionTestCase> cases,
    int runsPerCase = 3,
  }) {
    final createProvider = _testProviderFactory;
    if (createProvider == null) {
      throw StateError('Skill test Provider is unavailable.');
    }
    return _testSkillDescription(
      provider: createProvider(bot),
      skill: skill,
      cases: cases,
      runsPerCase: runsPerCase,
    );
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final installed = await _skillRepository.getInstalled(forceRefresh: true);
      final bundled = await _bundledSkillLoader?.call() ?? const [];
      _bundledContents = Map<String, SkillContent>.unmodifiable({
        for (final content in bundled) content.descriptor.id: content,
      });
      _applyInstalledSkills(installed, notify: false);
      await _refreshEcosystemState(notify: false);
    } catch (error) {
      _error = AppFailure.from(error, code: 'skill_library_load_failed');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_disposed) return;
    _error = null;
    try {
      final installed = await _skillRepository.getInstalled(forceRefresh: true);
      if (_disposed) return;
      _applyInstalledSkills(installed, notify: false);
      await _refreshEcosystemState(notify: false);
    } catch (error) {
      if (_disposed) return;
      _error = AppFailure.from(error, code: 'skill_library_load_failed');
    }
    if (!_disposed) notifyListeners();
  }

  void search(String query) {
    if (_query == query) return;
    _query = query;
    _pageIndex = 0;
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() => search('');

  void previousPage() {
    if (!hasPreviousPage) return;
    _pageIndex -= 1;
    notifyListeners();
  }

  void nextPage() {
    if (!hasNextPage) return;
    _pageIndex += 1;
    notifyListeners();
  }

  Future<SkillDescriptor?> importDirectory() async {
    final source = await _pickerRepository.pickDirectory();
    return source == null ? null : _install(source);
  }

  Future<SkillDescriptor?> importZipArchive() async {
    final source = await _pickerRepository.pickZipArchive();
    return source == null ? null : _install(source);
  }

  Future<SkillContent> loadContent(String skillId) async =>
      _bundledContents[skillId] ?? await _skillRepository.load(skillId);

  Future<void> uninstall(String skillId) async {
    if (_bundledContents.containsKey(skillId)) return;
    _error = null;
    notifyListeners();
    try {
      await _skillRepository.uninstall(skillId);
    } catch (error) {
      _error = AppFailure.from(error, code: 'skill_uninstall_failed');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setScriptEnabled(SkillDescriptor skill, bool enabled) async {
    final service = _scriptCatalogService;
    if (service == null) {
      throw const SkillInstallException('当前构建未启用 Skill 脚本生态。');
    }
    _error = null;
    try {
      await service.setEnabled(skill, enabled);
      await _refreshEcosystemState();
    } catch (error) {
      _error = AppFailure.from(error, code: 'skill_delete_failed');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setUpdatePolicy(
    SkillDescriptor skill,
    SkillUpdatePolicy policy,
  ) async {
    if (skill.scope == SkillScope.bundled) return;
    final repository = _ecosystemRepository;
    if (repository == null) return;
    await repository.setSkillUpdatePolicy(skill.id, policy);
    _applyInstalledSkills(
      await _skillRepository.getInstalled(forceRefresh: true),
    );
  }

  Future<void> refreshCatalogs() async {
    final repository = _ecosystemRepository;
    final service = _catalogService;
    if (repository == null || service == null || _isRefreshingCatalogs) return;
    _isRefreshingCatalogs = true;
    _error = null;
    notifyListeners();
    try {
      Object? firstError;
      for (final catalog in await repository.getCatalogs()) {
        if (!catalog.enabled) continue;
        try {
          await service.refresh(catalog);
        } on Object catch (error) {
          firstError ??= error;
        }
      }
      await service.applyAutomaticUpdates();
      _applyInstalledSkills(
        await _skillRepository.getInstalled(forceRefresh: true),
        notify: false,
      );
      _availableUpdates = List<OnlineSkillCatalogEntry>.unmodifiable(
        await service.availableUpdates(),
      );
      if (firstError != null) throw firstError;
    } catch (error) {
      _error = AppFailure.from(error, code: 'skill_operation_failed');
      rethrow;
    } finally {
      _isRefreshingCatalogs = false;
      notifyListeners();
    }
  }

  Future<void> installUpdate(OnlineSkillCatalogEntry entry) async {
    final service = _catalogService;
    if (service == null) return;
    await service.install(entry);
    _applyInstalledSkills(
      await _skillRepository.getInstalled(forceRefresh: true),
      notify: false,
    );
    _availableUpdates = List<OnlineSkillCatalogEntry>.unmodifiable(
      await service.availableUpdates(),
    );
    notifyListeners();
  }

  Future<SkillDescriptor?> _install(SkillImportSource source) async {
    if (_isImporting) return null;
    _isImporting = true;
    _error = null;
    _lastImported = null;
    notifyListeners();
    try {
      final skill = await _skillRepository.install(source);
      _lastImported = skill;
      return skill;
    } catch (error) {
      _error = AppFailure.from(error, code: 'skill_catalog_refresh_failed');
      rethrow;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  void _applySkills(List<SkillDescriptor> skills, {bool notify = true}) {
    _skills = List<SkillDescriptor>.unmodifiable(skills);
    _applyFilter();
    if (notify) notifyListeners();
  }

  void _applyInstalledSkills(
    List<SkillDescriptor> skills, {
    bool notify = true,
  }) {
    _installedSkills = List<SkillDescriptor>.unmodifiable(skills);
    final merged = <String, SkillDescriptor>{
      for (final content in _bundledContents.values)
        content.descriptor.id: content.descriptor,
    };
    for (final skill in _installedSkills) {
      merged.putIfAbsent(skill.id, () => skill);
    }
    _applySkills(merged.values.toList(), notify: notify);
  }

  void _applyFilter() {
    final normalized = _query.trim().toLowerCase();
    _filteredSkills =
        normalized.isEmpty
            ? _skills
            : List<SkillDescriptor>.unmodifiable(
              _skills.where((skill) {
                return skill.id.toLowerCase().contains(normalized) ||
                    skill.name.toLowerCase().contains(normalized) ||
                    skill.description.toLowerCase().contains(normalized) ||
                    skill.sourceUri.toLowerCase().contains(normalized);
              }),
            );
    _normalizePage();
  }

  void _normalizePage() {
    final pageCount = totalPages;
    if (pageCount == 0) {
      _pageIndex = 0;
    } else if (_pageIndex >= pageCount) {
      _pageIndex = pageCount - 1;
    }
  }

  Future<void> _refreshEcosystemState({bool notify = true}) async {
    final scriptService = _scriptCatalogService;
    if (scriptService != null) {
      _sandboxStatus = await scriptService.sandboxStatus();
      final withToolManifest = <String>{};
      final enabled = <String>{};
      for (final skill in _skills) {
        if (!await scriptService.hasToolManifest(skill)) continue;
        withToolManifest.add(skill.id);
        if (await scriptService.isEnabled(skill)) {
          enabled.add(skill.id);
        }
      }
      _scriptToolSkillIds = Set.unmodifiable(withToolManifest);
      _scriptEnabledSkillIds = Set.unmodifiable(enabled);
    }
    final catalog = _catalogService;
    final ecosystem = _ecosystemRepository;
    if (ecosystem != null) {
      _configuredCatalogs = List<SkillCatalogSource>.unmodifiable(
        await ecosystem.getCatalogs(),
      );
    }
    if (catalog != null) {
      _availableUpdates = List<OnlineSkillCatalogEntry>.unmodifiable(
        await catalog.availableUpdates(),
      );
    }
    if (notify && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_changesSubscription.cancel());
    super.dispose();
  }
}
