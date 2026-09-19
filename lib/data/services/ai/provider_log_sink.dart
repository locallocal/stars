/// Receives sanitized HTTP diagnostics without owning provider execution.
abstract interface class ProviderLogSink {
  Future<bool> get enabled;
  void add(Map<String, Object?> event);
}
