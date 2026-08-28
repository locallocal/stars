import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/bots/view_models/bot_skill_view_model.dart';
import 'package:stars/ui/features/bots/views/edit_bot.dart';
import 'package:stars/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'bot detail paginates, toggles, removes, and adds Skills on demand',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;

      final skills = [
        for (var index = 1; index <= 13; index += 1)
          _skill('Skill ${index.toString().padLeft(2, '0')}'),
      ];
      final timestamp = DateTime(2026, 7, 26);
      final bindingRepository = _FakeBindingRepository([
        for (var index = 1; index <= 6; index += 1)
          BotSkillBinding(
            botId: 'bot-1',
            skillId: 'user:Skill ${index.toString().padLeft(2, '0')}',
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
      ]);
      final viewModel = BotSkillViewModel(
        botId: 'bot-1',
        skillRepository: _FakeSkillRepository(skills),
        bindingRepository: bindingRepository,
        supportsAutoActivation: true,
        pageSize: 5,
      );
      addTearDown(bindingRepository.dispose);
      addTearDown(viewModel.dispose);

      try {
        await tester.pumpWidget(_harness(viewModel));
        await tester.pumpAndSettle();

        expect(find.text('Skill 01'), findsOneWidget);
        expect(find.text('Skill 05'), findsOneWidget);
        expect(find.text('Skill 06'), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('bot-skills-page-indicator')),
          findsOneWidget,
        );
        expect(find.text('1 / 2'), findsOneWidget);

        final nextAddedPage = find.byKey(
          const ValueKey<String>('bot-skills-next-page'),
        );
        await tester.ensureVisible(nextAddedPage);
        await tester.tap(nextAddedPage);
        await tester.pump();

        expect(find.text('Skill 01'), findsNothing);
        expect(find.text('Skill 06'), findsOneWidget);
        expect(find.text('2 / 2'), findsOneWidget);

        final skillToggle = find.byKey(
          const ValueKey<String>('bot-skill-toggle-user:Skill 06'),
        );
        await tester.ensureVisible(skillToggle);
        final toggleRect = tester.getRect(skillToggle);
        await tester.tapAt(Offset(toggleRect.left + 16, toggleRect.center.dy));
        await tester.pumpAndSettle();

        expect(bindingRepository.bindingFor('user:Skill 06')?.enabled, isFalse);
        expect(find.text('已开启'), findsNothing);
        expect(find.text('已关闭'), findsNothing);
        expect(find.text('Skill 06'), findsOneWidget);

        final removeSkill = find.byKey(
          const ValueKey<String>('remove-bot-skill-user:Skill 06'),
        );
        await tester.ensureVisible(removeSkill);
        await tester.tap(removeSkill);
        await tester.pumpAndSettle();

        expect(bindingRepository.bindingFor('user:Skill 06'), isNull);
        expect(find.text('Skill 06'), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('bot-skills-page-indicator')),
          findsNothing,
        );

        final addSkill = find.byKey(const ValueKey<String>('add-bot-skill'));
        await tester.ensureVisible(addSkill);
        await tester.tap(addSkill);
        await tester.pumpAndSettle();

        final addSkillClose = find.byKey(
          const ValueKey<String>('bot-add-skill-close'),
        );
        final addSkillDialog = find.byKey(
          const ValueKey<String>('bot-add-skill-dialog'),
        );
        expect(addSkillClose, findsOneWidget);
        expect(addSkillDialog, findsOneWidget);
        final addSkillDialogSurface =
            find
                .ancestor(of: addSkillClose, matching: find.byType(Stack))
                .first;
        expect(tester.getSize(addSkillClose), const Size.square(44));
        expect(
          find.descendant(
            of: addSkillClose,
            matching: find.byIcon(LucideIcons.x),
          ),
          findsOneWidget,
        );
        expect(
          tester.getRect(addSkillDialogSurface).right -
              tester.getRect(addSkillClose).right,
          closeTo(8, 0.01),
        );
        expect(
          tester.getRect(addSkillClose).top -
              tester.getRect(addSkillDialogSurface).top,
          closeTo(12, 0.01),
        );

        final searchField = find.byKey(
          const ValueKey<String>('bot-skill-search-field'),
        );
        expect(searchField, findsOneWidget);
        await tester.enterText(
          find.descendant(of: searchField, matching: find.byType(EditableText)),
          'Skill 13',
        );
        await tester.pump();

        expect(find.text('Skill 06'), findsNothing);
        expect(
          find.byKey(
            const ValueKey<String>('available-bot-skill-user:Skill 13'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('available-skills-page-indicator')),
          findsNothing,
        );

        await tester.enterText(
          find.descendant(of: searchField, matching: find.byType(EditableText)),
          'missing',
        );
        await tester.pump();
        expect(find.text('未找到匹配的技能'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey<String>('available-bot-skill-user:Skill 13'),
          ),
          findsNothing,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('clear-bot-skill-search')),
        );
        await tester.pump();
        expect(find.text('Skill 06'), findsOneWidget);
        expect(find.text('Skill 10'), findsOneWidget);
        expect(find.text('Skill 13'), findsNothing);

        await tester.tap(
          find.byKey(const ValueKey<String>('available-skills-next-page')),
        );
        await tester.pump();

        expect(find.text('Skill 06'), findsNothing);
        expect(find.text('Skill 11'), findsOneWidget);
        expect(find.text('Skill 13'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('add-bot-skill-user:Skill 13')),
        );
        await tester.pumpAndSettle();

        expect(bindingRepository.bindingFor('user:Skill 13')?.enabled, isTrue);
        expect(find.byType(ShadDialog), findsNothing);

        final restoredNextPage = find.byKey(
          const ValueKey<String>('bot-skills-next-page'),
        );
        await tester.ensureVisible(restoredNextPage);
        await tester.tap(restoredNextPage);
        await tester.pump();

        expect(find.text('Skill 13'), findsOneWidget);
        expect(find.text('Skill 01'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets('capable provider exposes automatic Skills only', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    final timestamp = DateTime(2026, 7, 26);
    final bindingRepository = _FakeBindingRepository([
      BotSkillBinding(
        botId: 'bot-1',
        skillId: 'user:release-notes',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ]);
    final provider = _AutoProvider();
    final viewModel = BotSkillViewModel(
      botId: 'bot-1',
      skillRepository: _FakeSkillRepository([_skill('release-notes')]),
      bindingRepository: bindingRepository,
      skillToolProvider: provider,
    );
    addTearDown(bindingRepository.dispose);
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final skillRow = find.byKey(
        const ValueKey<String>('bot-skill-user:release-notes'),
      );
      expect(
        find.descendant(of: skillRow, matching: find.text('自动激活')),
        findsNothing,
      );
      expect(find.text('已开启'), findsNothing);
      expect(find.text('已关闭'), findsNothing);
      expect(find.bySemanticsLabel('自动激活'), findsOneWidget);
      expect(find.text('按消息启用'), findsNothing);
      expect(find.text('始终启用'), findsNothing);
      expect(
        find.descendant(of: skillRow, matching: find.text('测试')),
        findsOneWidget,
      );

      expect(
        bindingRepository.bindingFor('user:release-notes')?.activationMode,
        SkillActivationMode.auto,
      );

      final testDescription = find.byKey(
        const ValueKey<String>('test-skill-description-user:release-notes'),
      );
      final skillToggle = find.byKey(
        const ValueKey<String>('bot-skill-toggle-user:release-notes'),
      );
      expect(
        tester.getRect(testDescription).right,
        lessThan(tester.getRect(skillToggle).left),
      );
      await tester.ensureVisible(testDescription);
      await tester.tap(testDescription);
      await tester.pumpAndSettle();

      final skillDescriptionDialog = find.byKey(
        const ValueKey<String>('skill-description-test-dialog'),
      );
      expect(skillDescriptionDialog, findsOneWidget);
      expect(find.text('测试技能描述'), findsOneWidget);
      expect(
        find.descendant(
          of: skillDescriptionDialog,
          matching: find.byType(ShadTextarea),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('skill-description-test-input'),
          ),
          matching: find.byType(EditableText),
        ),
        'Create release notes',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('run-skill-description-test')),
      );
      await tester.pumpAndSettle();

      expect(skillDescriptionDialog, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('skill-description-test-result')),
        findsOneWidget,
      );
      expect(find.text('3 / 3'), findsOneWidget);
      expect(provider.startedSessions, 3);

      await tester.tap(
        find.byKey(const ValueKey<String>('cancel-skill-description-test')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('read-only bot details hide Skill mutation actions', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    final timestamp = DateTime(2026, 7, 26);
    final bindingRepository = _FakeBindingRepository([
      BotSkillBinding(
        botId: 'bot-1',
        skillId: 'user:release-notes',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ]);
    final viewModel = BotSkillViewModel(
      botId: 'bot-1',
      skillRepository: _FakeSkillRepository([
        _skill('release-notes'),
        _skill('another-skill'),
      ]),
      bindingRepository: bindingRepository,
      supportsAutoActivation: true,
    );
    addTearDown(bindingRepository.dispose);
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel, readOnly: true));
      await tester.pumpAndSettle();

      final skillToggle = find.byKey(
        const ValueKey<String>('bot-skill-toggle-user:release-notes'),
      );
      await tester.ensureVisible(skillToggle);

      expect(find.byKey(const ValueKey<String>('add-bot-skill')), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('remove-bot-skill-user:release-notes'),
        ),
        findsNothing,
      );
      expect(tester.widget<ShadSwitch>(skillToggle).enabled, isFalse);
      expect(find.text('已开启'), findsNothing);
      expect(find.text('已关闭'), findsNothing);
      expect(find.bySemanticsLabel('自动激活'), findsOneWidget);

      await tester.tap(skillToggle, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(bindingRepository.bindingFor('user:release-notes'), isNotNull);
      expect(find.byType(ShadDialog), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('unsupported provider hides the Skill section', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    final bindingRepository = _FakeBindingRepository(const []);
    final viewModel = BotSkillViewModel(
      botId: 'bot-1',
      skillRepository: _FakeSkillRepository([_skill('release-notes')]),
      bindingRepository: bindingRepository,
      supportsAutoActivation: false,
    );
    addTearDown(bindingRepository.dispose);
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('desktop-bot-skills-section')),
        findsNothing,
      );
      expect(find.text('release-notes'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}

Widget _harness(BotSkillViewModel viewModel, {bool readOnly = false}) {
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
  );
  final timestamp = DateTime(2026, 7, 26);
  final bot = Bot(
    id: 'bot-1',
    name: 'Researcher',
    avatar: '',
    provider: 'OpenAI',
    baseURL: '',
    apiKey: '',
    apiType: Bot.apiTypeOpenAI,
    model: 'gpt-test',
    systemPrompt: '',
    createTimestamp: timestamp,
    modifyTimestamp: timestamp,
  );
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: shadTheme,
    appBuilder:
        (shadContext) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(
            context: shadContext,
            fontSize: 16,
          ),
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: EditBotPage(
            bot: bot,
            embedded: true,
            readOnly: readOnly,
            skillViewModel: viewModel,
            onBotUpdated: (_) async {},
            onBotDeleted: () async {},
          ),
        ),
  );
}

SkillDescriptor _skill(String name) {
  final timestamp = DateTime(2026, 7, 26);
  return SkillDescriptor(
    id: 'user:$name',
    name: name,
    description: '$name description',
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

final class _FakeSkillRepository implements SkillRepository {
  const _FakeSkillRepository(this.skills);

  final List<SkillDescriptor> skills;

  @override
  Stream<List<SkillDescriptor>> get changes => const Stream.empty();

  @override
  Future<List<SkillDescriptor>> getInstalled({
    bool forceRefresh = false,
  }) async => List<SkillDescriptor>.unmodifiable(skills);

  @override
  Future<SkillDescriptor?> getById(String id) async =>
      skills.where((skill) => skill.id == id).firstOrNull;

  @override
  Future<SkillDescriptor> install(SkillImportSource source) =>
      throw UnsupportedError('Import is not used in this test.');

  @override
  Future<SkillContent> load(String skillId, {String? contentDigest}) =>
      throw UnsupportedError('Loading is not used in this test.');

  @override
  Future<SkillResourceContent> readResource(
    String skillId,
    String relativePath, {
    String? contentDigest,
  }) => throw UnsupportedError('Resource reading is not used in this test.');

  @override
  Future<void> uninstall(String skillId) =>
      throw UnsupportedError('Uninstall is not used in this test.');
}

final class _FakeBindingRepository implements BotSkillBindingRepository {
  _FakeBindingRepository(List<BotSkillBinding> bindings)
    : _bindings = List<BotSkillBinding>.of(bindings);

  final StreamController<void> _changes = StreamController<void>.broadcast();
  List<BotSkillBinding> _bindings;

  @override
  Stream<void> get changes => _changes.stream;

  BotSkillBinding? bindingFor(String skillId) =>
      _bindings.where((binding) => binding.skillId == skillId).firstOrNull;

  @override
  Future<List<BotSkillBinding>> getForBot(String botId) async =>
      List<BotSkillBinding>.unmodifiable(
        _bindings.where((binding) => binding.botId == botId),
      );

  @override
  Future<void> remove(String botId, String skillId) async {
    _bindings =
        _bindings
            .where(
              (binding) => binding.botId != botId || binding.skillId != skillId,
            )
            .toList();
    _changes.add(null);
  }

  @override
  Future<void> save(BotSkillBinding binding) async {
    _bindings = [
      ..._bindings.where(
        (item) =>
            item.botId != binding.botId || item.skillId != binding.skillId,
      ),
      binding,
    ];
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
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

  var startedSessions = 0;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) {
    startedSessions += 1;
    return _AutoSkillSession(skillName: request.catalog.single.name);
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _AutoSkillSession implements SkillToolSession {
  const _AutoSkillSession({required this.skillName});

  final String skillName;

  @override
  Future<SkillToolTurn> start() async => SkillToolTurn(
    calls: [
      SkillToolCall(
        callId: 'call',
        name: 'activate_skill',
        arguments: {'name': skillName},
      ),
    ],
  );

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) async =>
      SkillToolTurn(isComplete: true);

  @override
  void close() {}
}
