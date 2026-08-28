import 'package:stars/data/repositories/ai_provider_repository_impl.dart';
import 'package:stars/data/repositories/attachment_repository_impl.dart';
import 'package:stars/data/repositories/feedback_repository_impl.dart';
import 'package:stars/data/repositories/legal_document_repository_impl.dart';
import 'package:stars/data/repositories/local_conversation_directory_repository.dart';
import 'package:stars/data/repositories/memory_conversation_draft_repository.dart';
import 'package:stars/data/repositories/platform_message_action_repository.dart';
import 'package:stars/data/repositories/file_skill_repository.dart';
import 'package:stars/data/repositories/sqlite_mcp_server_repository.dart';
import 'package:stars/data/repositories/sqlite_mcp_inventory_repository.dart';
import 'package:stars/data/repositories/skill_picker_repository_impl.dart';
import 'package:stars/data/repositories/sqlite_bot_repository.dart';
import 'package:stars/data/repositories/sqlite_bot_skill_binding_repository.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/data/repositories/sqlite_conversation_skill_pin_repository.dart';
import 'package:stars/data/repositories/sqlite_conversation_memory_repository.dart';
import 'package:stars/data/repositories/sqlite_conversation_history_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_model_usage_repository.dart';
import 'package:stars/data/repositories/sqlite_profile_repository.dart';
import 'package:stars/data/repositories/sqlite_skill_run_repository.dart';
import 'package:stars/data/repositories/sqlite_skill_ecosystem_repository.dart';
import 'package:stars/data/repositories/sqlite_skill_inventory_repository.dart';
import 'package:stars/data/services/feedback_service.dart';
import 'package:stars/data/services/attachment_picker_service.dart';
import 'package:stars/data/services/asset_text_service.dart';
import 'package:stars/data/services/bot_api_key_cipher.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/conversation_summary_storage.dart';
import 'package:stars/data/services/ai/provider_context_summarizer.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/mcp/mcp_catalog_service.dart';
import 'package:stars/data/services/mcp/mcp_client_service.dart';
import 'package:stars/data/services/mcp/mcp_endpoint_policy.dart';
import 'package:stars/data/services/mcp/mcp_http_transport.dart';
import 'package:stars/data/services/mcp/mcp_stdio_transport.dart';
import 'package:stars/data/services/mcp/secure_mcp_credential_store.dart';
import 'package:stars/data/services/skills/skill_package_storage_service.dart';
import 'package:stars/data/services/skills/skill_parser.dart';
import 'package:stars/data/services/skills/skill_picker_service.dart';
import 'package:stars/data/services/skills/linux_bubblewrap_skill_sandbox.dart';
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_catalog_service.dart';
import 'package:stars/data/services/skills/skill_installation_service.dart';
import 'package:stars/data/services/skills/skill_organization_policy_bundle_service.dart';
import 'package:stars/data/services/skills/skill_script_catalog_service.dart';
import 'package:stars/data/services/skills/skill_script_manifest_parser.dart';
import 'package:stars/data/services/skills/skill_signature_service.dart';
import 'package:stars/data/services/tools/built_in_tools.dart';
import 'package:stars/data/services/tools/add_mcp_server_tool.dart';
import 'package:stars/data/services/tools/shell_command_tool.dart';
import 'package:stars/data/services/tools/skill_installer_tool.dart';
import 'package:stars/data/services/tools/system_conversation_history_skill.dart';
import 'package:stars/data/services/tools/system_local_file_system_skills.dart';
import 'package:stars/data/services/tools/system_shell_skill.dart';
import 'package:stars/data/services/tools/system_skill_installer_skill.dart';
import 'package:stars/data/services/tools/system_mcp_installer_skill.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/legal_document.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/conversation_skill_pin_repository.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/conversation_history_repository.dart';
import 'package:stars/domain/repositories/conversation_draft_repository.dart';
import 'package:stars/domain/repositories/conversation_directory_repository.dart';
import 'package:stars/domain/repositories/feedback_repository.dart';
import 'package:stars/domain/repositories/legal_document_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/repositories/model_usage_repository.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/repositories/mcp_inventory_repository.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/repositories/skill_ecosystem_repository.dart';
import 'package:stars/domain/repositories/skill_inventory_repository.dart';
import 'package:stars/domain/repositories/skill_run_repository.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/chat_workflow_facade.dart';
import 'package:stars/domain/use_cases/create_chat.dart';
import 'package:stars/domain/use_cases/create_user_message.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/domain/use_cases/mcp_server_mutations.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';
import 'package:stars/domain/use_cases/prepare_conversation_context.dart';
import 'package:stars/domain/use_cases/compact_conversation.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_interaction_facade.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';
import 'package:stars/ui/features/app/view_models/app_view_model.dart';
import 'package:stars/ui/features/app/view_models/main_shell_view_model.dart';
import 'package:stars/ui/features/app/view_models/startup_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_list_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_form_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_token_usage_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_skill_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_skill_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_view_model.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';
import 'package:stars/ui/features/chat/view_models/conversation_memory_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_token_usage_view_model.dart';
import 'package:stars/ui/features/chats/view_models/chat_list_view_model.dart';
import 'package:stars/ui/features/chats/view_models/new_chat_view_model.dart';
import 'package:stars/ui/features/feedback/view_models/feedback_view_model.dart';
import 'package:stars/ui/features/mcp/view_models/mcp_servers_view_model.dart';
import 'package:stars/ui/features/profile/view_models/profile_view_model.dart';
import 'package:stars/ui/features/profile/view_models/legal_document_view_model.dart';
import 'package:stars/ui/features/skills/view_models/skill_library_view_model.dart';

