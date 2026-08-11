class BackupPreview {
  final bool isValid;
  final String? errorMessage;
  final int schemaVersion;
  final String? appVersion;
  final Map<String, int> recordCounts;
  final Map<String, int> duplicateCounts;
  final List<String> missingBoxes;

  BackupPreview({
    required this.isValid,
    this.errorMessage,
    required this.schemaVersion,
    this.appVersion,
    required this.recordCounts,
    required this.duplicateCounts,
    required this.missingBoxes,
  });
}
