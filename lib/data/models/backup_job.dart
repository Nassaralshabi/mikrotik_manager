class BackupJob {
  const BackupJob({
    required this.id,
    required this.type,
    required this.lastRun,
    required this.sizeMb,
    required this.status,
  });

  final String id;
  final String type;
  final DateTime lastRun;
  final double sizeMb;
  final String status;

  factory BackupJob.fromJson(Map<String, dynamic> json) {
    return BackupJob(
      id: json['id'].toString(),
      type: json['type'] as String,
      lastRun: DateTime.parse(json['last_run'] as String),
      sizeMb: (json['size_mb'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}
