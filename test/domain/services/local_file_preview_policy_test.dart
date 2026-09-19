import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/local_file_preview_policy.dart';
import 'package:stars/domain/services/local_file_reference_parser.dart';

import '../../support/file_preview_test_support.dart';

void main() {
  const policy = LocalFilePreviewPolicy();
  final parser = LocalFileReferenceParser(baseDirectory: '/chat');

  test('supports file observations without a tool-name allowlist', () {
    expect(
      policy.supportedPaths(
        parser: parser,
        evidence: [
          filePreviewEvidence(path: 'report.md', toolName: 'new_plugin.export'),
        ],
      ),
      {'/chat/report.md'},
    );
  });

  test('copy and move receipts expose the destination, not the source', () {
    expect(
      policy.supportedPaths(
        parser: parser,
        evidence: [
          filePreviewEvidence(
            path: '',
            scope: {
              'source_path': '/input.md',
              'destination_path': '/output.md',
            },
            facts: [
              StructuredFact(name: 'action.completed', value: true),
              StructuredFact(name: 'file.destination_exists', value: true),
            ],
          ),
        ],
      ),
      {'/output.md'},
    );
  });

  test('remote file facts do not establish a local file reference', () {
    expect(
      policy.supportedPaths(
        parser: parser,
        evidence: [
          filePreviewEvidence(
            path: '/report.md',
            capabilities: const {ToolCapability.externalWrite},
          ),
        ],
      ),
      isEmpty,
    );
  });

  test('success or a path argument alone does not prove a file result', () {
    expect(
      policy.supportedPaths(
        parser: parser,
        evidence: [
          filePreviewEvidence(path: '/unpersisted.md', persisted: false),
          filePreviewEvidence(
            path: '/planned.md',
            facts: [StructuredFact(name: 'action.completed', value: true)],
          ),
          filePreviewEvidence(
            path: '/deleted.md',
            facts: [
              StructuredFact(name: 'action.completed', value: true),
              StructuredFact(name: 'file.deleted', value: true),
              StructuredFact(name: 'file.exists', value: false),
            ],
          ),
        ],
      ),
      isEmpty,
    );
  });
}
