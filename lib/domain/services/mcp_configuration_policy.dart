import 'package:stars/domain/models/mcp.dart';

/// Keeps recognizable credentials out of ordinary server configuration.
/// Secrets belong in the credential store, never URLs or process arguments.
abstract final class McpConfigurationPolicy {
  static final _sensitiveName = RegExp(
    r'^(?:.*(?:apikey|token|secret|password|passwd|credential|credentials|privatekey|accesskeyid|secretaccesskey)|'
    r'pwd|authorization|authentication|auth|cookie|key|bearer)$',
    caseSensitive: false,
  );
  static final _assignment = RegExp(r'''(?:^|[\s?&;,])[-\w.]+\s*[=:]''');
  static final _bearer = RegExp(r'\bBearer\s+\S+', caseSensitive: false);
  static final _knownSecret = RegExp(
    r'\b(?:sk-[A-Za-z0-9_-]{8,}|gh[pousr]_[A-Za-z0-9]{16,})\b',
  );

  static bool _isSensitiveName(String name) =>
      _sensitiveName.hasMatch(name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''));

  static bool endpointContainsCredentials(Uri endpoint) =>
      endpoint.userInfo.isNotEmpty ||
      endpoint.queryParametersAll.keys.any(_isSensitiveName) ||
      _containsCredentialText(endpoint.toString());

  static bool _containsCredentialText(String value) {
    if (_bearer.hasMatch(value) || _knownSecret.hasMatch(value)) return true;
    for (final match in _assignment.allMatches(value)) {
      final name = match.group(0)!.replaceAll(RegExp(r'[\s?&;,=:]'), '');
      if (_isSensitiveName(name)) return true;
    }
    return false;
  }

  static bool argumentsContainCredentials(Iterable<String> arguments) {
    for (final argument in arguments) {
      if (_containsCredentialText(argument)) return true;
      if (argument.startsWith('-') &&
          _isSensitiveName(argument.split(RegExp(r'[=:\s]')).first)) {
        return true;
      }
      // Decode URL query names, including percent-encoded credential keys.
      for (final match in RegExp(r'https?://[^\s]+').allMatches(argument)) {
        final uri = Uri.tryParse(match.group(0)!);
        if (uri != null && endpointContainsCredentials(uri)) return true;
      }
    }
    return false;
  }

  static void validateTransport(McpServerTransport transport) {
    final unsafe = switch (transport) {
      McpStreamableHttpServerTransport(:final endpoint) =>
        endpointContainsCredentials(endpoint),
      McpStdioServerTransport(:final command, :final arguments) =>
        _containsCredentialText(command) ||
            argumentsContainCredentials(arguments),
    };
    if (unsafe) {
      throw const McpException(
        'mcp_credentials_in_configuration',
        message:
            'Use the secure access token or environment fields for '
            'credentials. Do not put credentials in URLs, commands, or arguments.',
      );
    }
  }
}
