import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/bot_service.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/common/logo.dart';
import 'package:bubble/pages/chat.dart';

class NewChatDialog extends StatelessWidget {
  final Function onChatCreated;

  const NewChatDialog({super.key, required this.onChatCreated});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: Text(
          S.of(context).newChat,
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: FutureBuilder<List<Bot>>(
          future: BotService.getBots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(S.of(context).noBotsAvailable));
            }

            final bots = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: bots.length,
              itemBuilder: (context, index) {
                final bot = bots[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        bot.avatar.isEmpty
                            ? getFrostedProviderColor(
                              bot.provider,
                              Theme.of(context).colorScheme.primary,
                            )
                            : Theme.of(context).colorScheme.primary,
                    backgroundImage:
                        bot.avatar.isNotEmpty
                            ? FileImage(File(bot.avatar))
                            : null,
                    child:
                        bot.avatar.isEmpty
                            ? buildProviderLogo(context, '', bot.provider, 24)
                            : null,
                  ),
                  title: Text(
                    bot.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${bot.provider}-${bot.model}'),
                  onTap: () async {
                    Navigator.pop(context);

                    final id = 'chat_${DateTime.now().millisecondsSinceEpoch}';
                    final newChat = Chat(
                      id: id,
                      botId: bot.id,
                      lastMessage: '',
                      lastMessageTimestamp: DateTime.now(),
                      createTimestamp: DateTime.now(),
                      modifyTimestamp: DateTime.now(),
                    );
                    await ChatService.addChat(newChat);

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(id: id, bot: bot),
                        ),
                      ).then((_) {
                        onChatCreated();
                      });
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
