import 'dart:async';

import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/use_cases/test_skill_description.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

final class BotSkillViewModel extends DisposableChangeNotifier {
  static const int defaultPageSize = 5;

  BotSkillViewModel({
    required this.botId,
    required SkillRepository skillRepository,
    required BotSkillBindingRepository bindingRepository,
    AiProvider? skillToolProvider,
    bool? supportsAutoActivation,
    BundledSkillLoader? bundledSkillLoader,
    TestSkillDescription testSkillDescription = const TestSkillDescription(),
    this.pageSize = defaultPageSize,
  }) : _skillRepository = skillRepository,
       _bindingRepository = bindingRepository,
       _bundledSkillLoader = bundledSkillLoader,
       _skillToolProvider = skillToolProvider,
       _supportsAutoActivation =
           supportsAutoActivation ??
           skillToolProvider?.capabilities.supportsAutomaticSkillActivation ??
           false,
       _testSkillDescription = testSkillDescription,
       assert(pageSize > 0) {
    _skillChanges = _skillRepository.changes.listen((_) => _reload());
    _bindingChanges = _bindingRepository.changes.listen((_) => _reload());
  }

  final String botId;
  final SkillRepository _skillRepository;
  final BotSkillBindingRepository _bindingRepository;
  final BundledSkillLoader? _bundledSkillLoader;
  AiProvider? _skillToolProvider;
  bool _supportsAutoActivation;
  final TestSkillDescription _testSkillDescription;
  final int pageSize;
  late final StreamSubscription<List<SkillDescriptor>> _skillChanges;
  late final StreamSubscription<void> _bindingChanges;

  List<SkillDescriptor> _skills = const [];
  Map<String, BotSkillBinding> _bindings = const {};
  String _availableQuery = '';
  int _addedPageIndex = 0;
  int _availablePageIndex = 0;
  bool _isLoading = false;
  AppFailure? _error;
  int _reloadGeneration = 0;

  List<SkillDescriptor> get skills =>
      _supportsAutoActivation ? _skills : const [];
  List<SkillDescriptor> get addedSkills => List<SkillDescriptor>.unmodifiable(
    skills.where((skill) => _bindings.containsKey(skill.id)),
  );
  List<SkillDescriptor> get availableSkills =>
      List<SkillDescriptor>.unmodifiable(
        skills.where(
          (skill) => skill.isUsable && !_bindings.containsKey(skill.id),
        ),
      );
  List<SkillDescriptor> get filteredAvailableSkills {
    final normalized = _availableQuery.trim().toLowerCase();
    final skills = availableSkills;
    if (normalized.isEmpty) return skills;
    return List<SkillDescriptor>.unmodifiable(
      skills.where(
        (skill) =>
            skill.name.toLowerCase().contains(normalized) ||
            skill.description.toLowerCase().contains(normalized),
      ),
    );
  }

  List<BotSkillBinding> get bindings => List<BotSkillBinding>.unmodifiable(
    skills
        .where((skill) => _bindings.containsKey(skill.id))
        .map((skill) => _bindings[skill.id]!),
  );
  String get availableQuery => _availableQuery;
  List<SkillDescriptor> get paginatedAddedSkills =>
      _paginate(addedSkills, _addedPageIndex);
  List<SkillDescriptor> get paginatedAvailableSkills =>
      _paginate(filteredAvailableSkills, _availablePageIndex);
  int get currentAddedPage => totalAddedPages == 0 ? 0 : _addedPageIndex + 1;
  int get totalAddedPages => _pageCount(addedSkills.length);
  bool get hasPreviousAddedPage => _addedPageIndex > 0;
  bool get hasNextAddedPage => _addedPageIndex + 1 < totalAddedPages;
  int get currentAvailablePage =>
      totalAvailablePages == 0 ? 0 : _availablePageIndex + 1;
  int get totalAvailablePages => _pageCount(filteredAvailableSkills.length);
  bool get hasPreviousAvailablePage => _availablePageIndex > 0;
  bool get hasNextAvailablePage =>
      _availablePageIndex + 1 < totalAvailablePages;
  bool get isLoading => _isLoading;
  AppFailure? get error => _error;
  bool get supportsAutoActivation => _supportsAutoActivation;

  BotSkillBinding? bindingFor(String skillId) => _bindings[skillId];