part 'app_dependencies_chat.dart';

/// Application composition root. Production implementations are assembled in
/// one place; views only receive repositories through their ViewModels.
class AppDependencies {
  AppDependencies({
    required this.botRepository,
    required this.chatRepository,
    required this.messageRepository,
    required this.modelUsageRepository,
    required this.profileRepository,
    required this.feedbackRepository,
    required this.aiProviderRepository,
    required this.attachmentRepository,
    required this.conversationArtifactsDirectoryProvider,
    required this.legalDocumentRepository,
    required this.skillRepository,
    required this.skillInventoryRepository,
    required this.skillPickerRepository,
    required this.botSkillBindingRepository,
    required this.conversationSkillPinRepository,
    required this.conversationMemoryRepository,
    required this.conversationHistoryRepository,
    required this.skillRunRepository,
    required this.mcpServerRepository,
    required this.mcpInventoryRepository,
    required this.mcpCredentialStore,
    required this.mcpCatalogService,
    required this.toolRegistry,
    required this.toolPolicy,
    required this.composeChatTurn,
    required this.createUserMessage,
    required this.persistConversationAssets,
    required this.generateMediaTurn,
    required this.prepareTextGeneration,
    required this.compactConversation,
    required this.systemConversationHistorySkill,
    required this.systemDirectoryOperationsSkill,
    required this.systemFileOperationsSkill,
    required this.systemMcpInstallerSkill,
    required this.systemShellSkill,
    required this.systemSkillInstallerSkill,
    required this.bundledSkillLoader,
    required this.createChat,
    required this.generationRegistry,
    ConversationDraftRepository? conversationDraftRepository,
    ConversationDirectoryRepository? conversationDirectoryRepository,
    MessageActionRepository? messageActionRepository,
    this.skillEcosystemRepository,
    this.skillScriptCatalogService,
    this.skillCatalogService,
    this.skillOrganizationPolicyBundleService,
  }) : conversationDraftRepository =
           conversationDraftRepository ?? MemoryConversationDraftRepository(),
       conversationDirectoryRepository =
           conversationDirectoryRepository ??
           LocalConversationDirectoryRepository(
             directoryProvider: conversationArtifactsDirectoryProvider,
           ),
       messageActionRepository =
           messageActionRepository ?? const PlatformMessageActionRepository();

