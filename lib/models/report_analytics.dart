class TrendPoint {
  final String label;
  final double revenue;
  final int count;

  TrendPoint({required this.label, required this.revenue, required this.count});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      label: json['label'] ?? '',
      revenue: double.parse((json['revenue'] ?? 0).toString()),
      count: json['count'] ?? 0,
    );
  }
}

class TopServiceStat {
  final String name;
  final int count;
  final double revenue;

  TopServiceStat({required this.name, required this.count, required this.revenue});

  factory TopServiceStat.fromJson(Map<String, dynamic> json) {
    return TopServiceStat(
      name: json['name'] ?? 'Service',
      count: json['count'] ?? 0,
      revenue: double.parse((json['revenue'] ?? 0).toString()),
    );
  }
}

class BrandStat {
  final String brand;
  final int count;

  BrandStat({required this.brand, required this.count});

  factory BrandStat.fromJson(Map<String, dynamic> json) {
    return BrandStat(
      brand: json['brand'] ?? 'OTHER',
      count: json['count'] ?? 0,
    );
  }
}

class ReportAnalytics {
  final String period;
  final double totalRevenue;
  final int totalJobs;
  final int completedJobs;
  final int inProgressJobs;
  final int newJobs;
  final double avgJobValue;
  final List<TrendPoint> trendData;
  final List<TopServiceStat> topServices;
  final List<BrandStat> vehicleBrands;

  ReportAnalytics({
    required this.period,
    required this.totalRevenue,
    required this.totalJobs,
    required this.completedJobs,
    required this.inProgressJobs,
    required this.newJobs,
    required this.avgJobValue,
    required this.trendData,
    required this.topServices,
    required this.vehicleBrands,
  });

  factory ReportAnalytics.fromJson(Map<String, dynamic> json) {
    return ReportAnalytics(
      period: json['period'] ?? 'this_month',
      totalRevenue: double.parse((json['total_revenue'] ?? 0).toString()),
      totalJobs: json['total_jobs'] ?? 0,
      completedJobs: json['completed_jobs'] ?? 0,
      inProgressJobs: json['in_progress_jobs'] ?? 0,
      newJobs: json['new_jobs'] ?? 0,
      avgJobValue: double.parse((json['avg_job_value'] ?? 0).toString()),
      trendData: json['trend_data'] != null
          ? (json['trend_data'] as List).map((t) => TrendPoint.fromJson(t)).toList()
          : [],
      topServices: json['top_services'] != null
          ? (json['top_services'] as List).map((s) => TopServiceStat.fromJson(s)).toList()
          : [],
      vehicleBrands: json['vehicle_brands'] != null
          ? (json['vehicle_brands'] as List).map((b) => BrandStat.fromJson(b)).toList()
          : [],
    );
  }
}
