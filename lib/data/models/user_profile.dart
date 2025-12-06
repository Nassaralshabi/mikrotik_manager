class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.plan,
    required this.balance,
    required this.activeSessions,
    required this.isSuspended,
  });

  final String id;
  final String name;
  final String plan;
  final double balance;
  final int activeSessions;
  final bool isSuspended;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      name: json['name'] as String,
      plan: json['plan'] as String,
      balance: (json['balance'] as num).toDouble(),
      activeSessions: json['active_sessions'] as int,
      isSuspended: json['is_suspended'] as bool,
    );
  }
}
