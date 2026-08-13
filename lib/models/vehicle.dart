import 'job_card.dart';
import 'customer.dart';

class Vehicle {
  final int id;
  final int? customerId;
  final String vehicleNumber;
  final String? brand;
  final String? model;
  final String? color;
  final Customer? customer;
  final List<JobCard> jobCards;

  Vehicle({
    required this.id,
    this.customerId,
    required this.vehicleNumber,
    this.brand,
    this.model,
    this.color,
    this.customer,
    this.jobCards = const [],
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      customerId: json['customer_id'],
      vehicleNumber: json['vehicle_number'],
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      jobCards: json['job_cards'] != null
          ? (json['job_cards'] as List).map((j) => JobCard.fromJson(j)).toList()
          : [],
    );
  }
}
