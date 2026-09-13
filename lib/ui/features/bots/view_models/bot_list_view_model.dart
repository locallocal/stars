import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/bot_transfer_repository.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/create_chat.dart';
import 'package:stars/domain/use_cases/bot_commands.dart';

@immutable
class BotCardMetrics {
  const BotCardMetrics({
    this.tokenUsage = ModelTokenUsage.empty,
    this.mcpServerNames = const [],
    this.skillCount = 0,
    this.contextWindowTokens,
    this.inputModalities = const [InputModality.text],
    this.outputModalities = const [OutputModality.text],
  });

  static const empty = BotCardMetrics();

  final ModelTokenUsage tokenUsage;
  final List<String> mcpServerNames;
  final int skillCount;
  final int? contextWindowTokens;
  final List<InputModality> inputModalities;
  final List<OutputModality> outputModalities;
}

class BotListViewModel extends ChangeNotifier {
  static final RegExp _searchWhitespace = RegExp(r'\s+');
  static final RegExp _searchSeparators = RegExp(r'[\s\-_.:/]+');
  static final RegExp _unsafeFileNameCharacters = RegExp(
    r'[<>:"/\\|?*\x00-\x1F]',
  );

  BotListViewModel({
    required BotRepository botRepository,
    required CreateChat createChat,
    required AiProviderRepository aiProviderRepository,
    required AttachmentRepository attachmentRepository,
    BotSkillBindingRepository? botSkillBindingRepository,
    MessageRepository? messageRepository,
    McpServerRepository? mcpServerRepository,
    CreateBot? createBot,
    UpdateBot? updateBot,
    DeleteBot? deleteBot,
    BotTransferRepository? botTransferRepository,
    DateTime Function()? clock,
  }) : _botRepository = botRepository,
       _createChat = createChat,
       _aiProviderRepository = aiProviderRepository,
       _attachmentRepository = attachmentRepository,
       _botSkillBindingRepository = botSkillBindingRepository,
       _messageRepository = messageRepository,
       _mcpServerRepository = mcpServerRepository,
       _botTransferRepository = botTransferRepository,
       _clock = clock ?? DateTime.now {
    _createBot =
        createBot ??
        CreateBot(
          repository: botRepository,
          bindingRepository: botSkillBindingRepository,
        );
    _updateBot = updateBot ?? UpdateBot(repository: botRepository);
    _deleteBot = deleteBot ?? DeleteBot(repository: botRepository);
    _botSubscription = _botRepository.changes.listen(_handleBotsChanged);
    if (messageRepository is BotScopedMessageMetricsRepository) {
      _messageMetricSubscription = messageRepository.botMetricChanges.listen(
        _scheduleMetricsLoad,
      );
    } else {
      _messageSubscription = messageRepository?.changes.listen(
        (_) => _scheduleMetricsLoad(),
      );
    }
    if (botSkillBindingRepository is BotScopedSkillBindingMetricsRepository) {
      _bindingMetricSubscription = botSkillBindingRepository.botMetricChanges
          .listen(_scheduleMetricsLoad);
    } else {
      _bindingSubscription = botSkillBindingRepository?.changes.listen(
        (_) => _scheduleMetricsLoad(),
      );
    }
    _mcpSubscription = mcpServerRepository?.changes.listen((servers) {
      final previous = {
        for (final server in _mcpServers ?? const []) server.id: server,
      };
      final next = {for (final server in servers) server.id: server};
      final changedServerIds =
          {
            ...previous.keys,
            ...next.keys,
          }.where((id) => previous[id]?.name != next[id]?.name).toSet();
      _mcpServers = List<McpServer>.unmodifiable(servers);
      _scheduleMetricsLoad({
        for (final bot in _bots)
          if (bot.mcpServerIds.any(changedServerIds.contains)) bot.id,
      });
    });
  }