  factory AppDependencies.production() {
    final databaseService = DatabaseService();
    final localDatabase = LocalDatabaseService(
      databaseProvider: () => databaseService.database,
    );
    final conversationSummaryStorage = ConversationSummaryStorage();
    conversationSummaryStorage.recoverPendingDeletions().ignore();
    final conversationMemoryRepository = SqliteConversationMemoryRepository(
      localDatabase: localDatabase,
      storage: conversationSummaryStorage,
    );
    final conversationDraftRepository = MemoryConversationDraftRepository();
    final chatRepository = SqliteChatRepository(
      localDatabase: localDatabase,
      conversationMemoryRepository: conversationMemoryRepository,
      conversationSummaryStorage: conversationSummaryStorage,
      conversationDraftRepository: conversationDraftRepository,
    );
    final messageRepository = SqliteMessageRepository(
      localDatabase: localDatabase,
    );
    final conversationHistoryRepository = SqliteConversationHistoryRepository(
      messageRepository: messageRepository,
    );
    final modelUsageRepository = SqliteModelUsageRepository(
      localDatabase: localDatabase,
    );
    final botApiKeyCipher = SecureBotApiKeyCipher();
    final botRepository = SqliteBotRepository(
      localDatabase: localDatabase,
      chatRepository: chatRepository,
      apiKeyCipher: botApiKeyCipher,
    );
    final profileRepository = SqliteProfileRepository(
      localDatabase: localDatabase,
    );
    final feedbackRepository = FeedbackRepositoryImpl(
      service: const FeedbackService(),
    );
    const aiProviderRepository = AiProviderRepositoryImpl();
    final systemConversationHistorySkill = SystemConversationHistorySkill();
    final systemDirectoryOperationsSkill = SystemDirectoryOperationsSkill();
    final systemFileOperationsSkill = SystemFileOperationsSkill();
    final systemMcpInstallerSkill = SystemMcpInstallerSkill();
    final systemSkillInstallerSkill = SystemSkillInstallerSkill();
    final shellCommandTool = createHostShellCommandTool();
    final systemShellSkill =
        shellCommandTool == null ? null : SystemShellSkill();
    Future<List<SkillContent>> loadBundledSkills() async {
      final contents = <SkillContent>[];
      try {
        contents.add(await systemConversationHistorySkill.loadContent());
      } on Object {
        // A damaged built-in Skill is omitted while other Skills stay usable.
      }
      try {
        contents.add(await systemDirectoryOperationsSkill.loadContent());
      } on Object {
        // Directory operations fail closed if their Skill is damaged.
      }
      try {
        contents.add(await systemFileOperationsSkill.loadContent());
      } on Object {
        // File operations fail closed if their Skill is damaged.
      }
      try {
        final shellSkill = systemShellSkill;
        if (shellSkill != null) {
          contents.add(await shellSkill.loadContent());
        }
      } on Object {
        // Shell execution fails closed if its built-in Skill is damaged.
      }
      try {
        contents.add(await systemSkillInstallerSkill.loadContent());
      } on Object {
        // Skill installation fails closed if its built-in Skill is damaged.
      }
      try {
        contents.add(await systemMcpInstallerSkill.loadContent());
      } on Object {
        // MCP installation fails closed if its built-in Skill is damaged.
      }
      return List<SkillContent>.unmodifiable(contents);
    }

    final compactConversation = CompactConversation(
      messageRepository: messageRepository,
      memoryRepository: conversationMemoryRepository,
      summarizerFactory:
          (bot) => ProviderContextSummarizer(
            bot: bot,
            providerFactory: aiProviderRepository.create,
          ),
      usagePersister:
          (operationId, chatId, bot, usage) => modelUsageRepository.upsert(
            ModelTokenUsageRecord(
              messageId: operationId,
              chatId: chatId,
              botId: bot.id,
              timestamp: DateTime.now(),
              usage: usage,
              operationKind: 'context_compaction',
            ),
          ),
    );
    final attachmentRepository = AttachmentRepositoryImpl(
      service: AttachmentPickerService(),
    );
    final conversationArtifactsDirectoryProvider =
        attachmentRepository.getOutputDirectory;
    final persistConversationAssets = PersistConversationAssets(
      repository: attachmentRepository,
    );
    final createUserMessage = CreateUserMessage(
      messageRepository: messageRepository,
    );
    final generateMediaTurn = GenerateMediaTurn(
      messageRepository: messageRepository,
      chatRepository: chatRepository,
      providerRepository: aiProviderRepository,
      attachmentRepository: attachmentRepository,
      persistConversationAssets: persistConversationAssets,
    );
    const legalDocumentRepository = LegalDocumentRepositoryImpl(
      service: AssetTextService(),
    );
    final skillEcosystemRepository = SqliteSkillEcosystemRepository(
      localDatabase: localDatabase,
    );
    final skillStorageService = SkillPackageStorageService();
    final skillRepository = FileSkillRepository(
      localDatabase: localDatabase,
      storageService: skillStorageService,
      parser: const SkillParser(),
      ecosystemRepository: skillEcosystemRepository,
      signatureService: SkillSignatureService(
        ecosystemRepository: skillEcosystemRepository,
      ),
    );
    final skillInventoryRepository = SqliteSkillInventoryRepository(
      localDatabase: localDatabase,
    );
    final skillInstallerTool = SkillInstallerTool(
      installation: SkillInstallationService(
        skillRepository: skillRepository,
        endpointPolicy: SkillCatalogEndpointPolicy(),
      ),
    );
    const skillPickerRepository = SkillPickerRepositoryImpl(
      service: SkillPickerService(),
    );
    final botSkillBindingRepository = SqliteBotSkillBindingRepository(
      localDatabase: localDatabase,
    );
    final skillRunRepository = SqliteSkillRunRepository(
      localDatabase: localDatabase,
    );
    final conversationSkillPinRepository = SqliteConversationSkillPinRepository(
      localDatabase: localDatabase,
    );
    final mcpServerRepository = SqliteMcpServerRepository(
      localDatabase: localDatabase,
    );
    final mcpInventoryRepository = SqliteMcpInventoryRepository(
      localDatabase: localDatabase,
    );
    final mcpCredentialStore = SecureMcpCredentialStore();
    final mcpClient = McpClientService(
      transports: [
        McpHttpTransport(endpointPolicy: McpEndpointPolicy()),
        McpStdioTransport(),
      ],
      credentialStore: mcpCredentialStore,
    );
    final composeChatTurn = ComposeChatTurn(
      skillRepository: skillRepository,
      bindingRepository: botSkillBindingRepository,
      mcpServerRepository: mcpServerRepository,
      prepareConversationContext: PrepareConversationContext(
        memoryRepository: conversationMemoryRepository,
        aiProviderRepository: aiProviderRepository,
        historySkillAvailable: () => systemConversationHistorySkill.isValid,
      ),
      compactConversation: compactConversation,
      bundledSkillLoader: loadBundledSkills,
      conversationArtifactsDirectoryProvider:
          conversationArtifactsDirectoryProvider,
    );
    final prepareTextGeneration = PrepareTextGeneration(
      composeChatTurn: composeChatTurn.call,
      aiProviderRepository: aiProviderRepository,
      conversationHistoryRepository: conversationHistoryRepository,
      mcpInventoryRepository: mcpInventoryRepository,
      skillInventoryRepository: skillInventoryRepository,
    );
    final toolRegistry = DynamicToolRegistry([
      ...createBuiltInTools(),
      if (shellCommandTool != null) shellCommandTool,
      skillInstallerTool,
    ]);
    final mcpCatalogService = McpCatalogService(
      repository: mcpServerRepository,
      client: mcpClient,
      toolRegistry: toolRegistry,
    );
    final addMcpServerTool = AddMcpServerTool(
      repository: mcpServerRepository,
      credentialStore: mcpCredentialStore,
      connector:
          (serverId, cancellationToken) => mcpCatalogService.refreshServer(
            serverId,
            cancellationToken: cancellationToken,
          ),
    );
    toolRegistry.replaceDynamicSource('system-mcp', [addMcpServerTool]);
    final skillScriptCatalogService = SkillScriptCatalogService(
      skillRepository: skillRepository,
      ecosystemRepository: skillEcosystemRepository,
      manifestParser: const SkillScriptManifestParser(),
      sandbox: LinuxBubblewrapSkillSandbox(
        installationVerifier: skillStorageService.verifyImmutableInstallation,
      ),
      toolRegistry: toolRegistry,
    );
    final skillCatalogService = SkillCatalogService(
      ecosystemRepository: skillEcosystemRepository,
      skillRepository: skillRepository,
      endpointPolicy: SkillCatalogEndpointPolicy(),
    );
    final skillOrganizationPolicyBundleService =
        SkillOrganizationPolicyBundleService(
          ecosystemRepository: skillEcosystemRepository,
        );
    const toolPolicy = DefaultToolPolicy(
      allowDestructiveWithApproval: true,
      allowSkillScripts: true,
      allowProcessExecution: true,
    );
    return AppDependencies(
      botRepository: botRepository,
      chatRepository: chatRepository,
      messageRepository: messageRepository,
      modelUsageRepository: modelUsageRepository,
      profileRepository: profileRepository,
      feedbackRepository: feedbackRepository,
      aiProviderRepository: aiProviderRepository,
      attachmentRepository: attachmentRepository,
      conversationArtifactsDirectoryProvider:
          conversationArtifactsDirectoryProvider,
      legalDocumentRepository: legalDocumentRepository,
      skillRepository: skillRepository,
      skillInventoryRepository: skillInventoryRepository,
      skillPickerRepository: skillPickerRepository,
      botSkillBindingRepository: botSkillBindingRepository,
      conversationSkillPinRepository: conversationSkillPinRepository,
      conversationMemoryRepository: conversationMemoryRepository,
      conversationHistoryRepository: conversationHistoryRepository,
      skillRunRepository: skillRunRepository,
      mcpServerRepository: mcpServerRepository,
      mcpInventoryRepository: mcpInventoryRepository,
      mcpCredentialStore: mcpCredentialStore,
      mcpCatalogService: mcpCatalogService,
      toolRegistry: toolRegistry,
      toolPolicy: toolPolicy,
      composeChatTurn: composeChatTurn,
      createUserMessage: createUserMessage,
      persistConversationAssets: persistConversationAssets,
      generateMediaTurn: generateMediaTurn,
      prepareTextGeneration: prepareTextGeneration,
      compactConversation: compactConversation,
      systemConversationHistorySkill: systemConversationHistorySkill,
      systemDirectoryOperationsSkill: systemDirectoryOperationsSkill,
      systemFileOperationsSkill: systemFileOperationsSkill,
      systemMcpInstallerSkill: systemMcpInstallerSkill,
      systemShellSkill: systemShellSkill,
      systemSkillInstallerSkill: systemSkillInstallerSkill,
      bundledSkillLoader: loadBundledSkills,
      createChat: CreateChat(chatRepository: chatRepository),
      generationRegistry: ChatGenerationRegistry(
        messagePersister: messageRepository.upsertMessage,
        lastMessageUpdater: chatRepository.updateLastMessage,
        providerFactory: aiProviderRepository.create,
        messageIdFactory: messageRepository.createId,
        skillActivationPersister: skillRunRepository.saveActivations,
        terminalMessageObserver: (chatId, bot, message, report) async {
          final action = report?.compressionAction;
          if (action == ContextCompressionAction.backgroundReady ||
              action == ContextCompressionAction.synchronous ||
              action == ContextCompressionAction.fallbackTrim) {
            await compactConversation(bot: bot, chatId: chatId);
          }
        },
        toolInvocationPersister: (runId, chatId, botId, audit) async {
          final now = DateTime.now();
          await skillEcosystemRepository.appendComplianceEvent(
            SkillComplianceEvent(
              id:
                  '${now.microsecondsSinceEpoch}:tool:$runId:'
                  '${audit.callId}:${audit.status}',
              type: SkillComplianceEventType.toolInvoked,
              decision: audit.approvalStatus,
              reason: audit.errorCode,
              metadata: {
                'runId': runId,
                'chatId': chatId,
                'botId': botId,
                'callId': audit.callId,
                'tool': audit.name,
                'source': audit.source,
                'riskLevel': audit.riskLevel,
                'status': audit.status,
                'argumentsSummary': audit.argumentsSummary,
                'resultSummary': audit.resultSummary,
                'durationMs': audit.durationMs,
              },
              timestamp: now,
            ),
          );
        },
        toolRegistry: toolRegistry,
        toolPolicy: toolPolicy,
      ),
      skillEcosystemRepository: skillEcosystemRepository,
      skillScriptCatalogService: skillScriptCatalogService,
      skillCatalogService: skillCatalogService,
      skillOrganizationPolicyBundleService:
          skillOrganizationPolicyBundleService,
      conversationDraftRepository: conversationDraftRepository,
    );
  }

