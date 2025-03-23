// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that looks up messages for specific locales by
// delegating to the appropriate library.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:implementation_imports, file_names, unnecessary_new
// ignore_for_file:unnecessary_brace_in_string_interps, directives_ordering
// ignore_for_file:argument_type_not_assignable, invalid_assignment
// ignore_for_file:prefer_single_quotes, prefer_generic_function_type_aliases
// ignore_for_file:comment_references

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

import 'messages_de_DE.dart' as messages_de_de;
import 'messages_en.dart' as messages_en;
import 'messages_es_ES.dart' as messages_es_es;
import 'messages_fr_FR.dart' as messages_fr_fr;
import 'messages_hi_IN.dart' as messages_hi_in;
import 'messages_it_IT.dart' as messages_it_it;
import 'messages_ja_JP.dart' as messages_ja_jp;
import 'messages_ko_KR.dart' as messages_ko_kr;
import 'messages_pt_BR.dart' as messages_pt_br;
import 'messages_ru_RU.dart' as messages_ru_ru;
import 'messages_zh_CN.dart' as messages_zh_cn;
import 'messages_zh_TW.dart' as messages_zh_tw;

typedef Future<dynamic> LibraryLoader();
Map<String, LibraryLoader> _deferredLibraries = {
  'de_DE': () => new SynchronousFuture(null),
  'en': () => new SynchronousFuture(null),
  'es_ES': () => new SynchronousFuture(null),
  'fr_FR': () => new SynchronousFuture(null),
  'hi_IN': () => new SynchronousFuture(null),
  'it_IT': () => new SynchronousFuture(null),
  'ja_JP': () => new SynchronousFuture(null),
  'ko_KR': () => new SynchronousFuture(null),
  'pt_BR': () => new SynchronousFuture(null),
  'ru_RU': () => new SynchronousFuture(null),
  'zh_CN': () => new SynchronousFuture(null),
  'zh_TW': () => new SynchronousFuture(null),
};

MessageLookupByLibrary? _findExact(String localeName) {
  switch (localeName) {
    case 'de_DE':
      return messages_de_de.messages;
    case 'en':
      return messages_en.messages;
    case 'es_ES':
      return messages_es_es.messages;
    case 'fr_FR':
      return messages_fr_fr.messages;
    case 'hi_IN':
      return messages_hi_in.messages;
    case 'it_IT':
      return messages_it_it.messages;
    case 'ja_JP':
      return messages_ja_jp.messages;
    case 'ko_KR':
      return messages_ko_kr.messages;
    case 'pt_BR':
      return messages_pt_br.messages;
    case 'ru_RU':
      return messages_ru_ru.messages;
    case 'zh_CN':
      return messages_zh_cn.messages;
    case 'zh_TW':
      return messages_zh_tw.messages;
    default:
      return null;
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName) {
  var availableLocale = Intl.verifiedLocale(
    localeName,
    (locale) => _deferredLibraries[locale] != null,
    onFailure: (_) => null,
  );
  if (availableLocale == null) {
    return new SynchronousFuture(false);
  }
  var lib = _deferredLibraries[availableLocale];
  lib == null ? new SynchronousFuture(false) : lib();
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, _findGeneratedMessagesFor);
  return new SynchronousFuture(true);
}

bool _messagesExistFor(String locale) {
  try {
    return _findExact(locale) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary? _findGeneratedMessagesFor(String locale) {
  var actualLocale = Intl.verifiedLocale(
    locale,
    _messagesExistFor,
    onFailure: (_) => null,
  );
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
