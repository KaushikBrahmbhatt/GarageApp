class JobCardItem {
  final int id;
  final int? jobCardId;
  final String type;
  final String description;
  final double price;
  final String flag;

  JobCardItem({
    required this.id,
    this.jobCardId,
    required this.type,
    required this.description,
    required this.price,
    required this.flag,
  });

  factory JobCardItem.fromJson(Map<String, dynamic> json) {
    return JobCardItem(
      id: json['id'],
      jobCardId: json['job_card_id'],
      type: json['type'],
      description: json['description'],
      price: double.parse((json['price'] ?? 0).toString()),
      flag: json['flag'] ?? 'none',
    );
  }
}
