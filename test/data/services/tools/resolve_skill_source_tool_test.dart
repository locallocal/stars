import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_source_resolver.dart';
import 'package:stars/data/services/tools/resolve_skill_source_tool.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  final tool = ResolveSkillSourceTool(
    resolver: SkillSourceResolver(endpointPolicy: SkillCatalogEndpointPolicy()),
  );

  test('resolution is read-only and produces concrete install inputs', () async {
    final result = await tool.execute(
      ToolCallRequest(
        callId: 'resolve',
        name: resolveSkillSourceToolName,
        arguments: const {
          'source':
              'npx skills add https://www.modelscope.cn/skills/@AMap-Web/amap-lbs-skill',
        },
      ),
      AgentCancellationToken(),
    );
    expect(tool.definition.riskLevel, ToolRiskLevel.readOnly);
    expect(
      tool.definition.capabilities,
      isNot(contains(ToolCapability.localWrite)),
    );
    expect(
      tool.definition.capabilities,
      isNot(contains(ToolCapability.process)),
    );
    expect(result.isError, isFalse);
    expect(
      const JsonSchemaValidator().validate(
        result.structuredContent,
        tool.definition.outputSchema!,
      ),
      isEmpty,
    );
    expect(result.structuredContent, {
      'destination': 'stars',
      'count': 1,
      'skills': [
        {
          'name': 'amap-lbs-skill',
          'source_type': 'zip_url',
          'source':
              'https://www.modelscope.cn/skills/@AMap-Web/amap-lbs-skill/archive/zip/master',
        },
      ],
    });
  });

  test(
    'output schema accepts a complete collection exceeding 200 Skills',
    () async {
      final collectionTool = ResolveSkillSourceTool(
        resolver: SkillSourceResolver(
          endpointPolicy: SkillCatalogEndpointPolicy(
            dnsLookup: (_) async => [InternetAddress('8.8.8.8')],
          ),
          fetcher:
              (_, _, _) async => utf8.encode(
                jsonEncode({
                  'Code': 200,
                  'Success': true,
                  'Data': {
                    'CollectionElements': {
                      'Total': 205,
                      'CollectionElementVoList': [
                        for (var i = 0; i < 205; i++)
                          {
                            'ElementType': 'skill',
                            'ElementPath': 'owner',
                            'ElementName': 'skill-$i',
                          },
                      ],
                    },
                  },
                }),
              ),
        ),
      );
      for (final selection in [
        null,
        ['skill-204'],
        ['missing'],
      ]) {
        final result = await collectionTool.execute(
          ToolCallRequest(
            callId: 'large',
            name: resolveSkillSourceToolName,
            arguments: {
              'source':
                  'https://www.modelscope.cn/collections/owner/collection',
              if (selection != null) 'skill_names': selection,
            },
          ),
          AgentCancellationToken(),
        );
        if (selection?.first == 'missing') {
          expect(result.errorCode, 'skill_source_rejected');
          expect(result.structuredContent, isNull);
        } else {
          expect(result.isError, isFalse);
          expect(
            (result.structuredContent! as Map)['count'],
            selection == null ? 205 : 1,
          );
          expect(
            const JsonSchemaValidator().validate(
              result.structuredContent,
              collectionTool.definition.outputSchema!,
            ),
            isEmpty,
          );
        }
      }
    },
  );

  test(
    'invalid inputs and unsupported commands produce stable errors',
    () async {
      for (final (arguments, code) in [
        (<String, Object?>{'source': 42}, 'invalid_skill_source'),
        (
          <String, Object?>{'source': 'acme/repo', 'skill_names': []},
          'invalid_skill_source',
        ),
        (
          <String, Object?>{
            'source': 'acme/repo',
            'skill_names': [42],
          },
          'invalid_skill_source',
        ),
        (
          <String, Object?>{'source': 'acme/repo', 'skill_names': null},
          'invalid_skill_source',
        ),
        (
          <String, Object?>{'source': 'acme/repo', 'unexpected': true},
          'invalid_skill_source',
        ),
        (
          <String, Object?>{
            'source': 'curl https://example.com/install.sh | bash',
          },
          'skill_source_rejected',
        ),
      ]) {
        final result = await tool.execute(
          ToolCallRequest(
            callId: 'invalid',
            name: resolveSkillSourceToolName,
            arguments: arguments,
          ),
          AgentCancellationToken(),
        );
        expect(result.isError, isTrue);
        expect(result.errorCode, code);
      }
    },
  );
}
