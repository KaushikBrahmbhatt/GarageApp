class ServiceCatalogItem {
  final int id;
  final String name;
  final double price;
  final String type; // 'service' or 'repair'
  final bool isActive;

  ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    this.isActive = true,
  });

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogItem(
      id: json['id'],
      name: json['name'],
      price: double.parse((json['price'] ?? 0).toString()),
      type: json['type'] ?? 'service',
      isActive: json['is_active'] ?? true,
    );
  }
}
