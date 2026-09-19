import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/local_file_reference_parser.dart';

/// File references supported by structured observations, independent of message
/// kinds, tool names and the language used in a reply. These are navigation
/// targets, not a claim that the current file still matches its recorded hash.
final class LocalFilePreviewPolicy {
  const LocalFilePreviewPolicy();

  Set<String> supportedPaths({
    required LocalFileReferenceParser parser,
    required Iterable<ToolEvidenceRecord> evidence,
  }) {
    final paths = <String>{};
    void add(Object? reference) {
      if (reference is! String) return;
      final resolved = parser.resolve(reference);
      if (resolved != null) paths.add(resolved);
    }

    for (final record in evidence) {
      if (!record.canSupportBusinessFacts ||
          !record.capabilities.any(
            const {
              ToolCapability.localRead,
              ToolCapability.localWrite,
            }.contains,
          )) {
        continue;
      }
      final facts = {
        for (final fact in record.structuredFacts) fact.name: fact.value,
      };
      final size = facts['file.size_bytes'];
      if (facts['file.exists'] != false && facts['file.deleted'] != true) {
        if (facts['file.exists'] == true || (size is int && size >= 0)) {
          add(record.scope['path']);
        }
      }
      if (facts['file.destination_exists'] == true) {
        add(record.scope['destination_path']);
      }
    }
    return Set.unmodifiable(paths);
  }
}
