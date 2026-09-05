import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/conversation_history_repository.dart';
import 'package:stars/domain/repositories/mcp_inventory_repository.dart';
import 'package:stars/domain/repositories/skill_inventory_repository.dart';
import 'package:stars/domain/services/verification_tool_discovery.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/conversation_history_tools.dart';
import 'package:stars/domain/use_cases/mcp_inventory_tools.dart';
import 'package:stars/domain/use_cases/skill_inventory_tools.dart';

typedef ChatTurnComposer =
    Future<PreparedChatTurn> Function({
      required Bot bot,
      required List<Message> history,
      required Message userMessage,
      required String currentUserId,
      AiProvider? skillToolProvider,
    });

final class PreparedChatGeneration {
  PreparedChatGeneration({
    required this.userMessage,
    required List<ChatMessage> messages,
    required List<ActivatedSkill> activatedSkills,
    required List<SkillActivationAttempt> activationAttempts,
    required List<MessageToolCall> skillToolCalls,
    required this.preflightTokenUsage,
    required Set<String> requestedToolNames,
    Set<String> verificationToolNames = const {},
    required Set<String> approvalExemptToolNames,
    required List<ExecutableTool> runScopedTools,
    required this.contextAssemblyReport,
    this.reliabilityPolicyEnabled = true,
    this.verificationUnavailableReason = '',
  }) : messages = List<ChatMessage>.unmodifiable(messages),
       activatedSkills = List<ActivatedSkill>.unmodifiable(activatedSkills),
       activationAttempts = List<SkillActivationAttempt>.unmodifiable(
         activationAttempts,
       ),
       skillToolCalls = List<MessageToolCall>.unmodifiable(skillToolCalls),
       requestedToolNames = Set<String>.unmodifiable(requestedToolNames),
       verificationToolNames = Set<String>.unmodifiable(verificationToolNames),
       approvalExemptToolNames = Set<String>.unmodifiable(
         approvalExemptToolNames,
       ),
       runScopedTools = List<ExecutableTool>.unmodifiable(runScopedTools);

  final Message userMessage;
  final List<ChatMessage> messages;
  final List<ActivatedSkill> activatedSkills;
  final List<SkillActivationAttempt> activationAttempts;
  final List<MessageToolCall> skillToolCalls;
  final ModelTokenUsage preflightTokenUsage;
  final Set<String> requestedToolNames;
  final Set<String> verificationToolNames;
  final Set<String> approvalExemptToolNames;
  final List<ExecutableTool> runScopedTools;
  final ContextAssemblyReport contextAssemblyReport;
  final bool reliabilityPolicyEnabled;
  final String verificationUnavailableReason;
}

/// Prepares a text generation request and its run-scoped tools.
final class PrepareTextGeneration {
  PrepareTextGeneration({
    required ChatTurnComposer composeChatTurn,
    required AiProviderRepository aiProviderRepository,
    ConversationHistoryRepository? conversationHistoryRepository,
    McpInventoryRepository? mcpInventoryRepository,
    SkillInventoryRepository? skillInventoryRepository,
    ToolRegistry? toolRegistry,
    Set<String> verificationToolCandidateNames = const {},
    VerificationToolDiscovery verificationToolDiscovery =
        const VerificationToolDiscovery(),
  }) : _composeChatTurn = composeChatTurn,
       _aiProviderRepository = aiProviderRepository,
       _conversationHistoryRepository = conversationHistoryRepository,
       _mcpInventoryRepository = mcpInventoryRepository,
       _skillInventoryRepository = skillInventoryRepository,
       _toolRegistry = toolRegistry,
       _verificationToolCandidateNames = Set<String>.unmodifiable(
         verificationToolCandidateNames,
       ),
       _verificationToolDiscovery = verificationToolDiscovery;

  final ChatTurnComposer _composeChatTurn;
  final AiProviderRepository _aiProviderRepository;
  final ConversationHistoryRepository? _conversationHistoryRepository;
  final McpInventoryRepository? _mcpInventoryRepository;
  final SkillInventoryRepository? _skillInventoryRepository;
  final ToolRegistry? _toolRegistry;
  final Set<String> _verificationToolCandidateNames;
  final VerificationToolDiscovery _verificationToolDiscovery;

  Future<PreparedChatTurn> prepareTurn({
    required Bot bot,
    required List<Message> history,
    required Message userMessage,
    required String currentUserId,
  }) => _composeChatTurn(
    bot: bot,
    history: history,
    userMessage: userMessage,
    currentUserId: currentUserId,
    skillToolProvider: _aiProviderRepository.create(bot),
  );

  Future<PreparedChatGeneration> call({
    required String chatId,
    required Bot bot,
    required List<Message> history,
    required Message userMessage,
    required String currentUserId,
  }) async {
    final preparedTurn = await prepareTurn(
      bot: bot,
      history: history,
      userMessage: userMessage,
      currentUserId: currentUserId,
    );
    final historyRepository = _conversationHistoryRepository;
    final historyTools =
        preparedTurn.contextAssemblyReport.historyLookupAvailable &&
                historyRepository != null
            ? ConversationHistoryToolSession(
              repository: historyRepository,
              chatId: chatId,
              runId: userMessage.runId,
              resultTokenBudget:
                  preparedTurn.contextAssemblyReport.historyLookupReserveTokens,
              initiallyAllowedReferences: preparedTurn.historySummaryReferences,
            ).createTools()
            : const <ExecutableTool>[];
    final skillInventoryRepository = _skillInventoryRepository;
    final skillInventoryTools =
        skillInventoryRepository != null &&
                preparedTurn.requestedToolNames.any(
                  skillInventoryToolNames.contains,
                )
            ? SkillInventoryToolSession(
              repository: skillInventoryRepository,
              chatId: chatId,
            ).createTools()
            : const <ExecutableTool>[];
    final mcpInventoryRepository = _mcpInventoryRepository;
    final mcpInventoryTools =
        mcpInventoryRepository != null &&
                preparedTurn.requestedToolNames.any(
                  mcpInventoryToolNames.contains,
                )
            ? McpInventoryToolSession(
              repository: mcpInventoryRepository,
              chatId: chatId,
            ).createTools()
            : const <ExecutableTool>[];
    final verificationTools =
        preparedTurn.reliabilityPolicyEnabled
            ? _verificationToolDiscovery.discover(
              registry: _toolRegistry,
              candidateToolNames: _verificationToolCandidateNames,
              requestedToolNames: preparedTurn.requestedToolNames,
            )
            : VerificationToolDiscoveryResult();

    return PreparedChatGeneration(
      userMessage: userMessage,
      messages: preparedTurn.messages,
      activatedSkills: preparedTurn.activatedSkills,
      activationAttempts: preparedTurn.activationAttempts,
      skillToolCalls: preparedTurn.skillToolCalls,
      preflightTokenUsage: preparedTurn.preflightTokenUsage,
      requestedToolNames: preparedTurn.requestedToolNames,
      verificationToolNames: verificationTools.toolNames,
      approvalExemptToolNames: preparedTurn.approvalExemptToolNames,
      runScopedTools: [
        ...historyTools,
        ...skillInventoryTools,
        ...mcpInventoryTools,
      ],
      contextAssemblyReport: preparedTurn.contextAssemblyReport,
      reliabilityPolicyEnabled: preparedTurn.reliabilityPolicyEnabled,
      verificationUnavailableReason: verificationTools.unavailableReason,
    );
  }
}
