import 'package:stars/domain/models/models.dart';

abstract interface class BotRepository {
  Stream<List<Bot>> get changes;

  Future<List<Bot>> getBots({bool forceRefresh = false});

  Future<Bot?> getBot(String id);

  Future<void> addBot(Bot bot);

  Future<void> updateBot(Bot bot);

  Future<void> deleteBot(String id);
}
