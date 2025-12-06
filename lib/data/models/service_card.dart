class ServiceCard {
  const ServiceCard({
    required this.id,
    required this.title,
    required this.quota,
    required this.price,
    required this.status,
    this.username,
    this.password,
    this.profileName,
    this.customerName,
    this.createdAt,
  });

  final String id;
  final String title;
  final String quota;
  final double price;
  final String status;
  final String? username;
  final String? password;
  final String? profileName;
  final String? customerName;
  final DateTime? createdAt;

  factory ServiceCard.fromJson(Map<String, dynamic> json) {
    return ServiceCard(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'بطاقة غير محددة',
      quota: json['quota'] as String? ?? 'غير محدد',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'غير محدد',
      username: json['username'] as String?,
      password: json['password'] as String?,
      profileName: json['profile'] as String?,
      customerName: json['customer'] as String?,
      createdAt: json['created_at'] != null 
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'quota': quota,
      'price': price,
      'status': status,
      'username': username,
      'password': password,
      'profile': profileName,
      'customer': customerName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
