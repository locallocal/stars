import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const String starsApplicationDataDirectoryName = 'Stars';

/// Returns the app-specific directory used for all persistent Stars data.
///
/// Desktop document directories are shared by every application, so storing
/// generic names such as `app.db` or `chats` directly in their root lets an
/// unrelated application overwrite Stars data.
Future<Directory> getStarsApplicationDocumentsDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory(
    path.join(documents.path, starsApplicationDataDirectoryName),
  );
}
