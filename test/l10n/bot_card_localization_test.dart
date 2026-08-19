import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/generated/l10n.dart';

void main() {
  final expected = <
    Locale,
    ({
      String details,
      String edit,
      String delete,
      String searchBots,
      String basicInformation,
      String modelContextWindow,
      String tokenUsage,
    })
  >{
    Locale('en', 'US'): (
      details: 'Details',
      edit: 'Edit',
      delete: 'Delete',
      searchBots: 'Search bots',
      basicInformation: 'Basic Information',
      modelContextWindow: 'Model Context Size',
      tokenUsage: 'Token usage',
    ),
    Locale('zh', 'CN'): (
      details: '详情',
      edit: '编辑',
      delete: '删除',
      searchBots: '搜索智能体',
      basicInformation: '基本信息',
      modelContextWindow: '模型上下文大小',
      tokenUsage: 'Token 用量',
    ),
    Locale('zh', 'TW'): (
      details: '詳情',
      edit: '編輯',
      delete: '刪除',
      searchBots: '搜尋智能體',
      basicInformation: '基本資訊',
      modelContextWindow: '模型上下文大小',
      tokenUsage: 'Token 用量',
    ),
    Locale('ja', 'JP'): (
      details: '詳細',
      edit: '編集',
      delete: '削除',
      searchBots: 'ボットを検索',
      basicInformation: '基本情報',
      modelContextWindow: 'モデルのコンテキストサイズ',
      tokenUsage: 'トークン使用量',
    ),
    Locale('fr', 'FR'): (
      details: 'Détails',
      edit: 'Modifier',
      delete: 'Supprimer',
      searchBots: 'Rechercher des bots',
      basicInformation: 'Informations générales',
      modelContextWindow: 'Taille du contexte du modèle',
      tokenUsage: 'Utilisation des jetons',
    ),
    Locale('de', 'DE'): (
      details: 'Details',
      edit: 'Bearbeiten',
      delete: 'Löschen',
      searchBots: 'Bots durchsuchen',
      basicInformation: 'Grundlegende Informationen',
      modelContextWindow: 'Modellkontextgröße',
      tokenUsage: 'Token-Nutzung',
    ),
    Locale('ko', 'KR'): (
      details: '세부 정보',
      edit: '편집',
      delete: '삭제',
      searchBots: '봇 검색',
      basicInformation: '기본 정보',
      modelContextWindow: '모델 컨텍스트 크기',
      tokenUsage: '토큰 사용량',
    ),
    Locale('ru', 'RU'): (
      details: 'Сведения',
      edit: 'Редактировать',
      delete: 'Удалить',
      searchBots: 'Поиск ботов',
      basicInformation: 'Основная информация',
      modelContextWindow: 'Размер контекста модели',
      tokenUsage: 'Использование токенов',
    ),
    Locale('es', 'ES'): (
      details: 'Detalles',
      edit: 'Editar',
      delete: 'Eliminar',
      searchBots: 'Buscar bots',
      basicInformation: 'Información básica',
      modelContextWindow: 'Tamaño del contexto del modelo',
      tokenUsage: 'Uso de tokens',
    ),
    Locale('hi', 'IN'): (
      details: 'विवरण',
      edit: 'संपादित करें',
      delete: 'हटाएं',
      searchBots: 'बॉट खोजें',
      basicInformation: 'मूल जानकारी',
      modelContextWindow: 'मॉडल कॉन्टेक्स्ट आकार',
      tokenUsage: 'टोकन उपयोग',
    ),
    Locale('pt', 'BR'): (
      details: 'Detalhes',
      edit: 'Editar',
      delete: 'Excluir',
      searchBots: 'Pesquisar bots',
      basicInformation: 'Informações básicas',
      modelContextWindow: 'Tamanho do contexto do modelo',
      tokenUsage: 'Uso de tokens',
    ),
    Locale('it', 'IT'): (
      details: 'Dettagli',
      edit: 'Modifica',
      delete: 'Elimina',
      searchBots: 'Cerca bot',
      basicInformation: 'Informazioni di base',
      modelContextWindow: 'Dimensione del contesto del modello',
      tokenUsage: 'Utilizzo dei token',
    ),
  };

  test('every locale defines the Bot card and detail messages', () {
    for (final locale in expected.keys) {
      final fileName =
          locale.languageCode == 'en'
              ? 'intl_en.arb'
              : locale.languageCode == 'it'
              ? 'intl_it_IT.arb'
              : 'intl_${locale.languageCode}_${locale.countryCode}.arb';
      final messages =
          jsonDecode(File('lib/l10n/$fileName').readAsStringSync())
              as Map<String, dynamic>;

      for (final key in [
        'details',
        'startChatting',
        'edit',
        'delete',
        'searchBots',
        'basicInformation',
        'modelContextWindow',
        'modelInputModalities',
        'modelOutputModalities',
        'supportsSkills',
        'supportsMcp',
        'tokenUsage',
        'totalTokens',
        'noTokenUsageRecorded',
      ]) {
        expect(
          messages[key],
          isA<String>().having(
            (value) => value.trim(),
            'trimmed value',
            isNotEmpty,
          ),
          reason: '$fileName is missing $key',
        );
      }
    }
  });

  test(
    'generated Bot card and detail messages load for every locale',
    () async {
      for (final entry in expected.entries) {
        await S.load(entry.key);
        expect(
          S.current.details,
          entry.value.details,
          reason: entry.key.toString(),
        );
        expect(S.current.edit, entry.value.edit, reason: entry.key.toString());
        expect(
          S.current.delete,
          entry.value.delete,
          reason: entry.key.toString(),
        );
        expect(
          S.current.searchBots,
          entry.value.searchBots,
          reason: entry.key.toString(),
        );
        expect(
          S.current.basicInformation,
          entry.value.basicInformation,
          reason: entry.key.toString(),
        );
        expect(
          S.current.modelContextWindow,
          entry.value.modelContextWindow,
          reason: entry.key.toString(),
        );
        expect(
          S.current.tokenUsage,
          entry.value.tokenUsage,
          reason: entry.key.toString(),
        );
        expect(S.current.startChatting.trim(), isNotEmpty);
      }
    },
  );
}
