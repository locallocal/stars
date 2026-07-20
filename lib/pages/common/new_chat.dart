import 'package:stars/model/model.dart';
import 'package:stars/domain/use_cases/create_chat.dart';

@Deprecated('Inject and call the CreateChat use case directly.')
Future<Chat> createNewChat(Bot bot, {required CreateChat createChat}) =>
    createChat(bot);
