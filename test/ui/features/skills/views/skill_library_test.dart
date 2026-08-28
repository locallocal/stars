import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/data/services/skills/skill_script_catalog_service.dart';
import 'package:stars/data/services/skills/skill_script_manifest_parser.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/skill_ecosystem_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/repositories/skill_script_sandbox.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/skills/view_models/skill_library_view_model.dart';
import 'package:stars/ui/features/skills/views/skill_library.dart';
import 'package:stars/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop Skill library filters and clears search', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([
        _skill('Release Notes', 'Create polished changelogs'),
        _skill('Code Review', 'Find concise improvements'),
      ]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Release Notes'), findsOneWidget);
      expect(find.text('Code Review'), findsOneWidget);

      final searchField = find.descendant(
        of: find.byKey(const ValueKey<String>('skill-search-field')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'CONCISE');
      await tester.pump();

      expect(find.text('Release Notes'), findsNothing);
      expect(find.text('Code Review'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('clear-skill-search')),
      );
      await tester.pump();

      expect(find.text('Release Notes'), findsOneWidget);
      expect(find.text('Code Review'), findsOneWidget);

      await tester.enterText(searchField, 'missing');
      await tester.pump();

      expect(find.text('未找到匹配的技能'), findsOneWidget);
      expect(find.text('Release Notes'), findsNothing);
      expect(find.text('Code Review'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill library moves between pages', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([
        for (var index = 1; index <= 11; index += 1)
          _skill(
            'Skill ${index.toString().padLeft(2, '0')}',
            'Description $index',
          ),
      ]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Skill 01'), findsOneWidget);
      expect(find.text('Skill 10'), findsOneWidget);
      expect(find.text('Skill 11'), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget);

      final nextPage = find.byKey(const ValueKey<String>('skill-next-page'));
      await tester.ensureVisible(nextPage);
      await tester.tap(nextPage);
      await tester.pump();

      expect(find.text('Skill 01'), findsNothing);
      expect(find.text('Skill 10'), findsNothing);
      expect(find.text('Skill 11'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);

      final previousPage = find.byKey(
        const ValueKey<String>('skill-previous-page'),
      );
      await tester.tap(previousPage);
      await tester.pump();

      expect(find.text('Skill 01'), findsOneWidget);
      expect(find.text('Skill 11'), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill library right-aligns import actions', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final viewModel = SkillLibraryViewModel(
      skillRepository: const _FakeSkillRepository([]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final zipButton = find.byKey(const ValueKey<String>('import-skill-zip'));
      final searchField = find.byKey(
        const ValueKey<String>('skill-search-field'),
      );

      expect(zipButton, findsOneWidget);
      expect(
        tester.getRect(zipButton).right,
        closeTo(tester.getRect(searchField).right, 1),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill library shows the bundled history Skill', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    final bundled = _bundledSkillContent();
    final viewModel = SkillLibraryViewModel(
      skillRepository: const _FakeSkillRepository([]),
      pickerRepository: const _FakeSkillPickerRepository(),
      bundledSkillLoader: () async => [bundled],
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'desktop-skill-card-system:conversation-history',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('conversation-history'), findsOneWidget);
      expect(find.text('内置'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'desktop-skill-menu-button-system:conversation-history',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'desktop-skill-details-system:conversation-history',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'desktop-skill-uninstall-system:conversation-history',
          ),
        ),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill card uses one outline style for every tag', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final skill = _skill(
      'Release Notes',
      'Create polished changelogs',
      version: '',
      hasReferences: true,
      hasAssets: true,
      signatureStatus: SkillSignatureStatus.verified,
      diagnostics: const [
        SkillDiagnostic(
          code: 'warning',
          message: 'Review this Skill',
          severity: SkillDiagnosticSeverity.warning,
        ),
      ],
    );
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([skill]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final tags = tester.widgetList<ShadBadge>(find.byType(ShadBadge));
      expect(tags, hasLength(5));
      expect(
        tags.every((tag) => tag.variant == ShadBadgeVariant.outline),
        isTrue,
      );
      final footer = find.byKey(
        ValueKey<String>('desktop-skill-card-footer-${skill.id}'),
      );
      expect(find.text('用户'), findsOneWidget);
      expect(
        find.descendant(of: footer, matching: find.text('用户')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill cards keep the same height', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final compactSkill = _skill('Compact', 'Short description');
    final detailedSkill = _skill(
      'Detailed',
      'A longer description that spans multiple lines and still keeps the '
          'card aligned with a compact Skill beside it.',
      hasReferences: true,
      hasAssets: true,
      signatureStatus: SkillSignatureStatus.verified,
      diagnostics: const [
        SkillDiagnostic(
          code: 'warning',
          message: 'Review this Skill',
          severity: SkillDiagnosticSeverity.warning,
        ),
      ],
    );
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([compactSkill, detailedSkill]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final compactCard = find.byKey(
        ValueKey<String>('desktop-skill-card-${compactSkill.id}'),
      );
      final detailedCard = find.byKey(
        ValueKey<String>('desktop-skill-card-${detailedSkill.id}'),
      );
      expect(compactCard, findsOneWidget);
      expect(detailedCard, findsOneWidget);
      expect(tester.getSize(compactCard), tester.getSize(detailedCard));
      expect(
        tester.getSize(compactCard).height,
        StarsDesktopThemeSpec.managementCardHeight,
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill card opens Skill details when clicked', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final skill = _skill('Release Notes', 'Create polished changelogs');
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([skill]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final pageTitle = tester.widget<Text>(
        find.byKey(const ValueKey<String>('skill-library-title')),
      );
      final cardTitle = tester.widget<Text>(
        find.byKey(ValueKey<String>('desktop-skill-card-title-${skill.id}')),
      );
      expect(cardTitle.style?.fontSize, pageTitle.style?.fontSize);

      await tester.tap(
        find.byKey(ValueKey<String>('desktop-skill-card-${skill.id}')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      final detailsDialog = find.byKey(
        const ValueKey<String>('skill-details-dialog'),
      );
      final detailsClose = find.byKey(
        const ValueKey<String>('skill-details-close'),
      );
      expect(detailsDialog, findsOneWidget);
      expect(detailsClose, findsOneWidget);
      final detailsDialogSurface =
          find.ancestor(of: detailsClose, matching: find.byType(Stack)).first;
      expect(
        find.descendant(of: detailsClose, matching: find.byIcon(LucideIcons.x)),
        findsOneWidget,
      );
      expect(tester.getSize(detailsClose), const Size.square(44));
      expect(
        tester.getRect(detailsDialogSurface).right -
            tester.getRect(detailsClose).right,
        closeTo(8, 0.01),
      );
      expect(
        tester.getRect(detailsClose).top -
            tester.getRect(detailsDialogSurface).top,
        closeTo(12, 0.01),
      );
      expect(find.text('Instructions for Release Notes'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('skill-storage-location')),
        findsOneWidget,
      );
      expect(find.text(skill.rootPath), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('skill-details-files')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('copy-skill-storage-location')),
      );
      await tester.pump();

      expect(clipboardText, skill.rootPath);
      expect(find.text('安装位置已复制到剪贴板'), findsOneWidget);
      for (final file in const [
        'SKILL.md',
        'assets/template.txt',
        'references/tone.md',
      ]) {
        expect(
          find.byKey(ValueKey<String>('skill-file-$file')),
          findsOneWidget,
        );
        expect(find.text(file), findsOneWidget);
      }
      final detailsTitle = tester.widget<Text>(
        find.byKey(ValueKey<String>('skill-details-title-${skill.id}')),
      );
      expect(detailsTitle.style?.fontSize, pageTitle.style?.fontSize);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('mobile Skill details show copied files and storage location', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    final skill = _skill('Release Notes', 'Create polished changelogs');
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([skill]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final menuButton = find.byKey(
        ValueKey<String>('mobile-skill-menu-button-${skill.id}'),
      );
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      final testAction = find.byKey(
        ValueKey<String>('mobile-skill-test-${skill.id}'),
      );
      expect(testAction, findsOneWidget);
      expect(
        find.byKey(ValueKey<String>('mobile-skill-uninstall-${skill.id}')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      await tester.tap(find.text(skill.name));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('skill-storage-location')),
        findsOneWidget,
      );
      expect(find.text(skill.rootPath), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('skill-details-files')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('copy-skill-storage-location')),
      );
      await tester.pump();

      expect(clipboardText, skill.rootPath);
      expect(find.text('安装位置已复制到剪贴板'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('skill-file-references/tone.md')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill card runs description tests from its menu', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final skill = _skill('Release Notes', 'Create polished changelogs');
    final firstBot = _testBot('bot-1', 'First Agent');
    final selectedBot = _testBot('bot-2', 'Selected Agent');
    final providers = {
      firstBot.id: _DescriptionProvider(firstBot),
      selectedBot.id: _DescriptionProvider(selectedBot),
    };
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([skill]),
      pickerRepository: const _FakeSkillPickerRepository(),
      testBotLoader: () async => [firstBot, selectedBot],
      testProviderFactory: (bot) => providers[bot.id]!,
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(ValueKey<String>('desktop-skill-menu-button-${skill.id}')),
      );
      await tester.pumpAndSettle();

      final testAction = find.byKey(
        ValueKey<String>('desktop-skill-test-${skill.id}'),
      );
      expect(testAction, findsOneWidget);
      await tester.tap(testAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('skill-test-bot-dialog')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(ValueKey<String>('skill-test-bot-${selectedBot.id}')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('skill-description-test-dialog')),
        findsOneWidget,
      );
      final input = find.descendant(
        of: find.byKey(const ValueKey<String>('skill-description-test-input')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(input, 'Write release notes');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('run-skill-description-test')),
      );
      await tester.pumpAndSettle();

      expect(find.text('激活结果: 3/3'), findsOneWidget);
      expect(providers[firstBot.id]!.requests, isEmpty);
      expect(providers[selectedBot.id]!.requests, hasLength(3));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop Skill card operation error can be dismissed', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final skill = _skill('Release Notes', 'Create polished changelogs');
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([skill]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();
      await expectLater(
        viewModel.uninstall(skill.id),
        throwsA(isA<UnsupportedError>()),
      );

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      expect(
        viewModel.error,
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'skill_uninstall_failed',
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('skill-error-alert')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('close-skill-error')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('close-skill-error')));
      await tester.pump();

      expect(viewModel.error, isNull);
      expect(
        find.byKey(const ValueKey<String>('skill-error-alert')),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets(
    'desktop Skill card hides script action without a tools manifest',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;

      final directory = Directory.systemTemp.createTempSync(
        'stars-skill-card-test-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/scripts/helper.sh').createSync(recursive: true);
      final skill = _skill(
        'Release Notes',
        'Create polished changelogs',
        rootPath: directory.path,
        hasScripts: true,
      );
      final repository = _FakeSkillRepository([skill]);
      final scriptService = SkillScriptCatalogService(
        skillRepository: repository,
        ecosystemRepository: const _UnusedSkillEcosystemRepository(),
        manifestParser: const SkillScriptManifestParser(),
        sandbox: const _AvailableSkillSandbox(),
        toolRegistry: DynamicToolRegistry(const []),
      );
      final viewModel = SkillLibraryViewModel(
        skillRepository: repository,
        pickerRepository: const _FakeSkillPickerRepository(),
        scriptCatalogService: scriptService,
      );
      addTearDown(viewModel.dispose);
      try {
        await tester.runAsync(viewModel.load);

        await tester.pumpWidget(_harness(viewModel));
        await tester.pumpAndSettle();

        expect(viewModel.hasScriptTools(skill.id), isFalse);
        await tester.tap(
          find.byKey(ValueKey<String>('desktop-skill-menu-button-${skill.id}')),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(ValueKey<String>('desktop-skill-script-${skill.id}')),
          findsNothing,
        );
        expect(find.text('启用脚本'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets('desktop Skill card actions use the Agent-style menu', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final skill = _skill('Release Notes', 'Create polished changelogs');
    final viewModel = SkillLibraryViewModel(
      skillRepository: _FakeSkillRepository([skill]),
      pickerRepository: const _FakeSkillPickerRepository(),
    );
    addTearDown(viewModel.dispose);
    try {
      await viewModel.load();

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final menuButton = find.byKey(
        ValueKey<String>('desktop-skill-menu-button-${skill.id}'),
      );
      expect(menuButton, findsOneWidget);
      final card = find.byKey(
        ValueKey<String>('desktop-skill-card-${skill.id}'),
      );
      final cardTitle = find.byKey(
        ValueKey<String>('desktop-skill-card-title-${skill.id}'),
      );
      final footer = find.byKey(
        ValueKey<String>('desktop-skill-card-footer-${skill.id}'),
      );
      final footerTags = find.descendant(
        of: footer,
        matching: find.byType(ShadBadge),
      );
      expect(footerTags, findsOneWidget);
      expect(
        tester.getCenter(footerTags).dy,
        closeTo(tester.getCenter(menuButton).dy, 1),
      );
      expect(
        tester.getRect(card).bottom - tester.getRect(menuButton).bottom,
        closeTo(tester.getRect(cardTitle).top - tester.getRect(card).top, 1),
      );
      final menuIconButton = tester.widget<ShadIconButton>(
        find.descendant(of: menuButton, matching: find.byType(ShadIconButton)),
      );
      expect(menuIconButton.decoration?.disableSecondaryBorder, isTrue);
      expect(find.text('技能详情'), findsNothing);
      expect(find.text('卸载技能'), findsNothing);
      expect(
        find.byKey(ValueKey<String>('desktop-skill-details-${skill.id}')),
        findsNothing,
      );

      await tester.tap(menuButton, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsNothing);
      final actionMenu = find.byKey(
        ValueKey<String>('desktop-skill-action-menu-${skill.id}'),
      );
      final detailsAction = find.byKey(
        ValueKey<String>('desktop-skill-details-${skill.id}'),
      );
      expect(actionMenu, findsOneWidget);
      expect(
        find.descendant(of: actionMenu, matching: find.byType(ShadButton)),
        findsNWidgets(3),
      );
      expect(detailsAction, findsOneWidget);
      expect(
        find.byKey(ValueKey<String>('desktop-skill-test-${skill.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey<String>('desktop-skill-uninstall-${skill.id}')),
        findsOneWidget,
      );
      expect(find.text('详情'), findsOneWidget);
      expect(find.text('测试'), findsOneWidget);
      expect(find.text('卸载'), findsOneWidget);
      expect(
        tester.getRect(actionMenu).right,
        closeTo(tester.getRect(menuButton).right, 1),
      );

      await tester.tap(detailsAction, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      expect(actionMenu, findsNothing);
      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.text('Instructions for Release Notes'), findsOneWidget);

      await tester.tap(find.text('关闭'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      expect(actionMenu, findsNothing);
      expect(find.text('显示菜单'), findsNothing);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey<String>('desktop-skill-uninstall-${skill.id}')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.text('确定卸载技能“Release Notes”？相关智能体绑定也会被移除。'), findsOneWidget);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}

Widget _harness(SkillLibraryViewModel viewModel) {
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
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
          home: SkillLibraryPage(viewModel: viewModel),
        ),
  );
}

SkillDescriptor _skill(
  String name,
  String description, {
  String? rootPath,
  String version = '1.0.0',
  bool hasScripts = false,
  bool hasReferences = false,
  bool hasAssets = false,
  SkillSignatureStatus signatureStatus = SkillSignatureStatus.unsigned,
  List<SkillDiagnostic> diagnostics = const [],
}) {
  final timestamp = DateTime(2026, 7, 26);
  return SkillDescriptor(
    id: 'user:$name',
    name: name,
    description: description,
    version: version,
    scope: SkillScope.user,
    sourceUri: 'file:///$name',
    rootPath: rootPath ?? '/skills/$name',
    contentDigest: 'digest-$name',
    trustState: SkillTrustState.userReviewed,
    validationStatus: SkillValidationStatus.valid,
    compatibility: '',
    diagnostics: diagnostics,
    hasScripts: hasScripts,
    hasReferences: hasReferences,
    hasAssets: hasAssets,
    signatureStatus: signatureStatus,
    installedAt: timestamp,
    updatedAt: timestamp,
  );
}

SkillContent _bundledSkillContent() {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: 'system:conversation-history',
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
    ),
    instructions: 'Query conversation history when exact context is needed.',
    files: const ['SKILL.md'],
  );
}

Bot _testBot(String id, String name) => Bot(
  id: id,
  name: name,
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

final class _DescriptionProvider extends AiProvider {
  _DescriptionProvider(super.bot);

  final requests = <SkillToolSessionRequest>[];

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) {
    requests.add(request);
    return _DescriptionSession(skillName: request.catalog.single.name);
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _DescriptionSession implements SkillToolSession {
  const _DescriptionSession({required this.skillName});

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
    isComplete: false,
  );

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) async =>
      SkillToolTurn(isComplete: true);

  @override
  void close() {}
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
  Future<SkillContent> load(String skillId, {String? contentDigest}) async {
    final skill = skills.firstWhere((skill) => skill.id == skillId);
    return SkillContent(
      descriptor: skill,
      instructions: 'Instructions for ${skill.name}',
      files: const ['SKILL.md', 'assets/template.txt', 'references/tone.md'],
    );
  }

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

final class _FakeSkillPickerRepository implements SkillPickerRepository {
  const _FakeSkillPickerRepository();

  @override
  Future<SkillImportSource?> pickDirectory() async => null;

  @override
  Future<SkillImportSource?> pickZipArchive() async => null;
}

final class _AvailableSkillSandbox implements SkillScriptSandbox {
  const _AvailableSkillSandbox();

  @override
  Future<SkillSandboxStatus> probe() async => const SkillSandboxStatus(
    availability: SkillSandboxAvailability.available,
  );

  @override
  Future<SkillScriptExecutionResult> execute(
    SkillScriptExecutionRequest request,
    AgentCancellationToken cancellationToken,
  ) => throw UnsupportedError('Script execution is not used in this test.');
}

final class _UnusedSkillEcosystemRepository
    implements SkillEcosystemRepository {
  const _UnusedSkillEcosystemRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
