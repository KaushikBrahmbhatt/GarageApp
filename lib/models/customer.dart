import 'vehicle.dart';

class Customer {
  final int id;
  final int? garageId;
  final String name;
  final String phone;
  final String? email;
  final List<Vehicle> vehicles;

  Customer({
    required this.id,
    this.garageId,
    required this.name,
    required this.phone,
    this.email,
    required this.vehicles,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      garageId: json['garage_id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      vehicles: json['vehicles'] != null 
          ? (json['vehicles'] as List).map((v) => Vehicle.fromJson(v)).toList()
          : [],
    );
  }
}