  final BotRepository _botRepository;
  final CreateChat _createChat;
  final AiProviderRepository _aiProviderRepository;
  final AttachmentRepository _attachmentRepository;
  final BotSkillBindingRepository? _botSkillBindingRepository;
  final MessageRepository? _messageRepository;
  final McpServerRepository? _mcpServerRepository;
  final BotTransferRepository? _botTransferRepository;
  final DateTime Function() _clock;
  late final CreateBot _createBot;
  late final UpdateBot _updateBot;
  late final DeleteBot _deleteBot;
  late final StreamSubscription<List<Bot>> _botSubscription;
  StreamSubscription<void>? _messageSubscription;
  StreamSubscription<void>? _bindingSubscription;
  StreamSubscription<Set<String>>? _messageMetricSubscription;
  StreamSubscription<Set<String>>? _bindingMetricSubscription;
  late final StreamSubscription<List<McpServer>>? _mcpSubscription;

  List<Bot> _bots = const [];
  List<Bot> _filteredBots = const [];
  List<McpServer>? _mcpServers;
  Map<String, BotCardMetrics> _cardMetrics = const {};
  String _query = '';
  AppFailure? _error;
  CommandState _commandState = const CommandState.idle();
  bool _isLoading = false;
  bool _metricsLoadScheduled = false;
  bool _reloadAllMetrics = false;
  final Set<String> _pendingMetricBotIds = <String>{};
  bool _disposed = false;
  int _loadGeneration = 0;
  int _metricsLoadGeneration = 0;

  List<Bot> get bots => _bots;
  List<Bot> get filteredBots => _filteredBots;
  String get query => _query;
  AppFailure? get error => _error;
  CommandState get commandState => _commandState;
  bool get isLoading => _isLoading;
  BotCardMetrics metricsFor(String botId) =>
      _cardMetrics[botId] ?? BotCardMetrics.empty;

