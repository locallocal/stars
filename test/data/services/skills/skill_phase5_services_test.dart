import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/skills/linux_bubblewrap_skill_sandbox.dart';
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_catalog_service.dart';
import 'package:stars/data/services/skills/skill_organization_policy_bundle_service.dart';
import 'package:stars/data/services/skills/skill_script_catalog_service.dart';
import 'package:stars/data/services/skills/skill_script_manifest_parser.dart';
import 'package:stars/data/services/skills/skill_signature_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/skill_ecosystem_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/repositories/skill_script_sandbox.dart';

void main() {
  group('SkillSignatureService', () {
    test('verifies the detached Ed25519 content signature', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars-signature-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final keyPair = await Ed25519().newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      const digest = 'abc123';
      const name = 'signed-skill';
      const version = '1.2.0';
      final signature = await Ed25519().sign(
        utf8.encode(
          SkillSignatureService.signingPayload(
            publisherId: 'publisher-1',
            keyId: 'key-1',
            contentDigest: digest,
            skillName: name,
            version: version,
          ),
        ),
        keyPair: keyPair,
      );
      await File('${directory.path}/SIGNATURE.json').writeAsString(
        jsonEncode({
          'publisherId': 'publisher-1',
          'keyId': 'key-1',
          'algorithm': 'ed25519',
          'signature': base64Encode(signature.bytes),
        }),
      );
      final repository = _MemoryEcosystemRepository(
        publisher: SkillPublisher(
          id: 'publisher-1',
          name: 'Publisher',
          keyId: 'key-1',
          publicKey: base64Encode(publicKey.bytes),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );

      final result = await SkillSignatureService(
        ecosystemRepository: repository,
      ).verify(
        skillRoot: directory,
        contentDigest: digest,
        skillName: name,
        version: version,
      );

      expect(result.status, SkillSignatureStatus.verified);
      expect(result.publisherName, 'Publisher');
    });

    test('rejects a signature when the content digest changes', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars-signature-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final keyPair = await Ed25519().newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final signature = await Ed25519().sign(
        utf8.encode(
          SkillSignatureService.signingPayload(
            publisherId: 'publisher-1',
            keyId: 'key-1',
            contentDigest: 'old',
            skillName: 'signed-skill',
            version: '1.0.0',
          ),
        ),
        keyPair: keyPair,
      );
      await File('${directory.path}/SIGNATURE.json').writeAsString(
        jsonEncode({
          'publisherId': 'publisher-1',
          'keyId': 'key-1',
          'algorithm': 'ed25519',
          'signature': base64Encode(signature.bytes),
        }),
      );
      final repository = _MemoryEcosystemRepository(
        publisher: SkillPublisher(
          id: 'publisher-1',
          name: 'Publisher',
          keyId: 'key-1',
          publicKey: base64Encode(publicKey.bytes),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );

      final result = await SkillSignatureService(
        ecosystemRepository: repository,
      ).verify(
        skillRoot: directory,
        contentDigest: 'new',
        skillName: 'signed-skill',
        version: '1.0.0',
      );

      expect(result.status, SkillSignatureStatus.invalid);
    });
  });

  group('SkillScriptManifestParser', () {
    test('parses only controlled scripts entries and capabilities', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars-manifest-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory('${directory.path}/scripts').create();
      await File(
        '${directory.path}/scripts/transform.py',
      ).writeAsString('print("{}")');
      await File('${directory.path}/scripts/tools.json').writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'tools': [
            {
              'name': 'transform',
              'description': 'Transform structured input.',
              'entry': 'scripts/transform.py',
              'interpreter': 'python3',
              'inputSchema': {'type': 'object'},
              'outputSchema': {'type': 'object'},
              'capabilities': ['compute'],
            },
          ],
        }),
      );

      final manifests = await const SkillScriptManifestParser().parse(
        _skill(directory.path),
      );

      expect(manifests.single.name, 'skill.example.transform');
      expect(manifests.single.entry, 'scripts/transform.py');
      expect(
        manifests.single.capabilities,
        containsAll([ToolCapability.compute, ToolCapability.process]),
      );
    });

    test('rejects script traversal and network capability', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars-manifest-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory('${directory.path}/scripts').create();
      await File(
        '${directory.path}/scripts/transform.py',
      ).writeAsString('print("{}")');
      await File('${directory.path}/scripts/tools.json').writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'tools': [
            {
              'name': 'unsafe',
              'entry': 'scripts/../outside.py',
              'interpreter': 'python3',
              'inputSchema': {'type': 'object'},
              'capabilities': ['network'],
            },
          ],
        }),
      );

      expect(
        () => const SkillScriptManifestParser().parse(_skill(directory.path)),
        throwsA(isA<SkillInstallException>()),
      );
    });
  });

  test('sandbox fails closed when a required helper is missing', () async {
    final status =
        await LinuxBubblewrapSkillSandbox(
          bubblewrapPath: '/definitely/missing/bwrap',
          prlimitPath: '/definitely/missing/prlimit',
          installationVerifier: (_, _) async {},
        ).probe();

    expect(status.availability, SkillSandboxAvailability.helperUnavailable);
  });

  test('catalog endpoint policy rejects DNS resolving to private IP', () async {
    final policy = SkillCatalogEndpointPolicy(
      dnsLookup: (_) async => [InternetAddress('192.168.1.10')],
    );

    expect(
      () => policy.validate(Uri.parse('https://catalog.example/index.json')),
      throwsA(isA<SkillInstallException>()),
    );
  });

  test('refreshes only a valid signed HTTPS catalog index', () async {
    final archiveDigest = List.filled(64, 'a').join();
    final contentDigest = List.filled(64, 'b').join();
    final keyPair = await Ed25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final ecosystem = _MemoryEcosystemRepository(
      publisher: SkillPublisher(
        id: 'publisher-1',
        name: 'Publisher',
        keyId: 'catalog-key',
        publicKey: base64Encode(publicKey.bytes),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    final unsigned = <String, Object?>{
      'schemaVersion': 1,
      'publisherId': 'publisher-1',
      'keyId': 'catalog-key',
      'algorithm': 'ed25519',
      'entries': [
        {
          'id': 'example',
          'name': 'example',
          'description': 'Example',
          'version': '2.0.0',
          'publisherId': 'publisher-1',
          'archiveUrl': 'https://cdn.example/example.zip',
          'archiveSha256': archiveDigest,
          'contentSha256': contentDigest,
        },
      ],
    };
    final signature = await Ed25519().sign(
      utf8.encode(canonicalSkillJson(unsigned)),
      keyPair: keyPair,
    );
    final indexBytes = utf8.encode(
      jsonEncode({...unsigned, 'signature': base64Encode(signature.bytes)}),
    );
    final service = SkillCatalogService(
      ecosystemRepository: ecosystem,
      skillRepository: _FakeSkillRepository(
        _skill(
          '/tmp/example',
          catalogId: 'catalog-1',
          catalogEntryId: 'example',
        ),
      ),
      endpointPolicy: SkillCatalogEndpointPolicy(
        dnsLookup: (_) async => [InternetAddress('93.184.216.34')],
      ),
      fetcher: (_, _) async => indexBytes,
    );

    final entries = await service.refresh(
      SkillCatalogSource(
        id: 'catalog-1',
        name: 'Catalog',
        indexUri: Uri.parse('https://catalog.example/index.json'),
        publisherId: 'publisher-1',
      ),
    );

    expect(entries.single.version, '2.0.0');
    expect(entries.single.archiveDigest, archiveDigest);
    expect((await service.availableUpdates()).single.version, '2.0.0');
    expect(
      ecosystem.events.single.type,
      SkillComplianceEventType.catalogRefreshed,
    );
  });

  for (final validDigest in [true, false]) {
    test(
      'catalog downloads over 20 MB still verify integrity (valid: $validDigest)',
      () async {
        final payload = Uint8List(21 * 1024 * 1024);
        final repository = _FakeSkillRepository(_skill('/tmp/example'));
        final service = SkillCatalogService(
          ecosystemRepository: _MemoryEcosystemRepository(),
          skillRepository: repository,
          endpointPolicy: SkillCatalogEndpointPolicy(
            dnsLookup: (_) async => [InternetAddress('8.8.8.8')],
          ),
          fetcher: (_, limit) async {
            expect(limit, isNull);
            return payload;
          },
        );
        final entry = OnlineSkillCatalogEntry(
          id: 'example',
          catalogId: 'catalog-1',
          name: 'example',
          description: 'Example',
          version: '2.0.0',
          publisherId: 'publisher-1',
          archiveUri: Uri.parse('https://cdn.example/example.zip'),
          archiveDigest:
              validDigest
                  ? crypto.sha256.convert(payload).toString()
                  : '0' * 64,
          contentDigest: 'b' * 64,
        );

        if (validDigest) {
          await service.install(entry);
          expect(repository.archiveBytes, payload.length);
          expect(repository.source?.expectedArchiveDigest, entry.archiveDigest);
          expect(repository.source?.expectedContentDigest, entry.contentDigest);
          expect(await File(repository.source!.path).parent.exists(), isFalse);
        } else {
          await expectLater(
            service.install(entry),
            throwsA(isA<SkillInstallException>()),
          );
          expect(repository.source, isNull);
        }
      },
    );
  }

  test(
    'explicit digest grant registers and executes a sandboxed script tool',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars-script-catalog-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory('${directory.path}/scripts').create();
      await File(
        '${directory.path}/scripts/transform.py',
      ).writeAsString('print("{}")');
      await File('${directory.path}/scripts/tools.json').writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'tools': [
            {
              'name': 'transform',
              'description': 'Transform input.',
              'entry': 'scripts/transform.py',
              'interpreter': 'python3',
              'inputSchema': {'type': 'object'},
              'outputSchema': {'type': 'object'},
            },
          ],
        }),
      );
      final skill = _skill(directory.path);
      final ecosystem = _MemoryEcosystemRepository();
      final registry = DynamicToolRegistry(const []);
      final service = SkillScriptCatalogService(
        skillRepository: _FakeSkillRepository(skill),
        ecosystemRepository: ecosystem,
        manifestParser: const SkillScriptManifestParser(),
        sandbox: const _FakeSandbox(),
        toolRegistry: registry,
      );

      await service.setEnabled(skill, true);
      final tool = registry.find('skill.example.transform');
      final result = await tool!.execute(
        ToolCallRequest(
          callId: 'call-1',
          name: tool.definition.name,
          arguments: const {'value': 'hello'},
        ),
        AgentCancellationToken(),
      );

      expect(await service.isEnabled(skill), isTrue);
      expect(result.structuredContent, {'ok': true, 'api_token': '[redacted]'});
      expect(
        ecosystem.events.map((event) => event.type),
        containsAll(<SkillComplianceEventType>[
          SkillComplianceEventType.scriptEnabled,
          SkillComplianceEventType.scriptExecuted,
        ]),
      );
    },
  );

  test('imports a signed organization policy bundle', () async {
    final keyPair = await Ed25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final repository = _MemoryEcosystemRepository(
      publisher: SkillPublisher(
        id: 'organization',
        name: 'Organization',
        keyId: 'policy-key',
        publicKey: base64Encode(publicKey.bytes),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    final unsigned = <String, Object?>{
      'schemaVersion': 1,
      'publisherId': 'organization',
      'keyId': 'policy-key',
      'algorithm': 'ed25519',
      'policy': {
        'allowUnsignedSkills': false,
        'allowUnknownPublishers': false,
        'allowScriptExecution': true,
        'allowAutomaticUpdates': false,
        'allowedPublisherIds': ['organization'],
      },
    };
    final signature = await Ed25519().sign(
      utf8.encode(canonicalSkillJson(unsigned)),
      keyPair: keyPair,
    );

    final policy = await SkillOrganizationPolicyBundleService(
      ecosystemRepository: repository,
    ).importSigned(
      jsonEncode({...unsigned, 'signature': base64Encode(signature.bytes)}),
    );

    expect(policy.allowUnsignedSkills, isFalse);
    expect(repository.policy?.allowedPublisherIds, {'organization'});
    expect(
      repository.events.single.type,
      SkillComplianceEventType.policyChanged,
    );
  });
}

SkillDescriptor _skill(
  String rootPath, {
  String catalogId = '',
  String catalogEntryId = '',
}) => SkillDescriptor(
  id: 'user:example',
  name: 'example',
  description: 'Example',
  version: '1.0.0',
  scope: SkillScope.user,
  sourceUri: Uri.file(rootPath).toString(),
  rootPath: rootPath,
  contentDigest: 'digest',
  trustState: SkillTrustState.userReviewed,
  validationStatus: SkillValidationStatus.valid,
  compatibility: '',
  requestedToolNames: const {'skill.example.transform'},
  hasScripts: true,
  catalogId: catalogId,
  catalogEntryId: catalogEntryId,
  installedAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final class _MemoryEcosystemRepository implements SkillEcosystemRepository {
  _MemoryEcosystemRepository({this.publisher});

  final SkillPublisher? publisher;
  SkillOrganizationPolicy? policy;
  final List<SkillComplianceEvent> events = [];
  SkillScriptGrant? grant;

  @override
  Future<void> appendComplianceEvent(SkillComplianceEvent event) async {
    events.add(event);
  }

  @override
  Future<void> deleteScriptGrant(String skillId) async {}

  @override
  Future<List<SkillCatalogSource>> getCatalogs() async => const [];

  @override
  Future<List<SkillComplianceEvent>> getComplianceEvents({
    String? skillId,
    int limit = 100,
  }) async => List.unmodifiable(events);

  @override
  Future<SkillOrganizationPolicy> getOrganizationPolicy() async =>
      policy ?? SkillOrganizationPolicy.defaults;

  @override
  Future<SkillPublisher?> getPublisher(String publisherId) async =>
      publisher?.id == publisherId ? publisher : null;

  @override
  Future<List<SkillPublisher>> getPublishers() async =>
      publisher == null ? const [] : [publisher!];

  @override
  Future<SkillScriptGrant?> getScriptGrant(String skillId) async =>
      grant?.skillId == skillId ? grant : null;

  @override
  Future<void> saveCatalog(SkillCatalogSource catalog) async {}

  @override
  Future<void> saveOrganizationPolicy(SkillOrganizationPolicy policy) async {
    this.policy = policy;
  }

  @override
  Future<void> savePublisher(SkillPublisher publisher) async {}

  @override
  Future<void> saveScriptGrant(SkillScriptGrant grant) async {
    this.grant = grant;
  }

  @override
  Future<void> setSkillUpdatePolicy(
    String skillId,
    SkillUpdatePolicy policy,
  ) async {}
}

final class _FakeSkillRepository implements SkillRepository {
  _FakeSkillRepository(this.skill);

  final SkillDescriptor skill;
  SkillImportSource? source;
  int? archiveBytes;

  @override
  Stream<List<SkillDescriptor>> get changes => const Stream.empty();

  @override
  Future<SkillDescriptor?> getById(String id) async =>
      id == skill.id ? skill : null;

  @override
  Future<List<SkillDescriptor>> getInstalled({
    bool forceRefresh = false,
  }) async => [skill];

  @override
  Future<SkillDescriptor> install(SkillImportSource source) async {
    this.source = source;
    archiveBytes = await File(source.path).length();
    return skill;
  }

  @override
  Future<SkillContent> load(String skillId, {String? contentDigest}) =>
      throw UnimplementedError();

  @override
  Future<SkillResourceContent> readResource(
    String skillId,
    String relativePath, {
    String? contentDigest,
  }) => throw UnimplementedError();

  @override
  Future<void> uninstall(String skillId) => throw UnimplementedError();
}

final class _FakeSandbox implements SkillScriptSandbox {
  const _FakeSandbox();

  @override
  Future<SkillScriptExecutionResult> execute(
    SkillScriptExecutionRequest request,
    AgentCancellationToken cancellationToken,
  ) async {
    return const SkillScriptExecutionResult(
      exitCode: 0,
      stdout: '{"ok":true,"api_token":"do-not-persist"}',
      stderr: '',
      duration: Duration(milliseconds: 2),
    );
  }

  @override
  Future<SkillSandboxStatus> probe() async => const SkillSandboxStatus(
    availability: SkillSandboxAvailability.available,
  );
}
