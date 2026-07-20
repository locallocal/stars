import 'package:stars/domain/models/models.dart';

abstract interface class ProfileRepository {
  Stream<Profile> get changes;

  Future<Profile> getProfile();

  Future<void> updateProfile(Profile profile);
}
