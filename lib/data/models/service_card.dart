class ServiceCard {
  const ServiceCard({
    required this.id,
    required this.title,
    required this.quota,
    required this.price,
    required this.status,
  });

  final String id;
  final String title;
  final String quota;
  final double price;
  final String status;

  factory ServiceCard.fromJson(Map<String, dynamic> json) {
    return ServiceCard(
      id: json['id'].toString(),
      title: json['title'] as String,
      quota: json['quota'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}
