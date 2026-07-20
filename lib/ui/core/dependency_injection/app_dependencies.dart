import 'package:stars/data/repositories/feedback_repository_impl.dart';
import 'package:stars/data/repositories/sqlite_bot_repository.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_profile_repository.dart';
import 'package:stars/data/services/feedback_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/feedback_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/domain/use_cases/create_chat.dart';
import 'package:stars/services/chat_generation_controller.dart';
import 'package:stars/services/database_service.dart';
import 'package:stars/ui/features/app/view_models/app_view_model.dart';
import 'package:stars/ui/features/app/view_models/main_shell_view_model.dart';
import 'package:stars/ui/features/app/view_models/startup_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_list_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_view_model.dart';
import 'package:stars/ui/features/chats/view_models/chat_list_view_model.dart';
import 'package:stars/ui/features/chats/view_models/new_chat_view_model.dart';
import 'package:stars/ui/features/feedback/view_models/feedback_view_model.dart';
import 'package:stars/ui/features/profile/view_models/profile_view_model.dart';

/// Application composition root. Production implementations are assembled in
/// one place; views only receive repositories through their ViewModels.
class AppDependencies {
  AppDependencies({
    required this.botRepository,
    required this.chatRepository,
    required this.messageRepository,
    required this.profileRepository,
    required this.feedbackRepository,
    required this.createChat,
    required this.generationRegistry,
  });

  factory AppDependencies.production() {
    final localDatabase = LocalDatabaseService(
      databaseProvider: () => DatabaseService.database,
    );
    final chatRepository = SqliteChatRepository(localDatabase: localDatabase);
    final messageRepository = SqliteMessageRepository(
      localDatabase: localDatabase,
    );
    final botRepository = SqliteBotRepository(
      localDatabase: localDatabase,
      chatRepository: chatRepository,
    );
    final profileRepository = SqliteProfileRepository(
      localDatabase: localDatabase,
    );
    final feedbackRepository = FeedbackRepositoryImpl(
      service: const FeedbackService(),
    );
    return AppDependencies(
      botRepository: botRepository,
      chatRepository: chatRepository,
      messageRepository: messageRepository,
      profileRepository: profileRepository,
      feedbackRepository: feedbackRepository,
      createChat: CreateChat(chatRepository: chatRepository),
      generationRegistry: ChatGenerationRegistry(
        messagePersister: messageRepository.upsertMessage,
        lastMessageUpdater: chatRepository.updateLastMessage,
        messageIdFactory: messageRepository.createId,
      ),
    );
  }

  final BotRepository botRepository;
  final ChatRepository chatRepository;
  final MessageRepository messageRepository;
  final ProfileRepository profileRepository;
  final FeedbackRepository feedbackRepository;
  final CreateChat createChat;
  final ChatGenerationRegistry generationRegistry;

  StartupViewModel createStartupViewModel() =>
      StartupViewModel(profileRepository: profileRepository);

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

  BotListViewModel createBotListViewModel() =>
      BotListViewModel(botRepository: botRepository, createChat: createChat);

  ProfileViewModel createProfileViewModel() =>
      ProfileViewModel(profileRepository: profileRepository);

  FeedbackViewModel createFeedbackViewModel() =>
      FeedbackViewModel(feedbackRepository: feedbackRepository);

  NewChatViewModel createNewChatViewModel() =>
      NewChatViewModel(botRepository: botRepository, createChat: createChat);

  ChatViewModel createChatViewModel(String chatId, Bot bot) => ChatViewModel(
    chatId: chatId,
    bot: bot,
    messageRepository: messageRepository,
    chatRepository: chatRepository,
    generationRegistry: generationRegistry,
  );
}
