import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_source_resolver.dart';
import 'package:stars/domain/models/models.dart';

const _skillUrl = 'https://www.modelscope.cn/skills/@AMap-Web/amap-lbs-skill';
const _collectionUrl =
    'https://www.modelscope.cn/collections/Tashanworld/keyanjinengbao';
const _installer =
    'curl -fsSL https://www.modelscope.cn/skills/install.sh | bash -s --';

void main() {
  late List<Uri> fetched;
  late SkillSourceResolver resolver;

  setUp(() {
    fetched = [];
    resolver = SkillSourceResolver(
      endpointPolicy: _publicPolicy(),
      fetcher: (uri, maxBytes, cancellation) async {
        fetched.add(uri);
        final page = int.parse(uri.queryParameters['PageNumber']!);
        return _page(
          total: 20,
          entries: [
            for (var index = (page - 1) * 10; index < page * 10; index++)
              _entry('skill-$index'),
          ],
        );
      },
    );
  });

  for (final source in [
    _skillUrl,
    '@AMap-Web/amap-lbs-skill',
    'npx skills add $_skillUrl',
    'npx -y skills@latest add "$_skillUrl" --yes --global --agent stars',
    '$_installer @AMap-Web/amap-lbs-skill',
    "curl --fail --silent --show-error --location 'https://modelscope.cn/skills/install.sh' | bash -s -- '@AMap-Web/amap-lbs-skill' --agent default",
  ]) {
    test('resolves a single ModelScope source: $source', () async {
      final results = await resolver.resolve(source, AgentCancellationToken());
      expect(results.single.toJson(), {
        'name': 'amap-lbs-skill',
        'source_type': 'zip_url',
        'source': '$_skillUrl/archive/zip/master',
      });
      expect(fetched, isEmpty);
    });
  }

  for (final source in [
    _collectionUrl,
    'npx skills add $_collectionUrl',
    '$_installer --collection Tashanworld/keyanjinengbao',
  ]) {
    test('resolves every collection page: $source', () async {
      final results = await resolver.resolve(source, AgentCancellationToken());
      expect(results, hasLength(20));
      expect(results.map((entry) => entry.name), [
        for (var index = 0; index < 20; index++) 'skill-$index',
      ]);
      expect(fetched.map((uri) => uri.queryParameters['PageNumber']), [
        '1',
        '2',
      ]);
      expect(
        fetched.first.queryParameters['Fid'],
        'Tashanworld/keyanjinengbao',
      );
      expect(
        results.last.source,
        endsWith('/skills/Tashanworld/skill-19/archive/zip/master'),
      );
    });
  }

  test('filters non-Skills and deduplicates collection entries', () async {
    final resolver = _resolverWithPages([
      _page(
        total: 4,
        entries: [
          _entry('alpha'),
          _entry('model', type: 'model'),
          _entry('alpha'),
          _entry('beta'),
        ],
      ),
    ]);
    final results = await resolver.resolve(
      _collectionUrl,
      AgentCancellationToken(),
    );
    expect(results.map((entry) => entry.name), ['alpha', 'beta']);
  });

  for (final (count, perPage) in [(25, 10), (235, 10), (205, 1)]) {
    test(
      'resolves $count entries across pages of $perPage without a count cap',
      () async {
        final pages = <int>[];
        final resolver = SkillSourceResolver(
          endpointPolicy: _publicPolicy(),
          fetcher: (uri, _, cancellation) async {
            final page = int.parse(uri.queryParameters['PageNumber']!);
            pages.add(page);
            return _page(
              total: count,
              entries: [
                for (
                  var i = (page - 1) * perPage;
                  i < page * perPage && i < count;
                  i++
                )
                  _entry('skill-$i'),
              ],
            );
          },
        );

        final results = await resolver.resolve(
          _collectionUrl,
          AgentCancellationToken(),
        );

        expect(results.map((entry) => entry.name), [
          for (var i = 0; i < count; i++) 'skill-$i',
        ]);
        expect(pages, [for (var i = 1; i <= (count / perPage).ceil(); i++) i]);
      },
    );
  }

  test('cancels a large collection without returning a partial list', () async {
    final token = AgentCancellationToken();
    var fetches = 0;
    final resolver = SkillSourceResolver(
      endpointPolicy: _publicPolicy(),
      fetcher: (_, _, _) async {
        fetches++;
        if (fetches == 3) token.cancel();
        return _page(total: 1000, entries: [_entry('skill-$fetches')]);
      },
    );

    await expectLater(
      resolver.resolve(_collectionUrl, token),
      throwsA(isA<AgentRunCancelledException>()),
    );
    expect(fetches, 3);
  });

  test(
    'rejects disagreement between collection and pagination totals',
    () async {
      final document =
          jsonDecode(utf8.decode(_page(total: 1, entries: [_entry('alpha')])))
              as Map;
      (document['Data'] as Map)['ElementCount'] = 25;
      await expectLater(
        _resolverWithPages([
          utf8.encode(jsonEncode(document)),
        ]).resolve(_collectionUrl, AgentCancellationToken()),
        throwsA(isA<SkillInstallException>()),
      );
    },
  );

  test(
    'multiple script IDs resolve once each without executing the script',
    () async {
      final results = await resolver.resolve(
        '$_installer @AMap-Web/amap-lbs-skill Tashanworld/experiment-design @AMap-Web/amap-lbs-skill',
        AgentCancellationToken(),
      );
      expect(results.map((entry) => entry.name), [
        'amap-lbs-skill',
        'experiment-design',
      ]);
      expect(fetched, isEmpty);
    },
  );

  test('preserves explicit GitHub ref and subdirectory', () async {
    final results = await resolver.resolve(
      'npx skills add https://github.com/acme/skills/tree/main/skills/reviewer',
      AgentCancellationToken(),
    );
    expect(results.single.toJson(), {
      'name': 'reviewer',
      'source_type': 'github',
      'source': 'https://github.com/acme/skills',
      'ref': 'main',
      'subdirectory': 'skills/reviewer',
    });
  });

  test(
    'retains GitHub shorthand, ZIP, and local installation choices',
    () async {
      for (final (source, type) in [
        ('acme/skills', 'github'),
        ('https://example.com/skill.zip?download=1', 'zip_url'),
        (
          File('${Directory.systemTemp.path}/skill.zip').absolute.path,
          'local_zip',
        ),
        (
          Directory('${Directory.systemTemp.path}/skill').absolute.path,
          'local_directory',
        ),
      ]) {
        final results = await resolver.resolve(
          source,
          AgentCancellationToken(),
        );
        expect(results.single.sourceType, type);
      }
      expect(fetched, isEmpty);
    },
  );

  for (final source in [
    'npx skills add $_skillUrl && echo unsafe',
    'npx skills add $_skillUrl; echo unsafe',
    r'npx skills add $(echo unsafe)',
    'npx skills add $_skillUrl --skill unknown',
    'npx skills add "$_skillUrl',
    'curl -fsSL https://example.com/install.sh | bash -s -- @AMap-Web/amap-lbs-skill',
    '$_installer @AMap-Web/amap-lbs-skill --token secret',
    '$_installer @AMap-Web/amap-lbs-skill | bash',
    '$_installer --collection owner/pack owner/extra',
    'https://www.modelscope.cn/skills/owner/%2Fprivate',
    'https://www.modelscope.cn/skills/owner/..',
    'https://www.modelscope.cn:8443/skills/owner/name',
    'https://user:secret@www.modelscope.cn/skills/owner/name',
    'http://www.modelscope.cn/skills/owner/name',
  ]) {
    test('rejects unsupported or unsafe source: $source', () async {
      await expectLater(
        resolver.resolve(source, AgentCancellationToken()),
        throwsA(isA<SkillInstallException>()),
      );
      expect(fetched, isEmpty);
    });
  }

  test('does not return a partial list when page two fails', () async {
    final resolver = _resolverWithPages([
      _page(total: 2, entries: [_entry('alpha')]),
      utf8.encode('{"Success":false,"Code":403}'),
    ]);
    await expectLater(
      resolver.resolve(_collectionUrl, AgentCancellationToken()),
      throwsA(isA<SkillInstallException>()),
    );
  });

  test('rejects repeated, missing, and changed pages', () async {
    for (final secondPage in [
      _page(total: 2, entries: [_entry('alpha')]),
      _page(total: 2, entries: []),
      _page(total: 3, entries: [_entry('beta')]),
    ]) {
      final resolver = _resolverWithPages([
        _page(total: 2, entries: [_entry('alpha')]),
        secondPage,
      ]);
      await expectLater(
        resolver.resolve(_collectionUrl, AgentCancellationToken()),
        throwsA(isA<SkillInstallException>()),
      );
    }
  });

  test(
    'rejects malformed, oversized, empty, and unsafe collection metadata',
    () async {
      for (final page in [
        utf8.encode('<html>Sign in</html>'),
        _page(total: -1, entries: [_entry('alpha')]),
        _page(total: 0, entries: []),
        _page(total: 1, entries: [_entry('../escape')]),
        List<int>.filled(SkillSourceResolver.maxMetadataBytes + 1, 32),
      ]) {
        await expectLater(
          _resolverWithPages([
            page,
          ]).resolve(_collectionUrl, AgentCancellationToken()),
          throwsA(isA<SkillInstallException>()),
        );
      }
    },
  );

  test(
    'validates metadata destinations before fetching and propagates cancellation',
    () async {
      var fetchCount = 0;
      final blocked = SkillSourceResolver(
        endpointPolicy: SkillCatalogEndpointPolicy(
          dnsLookup: (_) async => [InternetAddress.loopbackIPv4],
        ),
        fetcher: (_, _, _) async {
          fetchCount++;
          return [];
        },
      );
      await expectLater(
        blocked.resolve(_collectionUrl, AgentCancellationToken()),
        throwsA(isA<SkillInstallException>()),
      );
      expect(fetchCount, 0);
      final cancellation = AgentCancellationToken()..cancel();
      await expectLater(
        resolver.resolve(_collectionUrl, cancellation),
        throwsA(isA<AgentRunCancelledException>()),
      );
      expect(fetched, isEmpty);
    },
  );
}

SkillCatalogEndpointPolicy _publicPolicy() => SkillCatalogEndpointPolicy(
  dnsLookup: (_) async => [InternetAddress('8.8.8.8')],
);

SkillSourceResolver _resolverWithPages(List<List<int>> pages) {
  var index = 0;
  return SkillSourceResolver(
    endpointPolicy: _publicPolicy(),
    fetcher: (_, _, _) async => pages[index++],
  );
}

Map<String, Object?> _entry(String name, {String type = 'skill'}) => {
  'ElementType': type,
  'ElementPath': 'Tashanworld',
  'ElementName': name,
};

List<int> _page({
  required int total,
  required List<Map<String, Object?>> entries,
}) => utf8.encode(
  jsonEncode({
    'Success': true,
    'Code': 200,
    'Data': {
      'CollectionElements': {
        'Total': total,
        'CollectionElementVoList': entries,
      },
    },
  }),
);
