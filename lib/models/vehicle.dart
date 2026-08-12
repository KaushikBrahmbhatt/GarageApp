class Vehicle {
  final int id;
  final int? customerId;
  final String vehicleNumber;
  final String? brand;
  final String? model;
  final String? color;

  Vehicle({
    required this.id,
    this.customerId,
    required this.vehicleNumber,
    this.brand,
    this.model,
    this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      customerId: json['customer_id'],
      vehicleNumber: json['vehicle_number'],
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
    );
  }
}
