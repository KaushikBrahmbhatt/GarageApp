import 'vehicle.dart';
import 'job_card.dart';

class Customer {
  final int id;
  final int? garageId;
  final String name;
  final String phone;
  final String? email;
  final List<Vehicle> vehicles;
  final List<JobCard> jobCards;

  Customer({
    required this.id,
    this.garageId,
    required this.name,
    required this.phone,
    this.email,
    required this.vehicles,
    this.jobCards = const [],
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
      jobCards: json['job_cards'] != null
          ? (json['job_cards'] as List).map((j) => JobCard.fromJson(j)).toList()
          : [],
    );
  }
}