  Future<void> load() async {
    if (isDisposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _reload();
    if (isDisposed) return;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSkill(String skillId) async {
    if (isDisposed || !supportsAutoActivation) return;
    if (_bindings.containsKey(skillId)) return;
    final now = DateTime.now();
    await _saveBinding(
      BotSkillBinding(
        botId: botId,
        skillId: skillId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> removeSkill(String skillId) async {
    if (isDisposed || !_bindings.containsKey(skillId)) return;
    try {
      await _bindingRepository.remove(botId, skillId);
      if (isDisposed) return;
      _bindings = Map<String, BotSkillBinding>.unmodifiable(
        Map<String, BotSkillBinding>.of(_bindings)..remove(skillId),
      );
      _normalizePages();
      notifyListeners();
    } catch (error) {
      if (isDisposed) return;
      _error = AppFailure.from(error, code: 'bot_skill_load_failed');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setEnabled(String skillId, bool enabled) async {
    if (isDisposed) return;
    final existing = _bindings[skillId];
    if (existing == null) {
      if (enabled) await addSkill(skillId);
      return;
    }
    await _saveBinding(
      existing.copyWith(enabled: enabled, updatedAt: DateTime.now()),
    );
  }

  Future<void> setApprovalExempt(String skillId, bool approvalExempt) async {
    if (isDisposed) return;
    final existing = _bindings[skillId];
    if (existing == null) return;
    await _saveBinding(
      existing.copyWith(
        requiresApproval: !approvalExempt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void updateSupportsAutoActivation(bool supported) {
    if (_supportsAutoActivation == supported) return;
    _supportsAutoActivation = supported;
    _normalizePages();
    notifyListeners();
  }

  void updateSkillToolProvider(AiProvider? provider) {
    _skillToolProvider = provider;
  }

  Future<SkillDescriptionTestReport> testDescription({
    required String skillId,
    required List<SkillDescriptionTestCase> cases,
    int runsPerCase = 3,
  }) async {
    final provider = _skillToolProvider;
    final skill = _skills.where((item) => item.id == skillId).firstOrNull;
    if (provider == null || skill == null) {
      throw StateError('Skill 或 Provider 不可用。');
    }
    return _testSkillDescription(
      provider: provider,
      skill: skill,
      cases: cases,
      runsPerCase: runsPerCase,
    );
  }

  void previousAddedPage() {
    if (!hasPreviousAddedPage) return;
    _addedPageIndex -= 1;
    notifyListeners();
  }

  void nextAddedPage() {
    if (!hasNextAddedPage) return;
    _addedPageIndex += 1;
    notifyListeners();
  }

  void resetAvailablePage() {
    if (_availablePageIndex == 0) return;
    _availablePageIndex = 0;
    notifyListeners();
  }

  void searchAvailableSkills(String query) {
    if (_availableQuery == query) return;
    _availableQuery = query;
    _availablePageIndex = 0;
    notifyListeners();
  }

  void clearAvailableSearch() => searchAvailableSkills('');

  void previousAvailablePage() {
    if (!hasPreviousAvailablePage) return;
    _availablePageIndex -= 1;
    notifyListeners();
  }

  void nextAvailablePage() {
    if (!hasNextAvailablePage) return;
    _availablePageIndex += 1;
    notifyListeners();
  }

  Future<void> _saveBinding(BotSkillBinding binding) async {
    if (isDisposed) return;
    try {
      await _bindingRepository.save(binding);
      if (isDisposed) return;
      _bindings = Map<String, BotSkillBinding>.unmodifiable({
        ..._bindings,
        binding.skillId: binding,
      });
      _normalizePages();
      notifyListeners();
    } catch (error) {
      if (isDisposed) return;
      _error = AppFailure.from(error, code: 'bot_skill_save_failed');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _reload() async {
    if (isDisposed) return;
    final generation = ++_reloadGeneration;
    try {
      final results = await Future.wait<Object>([
        _skillRepository.getInstalled(forceRefresh: true),
        _bindingRepository.getForBot(botId),
        _bundledSkillLoader?.call() ?? Future.value(const <SkillContent>[]),
      ]);
      if (isDisposed || generation != _reloadGeneration) return;
      final installed = results[0] as List<SkillDescriptor>;
      final bindings = results[1] as List<BotSkillBinding>;
      final bundled = results[2] as List<SkillContent>;
      final merged = <String, SkillDescriptor>{
        for (final content in bundled)
          content.descriptor.id: content.descriptor,
      };
      for (final skill in installed) {
        merged.putIfAbsent(skill.id, () => skill);
      }
      _skills = List<SkillDescriptor>.unmodifiable(merged.values);
      _bindings = Map<String, BotSkillBinding>.unmodifiable({
        for (final binding in bindings) binding.skillId: binding,
      });
      _normalizePages();
      _error = null;
      notifyListeners();
    } catch (error) {
      if (isDisposed || generation != _reloadGeneration) return;
      _error = AppFailure.from(error, code: 'bot_skill_test_failed');
      notifyListeners();
    }
  }

  int _pageCount(int itemCount) =>
      itemCount == 0 ? 0 : (itemCount + pageSize - 1) ~/ pageSize;

  List<SkillDescriptor> _paginate(List<SkillDescriptor> source, int pageIndex) {
    if (source.isEmpty) return const [];
    final start = pageIndex * pageSize;
    final proposedEnd = start + pageSize;
    final end = proposedEnd < source.length ? proposedEnd : source.length;
    return List<SkillDescriptor>.unmodifiable(source.getRange(start, end));
  }

  void _normalizePages() {
    final addedPages = totalAddedPages;
    _addedPageIndex =
        addedPages == 0 ? 0 : _addedPageIndex.clamp(0, addedPages - 1);
    final availablePages = totalAvailablePages;
    _availablePageIndex =
        availablePages == 0
            ? 0
            : _availablePageIndex.clamp(0, availablePages - 1);
  }

  @override
  void disposeResources() {
    unawaited(_skillChanges.cancel());
    unawaited(_bindingChanges.cancel());
  }
}

/// Keeps new-Bot Skill choices in memory until the Bot itself is persisted.
final class DraftBotSkillBindingRepository
    implements BotSkillBindingRepository {
  final Map<String, BotSkillBinding> _bindings = {};

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<BotSkillBinding>> getForBot(String botId) async =>
      List<BotSkillBinding>.unmodifiable(
        _bindings.values.where((binding) => binding.botId == botId),
      );

  @override
  Future<void> save(BotSkillBinding binding) async {
    _bindings[binding.skillId] = binding;
  }

  @override
  Future<void> remove(String botId, String skillId) async {
    final binding = _bindings[skillId];
    if (binding?.botId == botId) _bindings.remove(skillId);
  }
}
