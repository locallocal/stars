import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/profile_repository.dart';

class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository({required LocalDatabaseService localDatabase})
    : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;
  final StreamController<Profile> _changes =
      StreamController<Profile>.broadcast();
  Profile? _cache;

  @override
  Stream<Profile> get changes => _changes.stream;

  @override
  Future<Profile> getProfile() async {
    final cached = _cache;
    if (cached != null) return cached;

    final records = await _localDatabase.loadProfiles();
    if (records.isEmpty) {
      final now = DateTime.now();
      final profile = Profile(
        name: '用户名',
        avatar: '',
        fontSize: 16,
        themeMode: 0,
        language: 'zh_CN',
        showExecutionStatus: true,
        createTimestamp: now,
        modifyTimestamp: now,
      );
      await _localDatabase.insertProfile(
        ProfileRecord.fromDomain(profile).values,
      );
      _cache = profile;
      return profile;
    }

    _cache = ProfileRecord(records.first).toDomain();
    return _cache!;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    final records = await _localDatabase.loadProfiles();
    final values = ProfileRecord.fromDomain(profile).values;
    if (records.isEmpty) {
      await _localDatabase.insertProfile(values);
    } else {
      await _localDatabase.updateProfile(records.first['id']!, values);
    }
    _cache = profile;
    if (!_changes.isClosed) _changes.add(profile);
  }

  @visibleForTesting
  Future<void> dispose() => _changes.close();
}
