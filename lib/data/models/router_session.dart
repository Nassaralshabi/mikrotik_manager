class RouterSession {
  const RouterSession({
    required this.username,
    required this.ipAddress,
    required this.uptime,
    required this.downloadMbps,
    required this.uploadMbps,
  });

  final String username;
  final String ipAddress;
  final Duration uptime;
  final double downloadMbps;
  final double uploadMbps;

  factory RouterSession.fromJson(Map<String, dynamic> json) {
    return RouterSession(
      username: json['username'] as String,
      ipAddress: json['ip'] as String,
      uptime: Duration(seconds: json['uptime_seconds'] as int),
      downloadMbps: (json['download_mbps'] as num).toDouble(),
      uploadMbps: (json['upload_mbps'] as num).toDouble(),
    );
  }
}