  void clearError() {
    if (_error == null && _commandState.phase != CommandPhase.failed) return;
    _error = null;
    _commandState = const CommandState.idle();
    notifyListeners();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final bots = await _botRepository.getBots();
      if (_disposed || generation != _loadGeneration) return;
      _applyBots(bots, notify: false);
      await _loadCardMetrics(bots, notify: false);
    } catch (error) {
      if (_disposed || generation != _loadGeneration) return;
      _error = AppFailure.from(error, code: 'bot_list_load_failed');
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void search(String query) {
    _query = query;
    _applyFilter();
    notifyListeners();
  }

  Future<Chat> startChat(Bot bot) => _createChat(bot);

  Future<List<AiModelInfo>> listModels(Bot bot) =>
      _aiProviderRepository.listModels(bot);

  Future<AiModelInfo?> getModelInfo(Bot bot) =>
      _aiProviderRepository.getModelInfo(bot);

  Future<String?> pickAvatar() => _attachmentRepository.selectImage();

  Future<void> addBot(
    Bot bot, {
    List<BotSkillBinding> skillBindings = const [],
  }) async {
    await _runMutation(
      'bot_create_failed',
      () => _createBot(bot, skillBindings: skillBindings),
    );
  }

  Future<void> updateBot(Bot bot) =>
      _runMutation('bot_update_failed', () => _updateBot(bot));

  Future<void> deleteBot(String id) =>
      _runMutation('bot_delete_failed', () => _deleteBot(id));

  Future<BotExportResult> exportBot(Bot bot, {required String dialogTitle}) =>
      _runMutation('bot_export_failed', () {
        final repository = _requireTransferRepository();
        return repository.exportBot(
          BotExportDocument.fromBot(bot),
          suggestedFileName: _suggestedExportFileName(bot.name),
          dialogTitle: dialogTitle,
        );
      });

  Future<Bot?> importBot({required String dialogTitle}) =>
      _runMutation('bot_import_failed', () async {
        final document = await _requireTransferRepository().importBot(
          dialogTitle: dialogTitle,
        );
        if (document == null) return null;
        final timestamp = _clock();
        final bot = document.toImportedBot(
          id: 'bot_${timestamp.microsecondsSinceEpoch}',
          timestamp: timestamp,
        );
        await _createBot(bot);
        return bot;
      });

  BotTransferRepository _requireTransferRepository() {
    final repository = _botTransferRepository;
    if (repository == null) {
      throw StateError('Bot transfer is not configured.');
    }
    return repository;
  }

  String _suggestedExportFileName(String botName) {
    final safeName =
        botName
            .replaceAll(_unsafeFileNameCharacters, '-')
            .replaceAll(_searchWhitespace, ' ')
            .trim();
    final baseName = safeName.isEmpty ? 'bot' : safeName;
    final shortened =
        baseName.length > 80 ? baseName.substring(0, 80) : baseName;
    return '$shortened.stars-bot.json';
  }

  Future<T> _runMutation<T>(
    String failureCode,
    Future<T> Function() operation,
  ) async {
    _error = null;
    _commandState = const CommandState.submitting();
    notifyListeners();
    try {
      final result = await operation();
      _commandState = const CommandState.succeeded();
      return result;
    } on Object catch (error) {
      final failure = AppFailure.from(error, code: failureCode);
      _commandState = CommandState.failed(failure);
      _error = failure;
      rethrow;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  void _handleBotsChanged(List<Bot> bots) {
    if (_disposed) return;
    final previous = {for (final bot in _bots) bot.id: bot};
    final next = {for (final bot in bots) bot.id: bot};
    final changedIds =
        {
          ...previous.keys,
          ...next.keys,
        }.where((id) => previous[id] != next[id]).toSet();
    _applyBots(bots);
    _scheduleMetricsLoad(changedIds);
  }

  void _applyBots(List<Bot> bots, {bool notify = true}) {
    _bots = List<Bot>.unmodifiable(bots);
    _applyFilter();
    if (notify) notifyListeners();
  }

  void _applyFilter() {
    final terms = _query
        .trim()
        .toLowerCase()
        .split(_searchWhitespace)
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    _filteredBots =
        terms.isEmpty
            ? _bots
            : List<Bot>.unmodifiable(
              _bots.where((bot) => _matchesSearch(bot, terms)),
            );
  }

  bool _matchesSearch(Bot bot, List<String> terms) {
    final fields = [bot.name, bot.provider, bot.model]
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final compactFields = fields
        .map((value) => value.replaceAll(_searchSeparators, ''))
        .toList(growable: false);
    return terms.every((term) {
      if (fields.any((field) => field.contains(term))) return true;
      final compactTerm = term.replaceAll(_searchSeparators, '');
      return compactTerm.isNotEmpty &&
          compactFields.any((field) => field.contains(compactTerm));
    });
  }

  Future<void> _loadCardMetrics(
    List<Bot> bots, {
    Set<String>? affectedBotIds,
    bool notify = true,
  }) async {
    final generation = ++_metricsLoadGeneration;
    final requestedIds = affectedBotIds ?? {for (final bot in bots) bot.id};
    final selectedBots = [
      for (final bot in bots)
        if (requestedIds.contains(bot.id)) bot,
    ];
    var mcpServers = _mcpServers;
    final mcpRepository = _mcpServerRepository;
    if (mcpServers == null && mcpRepository != null) {
      mcpServers = List<McpServer>.unmodifiable(
        await mcpRepository.getServers(),
      );
      _mcpServers = mcpServers;
    }
    final serversById = {
      for (final server in mcpServers ?? const <McpServer>[]) server.id: server,
    };
    final selectedIds = selectedBots.map((bot) => bot.id).toSet();
    final messageRepository = _messageRepository;
    final usageByBot =
        messageRepository is BotScopedMessageMetricsRepository
            ? await messageRepository.getTokenUsageForBots(selectedIds)
            : Map<String, ModelTokenUsage>.fromEntries(
              await Future.wait(
                selectedBots.map(
                  (bot) async => MapEntry(
                    bot.id,
                    await (messageRepository?.getTokenUsageForBot(bot.id) ??
                        Future.value(ModelTokenUsage.empty)),
                  ),
                ),
              ),
            );
    final bindingRepository = _botSkillBindingRepository;
    final bindingCounts =
        bindingRepository is BotScopedSkillBindingMetricsRepository
            ? await bindingRepository.getBindingCountsForBots(selectedIds)
            : Map<String, int>.fromEntries(
              await Future.wait(
                selectedBots.map(
                  (bot) async => MapEntry(
                    bot.id,
                    (await (bindingRepository?.getForBot(bot.id) ??
                            Future.value(const <BotSkillBinding>[])))
                        .length,
                  ),
                ),
              ),
            );
    final entries = <(String, BotCardMetrics)>[
      for (final bot in selectedBots)
        _buildBotCardMetrics(
          bot,
          serversById,
          usageByBot[bot.id] ?? ModelTokenUsage.empty,
          bindingCounts[bot.id] ?? 0,
        ),
    ];
    if (_disposed || generation != _metricsLoadGeneration) return;
    final activeIds = bots.map((bot) => bot.id).toSet();
    _cardMetrics = Map<String, BotCardMetrics>.unmodifiable({
      for (final entry in _cardMetrics.entries)
        if (activeIds.contains(entry.key) && !selectedIds.contains(entry.key))
          entry.key: entry.value,
      for (final entry in entries) entry.$1: entry.$2,
    });
    if (notify) notifyListeners();
  }

  (String, BotCardMetrics) _buildBotCardMetrics(
    Bot bot,
    Map<String, McpServer> serversById,
    ModelTokenUsage usage,
    int bindingCount,
  ) {
    final contextWindowTokens = bot.configuredContextWindowTokens;
    final providerModalities = _providerModalities(bot);
    final inputModalities = _resolveInputModalities(
      bot.configuredInputModalities,
      null,
      providerModalities.$1,
    );
    final outputModalities = _resolveOutputModalities(
      bot.configuredOutputModalities,
      null,
      providerModalities.$2,
    );
    final serverNames =
        bot.mcpServerIds
            .map((id) => serversById[id]?.name.trim())
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort(
            (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
          );
    return (
      bot.id,
      BotCardMetrics(
        tokenUsage: usage,
        mcpServerNames: List<String>.unmodifiable(serverNames),
        skillCount: bindingCount,
        contextWindowTokens: contextWindowTokens,
        inputModalities: inputModalities,
        outputModalities: outputModalities,
      ),
    );
  }

  (List<InputModality>, List<OutputModality>) _providerModalities(Bot bot) {
    try {
      final provider = _aiProviderRepository.create(bot);
      return (provider.getInputModalites(), provider.getOutputModalites());
    } on Object {
      return const ([InputModality.text], [OutputModality.text]);
    }
  }

  List<InputModality> _resolveInputModalities(
    List<InputModality>? configured,
    List<InputModality>? fetched,
    List<InputModality> fallback,
  ) => List<InputModality>.unmodifiable(
    configured?.isNotEmpty == true
        ? configured!
        : fetched?.isNotEmpty == true
        ? fetched!
        : fallback.isNotEmpty
        ? fallback
        : const [InputModality.text],
  );

  List<OutputModality> _resolveOutputModalities(
    List<OutputModality>? configured,
    List<OutputModality>? fetched,
    List<OutputModality> fallback,
  ) => List<OutputModality>.unmodifiable(
    configured?.isNotEmpty == true
        ? configured!
        : fetched?.isNotEmpty == true
        ? fetched!
        : fallback.isNotEmpty
        ? fallback
        : const [OutputModality.text],
  );

  void _scheduleMetricsLoad([Set<String>? botIds]) {
    if (_disposed) return;
    if (botIds == null) {
      _reloadAllMetrics = true;
      _pendingMetricBotIds.clear();
    } else if (!_reloadAllMetrics) {
      _pendingMetricBotIds.addAll(botIds);
    }
    if (_metricsLoadScheduled) return;
    _metricsLoadScheduled = true;
    scheduleMicrotask(() async {
      _metricsLoadScheduled = false;
      if (_disposed) return;
      final affected =
          _reloadAllMetrics ? null : Set<String>.of(_pendingMetricBotIds);
      _reloadAllMetrics = false;
      _pendingMetricBotIds.clear();
      if (affected?.isEmpty == true) return;
      try {
        await _loadCardMetrics(_bots, affectedBotIds: affected);
      } catch (error) {
        if (_disposed) return;
        _error = AppFailure.from(error, code: 'bot_metrics_load_failed');
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _botSubscription.cancel();
    _messageSubscription?.cancel();
    _bindingSubscription?.cancel();
    _messageMetricSubscription?.cancel();
    _bindingMetricSubscription?.cancel();
    _mcpSubscription?.cancel();
    super.dispose();
  }
}
