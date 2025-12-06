class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.name,
    required this.ip,
    required this.location,
    required this.status,
    required this.latencyMs,
  });

  final String id;
  final String name;
  final String ip;
  final String location;
  final String status;
  final double latencyMs;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'].toString(),
      name: json['name'] as String,
      ip: json['ip'] as String,
      location: json['location'] as String,
      status: json['status'] as String,
      latencyMs: (json['latency_ms'] as num).toDouble(),
    );
  }
}
