import 'package:stars/domain/models/task_tool_observation.dart';

/// A source list must survive checkpoint preparation intact before installation.
/// A summary, an empty list, or a partial/redacted list cannot drive a batch.
bool usableTaskSkillSources(TaskToolObservation observation) {
  if (observation.truncated || observation.redacted) return false;
  final data = observation.structuredContent;
  if (data is! Map<String, Object?> || data['destination'] != 'stars') {
    return false;
  }
  final skills = data['skills'];
  if (skills is! List<Object?> ||
      skills.isEmpty ||
      data['count'] != skills.length) {
    return false;
  }
  return skills.every(
    (item) =>
        item is Map<String, Object?> &&
        item['source'] is String &&
        (item['source']! as String).trim().isNotEmpty &&
        const {
          'github',
          'zip_url',
          'local_zip',
          'local_directory',
        }.contains(item['source_type']),
  );
}
