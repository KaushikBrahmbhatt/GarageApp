import 'vehicle.dart';
import 'customer.dart';
import 'job_card_item.dart';

class JobCard {
  final int id;
  final String status;
  final String? notes;
  final double estimatedTotal;
  final double finalTotal;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Vehicle? vehicle;
  final Customer? customer;
  final List<JobCardItem> items;

  JobCard({
    required this.id,
    required this.status,
    this.notes,
    required this.estimatedTotal,
    required this.finalTotal,
    required this.createdAt,
    this.completedAt,
    this.vehicle,
    this.customer,
    required this.items,
  });

  factory JobCard.fromJson(Map<String, dynamic> json) {
    return JobCard(
      id: json['id'],
      status: json['status'],
      notes: json['notes'],
      estimatedTotal: double.parse((json['estimated_total'] ?? 0).toString()),
      finalTotal: double.parse((json['final_total'] ?? 0).toString()),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']).toLocal() : null,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      items: json['items'] != null ? (json['items'] as List).map((i) => JobCardItem.fromJson(i)).toList() : [],
    );
  }
}
