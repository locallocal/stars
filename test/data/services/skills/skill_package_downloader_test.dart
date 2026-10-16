import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_package_downloader.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  late Directory temporary;
  final uri = Uri.parse('https://skills.example/package.zip');
  final policy = SkillCatalogEndpointPolicy(
    dnsLookup: (_) async => [InternetAddress('8.8.8.8')],
  );

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('skill-download-test-');
  });
  tearDown(() => temporary.delete(recursive: true));

  for (final contentLength in [-1, 21 * 1024 * 1024]) {
    test(
      'streams packages over 20 MB with content-length $contentLength',
      () async {
        final chunk = Uint8List(64 * 1024)..last = 42;
        final client = _Client(
          _Response(
            Stream<List<int>>.fromIterable(
              Iterable.generate(336, (_) => chunk),
            ),
            contentLength: contentLength,
          ),
        );
        final downloader = SkillPackageDownloader(
          endpointPolicy: policy,
          httpClientFactory: () => client,
        );
        final destination = File('${temporary.path}/package.zip');

        await downloader.downloadToFile(
          uri,
          destination,
          AgentCancellationToken(),
        );

        expect(await destination.length(), 21 * 1024 * 1024);
        final file = await destination.open();
        try {
          await file.setPosition(21 * 1024 * 1024 - 1);
          expect(await file.readByte(), 42);
        } finally {
          await file.close();
        }
        expect(client.closed, isTrue);
      },
    );
  }

  test('metadata reads still enforce limits on chunked responses', () async {
    final client = _Client(
      _Response(Stream.fromIterable([Uint8List(1024), Uint8List(1024)])),
    );
    final downloader = SkillPackageDownloader(
      endpointPolicy: policy,
      httpClientFactory: () => client,
    );

    await expectLater(
      downloader.fetch(uri, 1024, AgentCancellationToken()),
      throwsA(isA<SkillInstallException>()),
    );
    expect(client.closed, isTrue);
  });

  test('cancelled downloads close the client and output stream', () async {
    final token = AgentCancellationToken();
    Stream<List<int>> chunks() async* {
      yield Uint8List(1024);
      token.cancel();
      yield Uint8List(1024);
    }

    final client = _Client(_Response(chunks()));
    final downloader = SkillPackageDownloader(
      endpointPolicy: policy,
      httpClientFactory: () => client,
    );
    final destination = File('${temporary.path}/cancelled.zip');

    await expectLater(
      downloader.downloadToFile(uri, destination, token),
      throwsA(isA<AgentRunCancelledException>()),
    );

    expect(client.closed, isTrue);
    expect(await destination.length(), 1024);
    await destination.delete();
  });

  test('validates redirects before opening a second request', () async {
    final client = _Client(
      _Response(
        const Stream.empty(),
        statusCode: HttpStatus.found,
        location: 'https://localhost/private.zip',
      ),
    );
    final downloader = SkillPackageDownloader(
      endpointPolicy: policy,
      httpClientFactory: () => client,
    );

    await expectLater(
      downloader.downloadToFile(
        uri,
        File('${temporary.path}/redirect.zip'),
        AgentCancellationToken(),
      ),
      throwsA(isA<SkillInstallException>()),
    );

    expect(client.requests, 1);
    expect(client.closed, isTrue);
  });
}

final class _Client implements HttpClient {
  _Client(this.response);
  final HttpClientResponse response;
  bool closed = false;
  int requests = 0;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requests += 1;
    return _Request(response);
  }

  @override
  void close({bool force = false}) => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Request implements HttpClientRequest {
  _Request(this.response);
  final HttpClientResponse response;

  @override
  bool followRedirects = true;

  @override
  Future<HttpClientResponse> close() async => response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(
    this.body, {
    this.contentLength = -1,
    this.statusCode = HttpStatus.ok,
    String? location,
  }) : headers = _Headers(location);
  final Stream<List<int>> body;
  @override
  final int contentLength;
  @override
  final int statusCode;
  @override
  final HttpHeaders headers;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => body.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Headers implements HttpHeaders {
  _Headers(this.location);
  final String? location;
  @override
  String? value(String name) =>
      name == HttpHeaders.locationHeader ? location : null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
