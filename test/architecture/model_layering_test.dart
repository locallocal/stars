import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy model entry point is fully migrated', () {
    expect(File('lib/model/model.dart').existsSync(), isFalse);

    final domainBarrel =
        File('lib/domain/models/models.dart').readAsStringSync();
    expect(domainBarrel, isNot(contains("export '../../model/")));
  });

  test('domain models do not depend on Flutter, data, or UI layers', () {
    final modelFiles = Directory('lib/domain/models')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in modelFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('package:flutter/')),
        reason: '${file.path} imports Flutter',
      );
      expect(
        source,
        isNot(contains('package:stars/data/')),
        reason: '${file.path} imports the data layer',
      );
      expect(
        source,
        isNot(contains('package:stars/ui/')),
        reason: '${file.path} imports the UI layer',
      );
    }
  });

  test('UI depends on data only through the composition root', () {
    final uiFiles = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in uiFiles) {
      if (file.path.endsWith(
        'lib/ui/core/dependency_injection/app_dependencies.dart',
      )) {
        continue;
      }
      expect(
        file.readAsStringSync(),
        isNot(contains('package:stars/data/')),
        reason: '${file.path} bypasses a domain contract',
      );
    }
  });

  test('data and domain layers never depend on UI', () {
    for (final root in const ['lib/data', 'lib/domain']) {
      final files = Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in files) {
        expect(
          file.readAsStringSync(),
          isNot(contains('package:stars/ui/')),
          reason: '${file.path} imports the UI layer',
        );
      }
    }
  });

  test('MCP cross-resource mutations stay in domain use cases', () {
    final viewModel =
        File(
          'lib/ui/features/mcp/view_models/mcp_servers_view_model.dart',
        ).readAsStringSync();
    final useCases =
        File(
          'lib/domain/use_cases/mcp_server_mutations.dart',
        ).readAsStringSync();

    expect(
      viewModel,
      contains('package:stars/domain/use_cases/mcp_server_mutations.dart'),
    );
    expect(viewModel, isNot(contains('mcp_credential_store.dart')));
    expect(viewModel, isNot(contains('.saveServer(')));
    expect(viewModel, isNot(contains('.deleteServer(')));
    expect(useCases, contains('final class SaveAndConnectMcpServer'));
    expect(useCases, contains('final class DeleteMcpServer'));
    expect(useCases, contains('enum McpServerMutationOutcome'));
  });

  test('Chat workflows are assembled by the composition root', () {
    final viewModel =
        File(
          'lib/ui/features/chat/view_models/chat_view_model.dart',
        ).readAsStringSync();
    final interactionFacade =
        File(
          'lib/ui/features/chat/view_models/chat_interaction_facade.dart',
        ).readAsStringSync();
    final workflowFacade =
        File(
          'lib/domain/use_cases/chat_workflow_facade.dart',
        ).readAsStringSync();
    final compositionRoot =
        File(
          'lib/ui/core/dependency_injection/app_dependencies.dart',
        ).readAsStringSync();

    expect(viewModel, contains('required ChatInteractionFacade interaction'));
    expect(viewModel, isNot(contains('domain/repositories/')));
    for (final constructor in const [
      'CreateUserMessage(',
      'GenerateMediaTurn(',
      'PersistConversationAssets(',
      'PrepareTextGeneration(',
    ]) {
      expect(viewModel, isNot(contains(constructor)), reason: constructor);
      expect(compositionRoot, contains(constructor), reason: constructor);
    }
    expect(interactionFacade, contains('final class ChatInteractionFacade'));
    expect(interactionFacade, contains('setCancellableExternalRun'));
    expect(workflowFacade, contains('final class ChatWorkflowFacade'));
    expect(workflowFacade, contains('required GenerateMediaTurn'));
    expect(workflowFacade, contains('required PrepareTextGeneration'));
  });

  test('async ChangeNotifiers use disposal guards', () {
    const auditedViewModels = <String>[
      'lib/ui/features/app/view_models/main_shell_view_model.dart',
      'lib/ui/features/app/view_models/startup_view_model.dart',
      'lib/ui/features/bots/view_models/bot_skill_view_model.dart',
      'lib/ui/features/chat/view_models/chat_generation_view_model.dart',
      'lib/ui/features/chat/view_models/chat_skill_view_model.dart',
      'lib/ui/features/chat/view_models/chat_view_model.dart',
      'lib/ui/features/chat/view_models/conversation_directory_view_model.dart',
      'lib/ui/features/chat/view_models/conversation_memory_view_model.dart',
      'lib/ui/features/chats/view_models/chat_list_view_model.dart',
      'lib/ui/features/feedback/view_models/feedback_view_model.dart',
      'lib/ui/features/mcp/view_models/mcp_servers_view_model.dart',
      'lib/ui/features/profile/view_models/legal_document_view_model.dart',
      'lib/ui/features/profile/view_models/profile_view_model.dart',
    ];

    for (final path in auditedViewModels) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('extends DisposableChangeNotifier'),
        reason: '$path can publish an async completion after disposal',
      );
    }

    final directAsyncNotifiers = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) {
          final source = file.readAsStringSync();
          return source.contains('extends ChangeNotifier') &&
              source.contains('Future<') &&
              source.contains('notifyListeners');
        });

    for (final file in directAsyncNotifiers) {
      final source = file.readAsStringSync();
      expect(
        RegExp(r'bool _(?:isDisposed|disposed)').hasMatch(source),
        isTrue,
        reason: '${file.path} has no disposal guard',
      );
    }
  });

  test('views do not invoke platform action plugins directly', () {
    const pluginImports = <String>[
      'package:file_picker/',
      'package:gallery_saver_plus/',
      'package:image_picker/',
      'package:share_plus/',
      'package:url_launcher/',
    ];
    final viewFiles = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') && file.path.contains('/views/'),
        );

    for (final file in viewFiles) {
      final source = file.readAsStringSync();
      for (final pluginImport in pluginImports) {
        expect(
          source,
          isNot(contains(pluginImport)),
          reason: '${file.path} invokes a platform plugin directly',
        );
      }
    }
  });

  test('production source files respect responsibility review limits', () {
    final sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              !file.path.contains('/generated/') &&
              !file.path.endsWith('.g.dart') &&
              !file.path.endsWith('.freezed.dart'),
        );

    for (final file in sourceFiles) {
      final lineCount = file.readAsLinesSync().length;
      final isView =
          file.path.contains('/ui/') && file.path.contains('/views/');
      final lineLimit = isView ? 780 : 800;
      expect(
        lineCount,
        lessThanOrEqualTo(lineLimit),
        reason:
            '${file.path} has $lineCount lines; its responsibility limit is '
            '$lineLimit',
      );
    }
  });

  test('test entry points stay within feature-group review limits', () {
    final testFiles = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'));

    for (final file in testFiles) {
      final lineCount = file.readAsLinesSync().length;
      final isWidgetFeatureGroup =
          file.path == 'test/widget_test.dart' ||
          file.path.contains('/widget/');
      final lineLimit = isWidgetFeatureGroup ? 1200 : 1500;
      expect(
        lineCount,
        lessThanOrEqualTo(lineLimit),
        reason:
            '${file.path} has $lineCount lines; split tests into independent '
            'feature groups (limit $lineLimit)',
      );
    }
  });

  test('desktop views use the shared component and semantic token system', () {
    final desktopFiles = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              (file.path.contains('/desktop_') ||
                  file.path.endsWith('_desktop.dart') ||
                  file.path.endsWith('_desktop_card.dart') ||
                  file.path.endsWith('skill_library_cards.dart') ||
                  file.path.endsWith('skill_library_details.dart')),
        );
    final rawProductColor = RegExp(r'Colors\.(?!transparent\b)');

    for (final file in desktopFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('MenuAnchor(')),
        reason: '${file.path} bypasses StarsDesktopMenu/StarsContextMenu',
      );
      expect(
        source,
        isNot(contains('MenuItemButton(')),
        reason: '${file.path} mixes Material menu items into desktop UI',
      );
      expect(
        RegExp(r'(?<!Lucide)Icons\.').hasMatch(source),
        isFalse,
        reason: '${file.path} mixes Material icons into desktop UI',
      );
      expect(
        source,
        isNot(matches(rawProductColor)),
        reason: '${file.path} defines a product color outside desktop tokens',
      );
      expect(
        source,
        isNot(contains('BorderRadius.circular(')),
        reason: '${file.path} defines a radius outside the desktop spec',
      );
    }
  });

  test(
    'responsive desktop branches use shared shape, icon, and color tokens',
    () {
      final responsiveFiles = Directory('lib/ui')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => _containsDesktopBranch(file.readAsStringSync()));

      for (final file in responsiveFiles) {
        final violations = _responsiveDesktopViolations(
          file.readAsStringSync(),
        );
        expect(
          violations,
          isEmpty,
          reason: '${file.path} bypasses desktop design tokens: $violations',
        );
      }
    },
  );

  test('desktop branch guard catches violations in a generic file fixture', () {
    final fixture =
        File(
          'test/fixtures/common_responsive_desktop_violation.txt',
        ).readAsStringSync();

    expect(_containsDesktopBranch(fixture), isTrue);
    expect(
      _responsiveDesktopViolations(fixture),
      containsAll(<String>[
        'raw desktop radius',
        'Material icon in desktop branch',
        'product color in desktop branch',
      ]),
    );
  });

  test('desktop icon actions and notices have one implementation', () {
    const directShadIconButtonAllowlist = <String>{
      'lib/ui/core/widgets/desktop_chat_primitives.dart',
      'lib/ui/features/app/views/desktop_layout_toolbar.dart',
    };
    final uiFiles = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in uiFiles) {
      final source = file.readAsStringSync();
      if (!directShadIconButtonAllowlist.contains(file.path)) {
        expect(
          source,
          isNot(contains('ShadIconButton.')),
          reason: '${file.path} bypasses the 44px StarsDesktopIconAction',
        );
      }
      if (!file.path.endsWith('lib/ui/core/widgets/common.dart')) {
        expect(
          source,
          isNot(anyOf(contains('ShadSonner.'), contains('ScaffoldMessenger.'))),
          reason: '${file.path} bypasses showStarsNotice',
        );
      }
    }

    final audioPlayer =
        File(
          'lib/ui/features/chat/views/audio_player_widget.dart',
        ).readAsStringSync();
    expect(audioPlayer, contains('StarsDesktopIconAction('));
    expect(audioPlayer, contains('LucideIcons.pause'));
    expect(audioPlayer, contains('LucideIcons.play'));
    expect(audioPlayer, isNot(contains('width: 48')));
    expect(audioPlayer, isNot(contains('height: 48')));
  });

  test('legacy desktop theme and platform aliases stay removed', () {
    final production = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in production) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('DesktopThemeTokens')));
      expect(source, isNot(contains('StarsDesktopTheme.')));
      expect(source, isNot(contains('isDesktopOrTabletPlatform')));
    }
  });

  test('desktop visual and integration regression matrix stays complete', () {
    const appearances = {'light', 'dark', 'high_contrast'};
    const locales = {'zh_CN', 'en'};
    const widths = {1024, 1280, 1600};
    final goldenDirectory = Directory('test/ui/goldens/desktop_visual_matrix');
    final expected = {
      for (final appearance in appearances)
        for (final locale in locales)
          for (final width in widths) '${appearance}_${locale}_$width.png',
    };
    final actual =
        goldenDirectory
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toSet();

    expect(actual, expected);
    expect(
      File('test/ui/desktop_visual_regression_test.dart').existsSync(),
      isTrue,
    );
    expect(
      File('integration_test/desktop_workflow_test.dart').existsSync(),
      isTrue,
    );
    expect(File('test_driver/integration_test.dart').existsSync(), isTrue);
  });
}