  final BotRepository botRepository;
  final ChatRepository chatRepository;
  final MessageRepository messageRepository;
  final ModelUsageRepository modelUsageRepository;
  final ProfileRepository profileRepository;
  final FeedbackRepository feedbackRepository;
  final AiProviderRepository aiProviderRepository;
  final AttachmentRepository attachmentRepository;
  final ConversationArtifactsDirectoryProvider
  conversationArtifactsDirectoryProvider;
  final LegalDocumentRepository legalDocumentRepository;
  final SkillRepository skillRepository;
  final SkillInventoryRepository skillInventoryRepository;
  final SkillPickerRepository skillPickerRepository;
  final BotSkillBindingRepository botSkillBindingRepository;
  final ConversationSkillPinRepository conversationSkillPinRepository;
  final ConversationMemoryRepository conversationMemoryRepository;
  final ConversationDirectoryRepository conversationDirectoryRepository;
  final ConversationHistoryRepository conversationHistoryRepository;
  final SkillRunRepository skillRunRepository;
  final McpServerRepository mcpServerRepository;
  final McpInventoryRepository mcpInventoryRepository;
  final McpCredentialStore mcpCredentialStore;
  final McpCatalogService mcpCatalogService;
  final ToolRegistry toolRegistry;
  final ToolPolicy toolPolicy;
  final ComposeChatTurn composeChatTurn;
  final CreateUserMessage createUserMessage;
  final PersistConversationAssets persistConversationAssets;
  final GenerateMediaTurn generateMediaTurn;
  final PrepareTextGeneration prepareTextGeneration;
  final CompactConversation compactConversation;
  final SystemConversationHistorySkill systemConversationHistorySkill;
  final SystemDirectoryOperationsSkill systemDirectoryOperationsSkill;
  final SystemFileOperationsSkill systemFileOperationsSkill;
  final SystemMcpInstallerSkill systemMcpInstallerSkill;
  final SystemShellSkill? systemShellSkill;
  final SystemSkillInstallerSkill systemSkillInstallerSkill;
  final BundledSkillLoader bundledSkillLoader;
  final CreateChat createChat;
  final ChatGenerationRegistry generationRegistry;
  final ConversationDraftRepository conversationDraftRepository;
  final MessageActionRepository messageActionRepository;
  final SkillEcosystemRepository? skillEcosystemRepository;
  final SkillScriptCatalogService? skillScriptCatalogService;
  final SkillCatalogService? skillCatalogService;
  final SkillOrganizationPolicyBundleService?
  skillOrganizationPolicyBundleService;

