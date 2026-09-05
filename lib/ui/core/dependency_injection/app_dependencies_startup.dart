part of 'app_dependencies.dart';

extension AppDependenciesStartupFactory on AppDependencies {
  StartupViewModel createStartupViewModel() => StartupViewModel(
    profileRepository: profileRepository,
    recoveryInitializer: startupRecoveryInitializer,
    capabilityInitializer: () async {
      final statuses = <StartupCapabilityStatus>[];
      Future<void> inspect(
        String id, {
        required bool required,
        required Future<void> Function() initialize,
      }) async {
        try {
          await initialize();
          statuses.add(
            StartupCapabilityStatus(
              id: id,
              required: required,
              state: StartupCapabilityState.available,
            ),
          );
        } on Object catch (error) {
          final failure = AppFailure.from(
            error,
            code: '${id}_initialization_failed',
          );
          statuses.add(
            StartupCapabilityStatus(
              id: id,
              required: required,
              state:
                  required
                      ? StartupCapabilityState.failed
                      : StartupCapabilityState.degraded,
              diagnosticCode: failure.code,
              retryable: failure.retryable,
            ),
          );
        }
      }

      await inspect(
        'conversation_history_skill',
        required: true,
        initialize: systemConversationHistorySkill.validate,
      );
      await inspect(
        'directory_operations_skill',
        required: true,
        initialize: systemDirectoryOperationsSkill.validate,
      );
      await inspect(
        'file_operations_skill',
        required: true,
        initialize: systemFileOperationsSkill.validate,
      );
      if (systemShellSkill case final shellSkill?) {
        await inspect(
          'shell_skill',
          required: true,
          initialize: shellSkill.validate,
        );
      }
      await inspect(
        'skill_installer',
        required: true,
        initialize: systemSkillInstallerSkill.validate,
      );
      await inspect(
        'mcp_installer',
        required: true,
        initialize: systemMcpInstallerSkill.validate,
      );
      await inspect(
        'mcp_catalog_cache',
        required: false,
        initialize: mcpCatalogService.hydrateFromCache,
      );
      if (skillScriptCatalogService case final scriptCatalog?) {
        await inspect(
          'skill_script_catalog',
          required: false,
          initialize: scriptCatalog.hydrateFromCache,
        );
      }
      if (skillCatalogService case final onlineCatalog?) {
        await inspect(
          'online_skill_catalog',
          required: false,
          initialize: onlineCatalog.refreshConfiguredCatalogs,
        );
      }
      return StartupCapabilitiesReport(List.unmodifiable(statuses));
    },
  );
}
