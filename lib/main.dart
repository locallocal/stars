import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/ui/core/dependency_injection/app_dependencies.dart';
import 'package:stars/ui/features/app/views/stars_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }
  intl.Intl.defaultLocale = 'zh';
  runApp(StarsBootstrapApp(dependencies: AppDependencies.production()));
}