  StartupViewModel createStartupViewModel() => StartupViewModel(
    profileRepository: profileRepository,
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

  AppViewModel createAppViewModel(Profile initialProfile) => AppViewModel(
    initialProfile: initialProfile,
    profileRepository: profileRepository,
  );

  MainShellViewModel createMainShellViewModel() =>
      MainShellViewModel(botRepository: botRepository);

  ChatListViewModel createChatListViewModel() => ChatListViewModel(
    chatRepository: chatRepository,
    botRepository: botRepository,
  );

  BotListViewModel createBotListViewModel() => BotListViewModel(
    botRepository: botRepository,
    createChat: createChat,
    aiProviderRepository: aiProviderRepository,
    attachmentRepository: attachmentRepository,
    botSkillBindingRepository: botSkillBindingRepository,
    messageRepository: messageRepository,
    mcpServerRepository: mcpServerRepository,
  );

  BotFormViewModel createBotFormViewModel() => BotFormViewModel(
    mcpServerRepository: mcpServerRepository,
    aiProviderRepository: aiProviderRepository,
  );

  BotTokenUsageViewModel createBotTokenUsageViewModel(String botId) =>
      BotTokenUsageViewModel(
        botId: botId,
        messageRepository: messageRepository,
        chatRepository: chatRepository,
      );

  BotSkillViewModel createBotSkillViewModel(Bot bot) {
    final provider = aiProviderRepository.create(bot);
    return BotSkillViewModel(
      botId: bot.id,
      skillRepository: skillRepository,
      bindingRepository: botSkillBindingRepository,
      bundledSkillLoader: bundledSkillLoader,
      skillToolProvider: provider,
      supportsAutoActivation:
          bot.configuredSupportsAutomaticSkillActivation ??
          provider.capabilities.supportsAutomaticSkillActivation,
    );
  }

  BotSkillViewModel createDraftBotSkillViewModel(String botId) =>
      BotSkillViewModel(
        botId: botId,
        skillRepository: skillRepository,
        bindingRepository: DraftBotSkillBindingRepository(),
        bundledSkillLoader: bundledSkillLoader,
        supportsAutoActivation: false,
      );

  SkillLibraryViewModel createSkillLibraryViewModel() => SkillLibraryViewModel(
    skillRepository: skillRepository,
    pickerRepository: skillPickerRepository,
    ecosystemRepository: skillEcosystemRepository,
    scriptCatalogService: skillScriptCatalogService,
    catalogService: skillCatalogService,
    bundledSkillLoader: bundledSkillLoader,
  );

  McpServersViewModel createMcpServersViewModel() => McpServersViewModel(
    repository: mcpServerRepository,
    catalogService: mcpCatalogService,
    saveAndConnect: SaveAndConnectMcpServer(
      repository: mcpServerRepository,
      credentialStore: mcpCredentialStore,
      catalogController: mcpCatalogService,
    ),
    deleteServer: DeleteMcpServer(
      repository: mcpServerRepository,
      botRepository: botRepository,
      credentialStore: mcpCredentialStore,
      catalogController: mcpCatalogService,
    ),
  );

  ChatSkillViewModel createChatSkillViewModel(String chatId, Bot bot) =>
      ChatSkillViewModel(
        botId: bot.id,
        skillRepository: skillRepository,
        bindingRepository: botSkillBindingRepository,
        bundledSkillLoader: bundledSkillLoader,
        supportsAutoActivation:
            bot.configuredSupportsAutomaticSkillActivation ??
            aiProviderRepository
                .create(bot)
                .capabilities
                .supportsAutomaticSkillActivation,
      );

  ProfileViewModel createProfileViewModel() => ProfileViewModel(
    profileRepository: profileRepository,
    attachmentRepository: attachmentRepository,
  );

  LegalDocumentViewModel createLegalDocumentViewModel(LegalDocumentType type) =>
      LegalDocumentViewModel(type: type, repository: legalDocumentRepository);

  FeedbackViewModel createFeedbackViewModel() =>
      FeedbackViewModel(feedbackRepository: feedbackRepository);

  NewChatViewModel createNewChatViewModel() =>
      NewChatViewModel(botRepository: botRepository, createChat: createChat);

  ChatViewModel createChatViewModel(String chatId, Bot bot) {
    final workflow = ChatWorkflowFacade(
      chatId: chatId,
      bot: bot,
      messageRepository: messageRepository,
      chatRepository: chatRepository,
      aiProviderRepository: aiProviderRepository,
      attachmentRepository: attachmentRepository,
      conversationDraftRepository: conversationDraftRepository,
      createUserMessage: createUserMessage,
      persistConversationAssets: persistConversationAssets,
      generateMediaTurn: generateMediaTurn,
      prepareTextGeneration: prepareTextGeneration,
    );
    return ChatViewModel(
      interaction: ChatInteractionFacade(
        workflow: workflow,
        messageActions: MessageActionViewModel(
          repository: messageActionRepository,
        ),
        generationRegistry: generationRegistry,
        generationViewModel: generationRegistry.viewModelFor(chatId, bot),
      ),
    );
  }
}