bool _containsDesktopBranch(String source) => RegExp(
  r'\b(?:isDesktopPlatform|isDesktop|_isDesktop|desktopMode)\b',
).hasMatch(source);

List<String> _responsiveDesktopViolations(String source) {
  final normalized = source.replaceAll(RegExp(r'\s+'), ' ');
  const desktopCondition = r'(?:(?:widget\.)?_?isDesktop|desktopMode)';
  final violations = <String>[];

  final radiusSelectedInsideCall = RegExp(
    'BorderRadius\\.circular\\(\\s*$desktopCondition\\b',
  );
  final rawRadiusInDesktopDecoration = RegExp(
    '$desktopCondition\\s*\\?\\s*BoxDecoration\\(.{0,600}?'
    r'borderRadius:\s*BorderRadius\.circular\(',
  );
  if (radiusSelectedInsideCall.hasMatch(normalized) ||
      rawRadiusInDesktopDecoration.hasMatch(normalized)) {
    violations.add('raw desktop radius');
  }

  if (RegExp(
    '$desktopCondition\\s*\\?\\s*(?:const\\s+)?'
    r'(?:Icon\(\s*)?Icons\.',
  ).hasMatch(normalized)) {
    violations.add('Material icon in desktop branch');
  }

  if (RegExp(
    '$desktopCondition\\s*\\?\\s*Colors\\.(?!transparent\\b)',
  ).hasMatch(normalized)) {
    violations.add('product color in desktop branch');
  }

  return violations;
}
