/// Inherit only runtime essentials; server-specific values must be explicit.
/// This limits ambient credentials, but is not a process sandbox.
Map<String, String> mcpStdioEnvironment(
  Map<String, String> parent,
  Map<String, String> explicit, {
  bool caseInsensitive = false,
}) {
  const allowed = {
    'PATH',
    'HOME',
    'USERPROFILE',
    'SYSTEMROOT',
    'WINDIR',
    'COMSPEC',
    'PATHEXT',
    'APPDATA',
    'LOCALAPPDATA',
    'TEMP',
    'TMP',
    'TMPDIR',
    'LANG',
    'LC_ALL',
    'LC_CTYPE',
  };
  final result = <String, String>{
    for (final entry in parent.entries)
      if (allowed.contains(
        caseInsensitive ? entry.key.toUpperCase() : entry.key,
      ))
        entry.key: entry.value,
  };
  // Windows environment names are case-insensitive. Explicit values win.
  for (final entry in explicit.entries) {
    if (caseInsensitive) {
      result.removeWhere(
        (key, _) => key.toUpperCase() == entry.key.toUpperCase(),
      );
    }
    result[entry.key] = entry.value;
  }
  return result;
}
