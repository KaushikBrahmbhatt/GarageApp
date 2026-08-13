import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_colors.dart';
import '../../models/report_analytics.dart';
import '../../services/report_service.dart';
import '../../widgets/skeleton_loader.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'this_month';
  ReportAnalytics? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _loading = true);
    try {
      final res = await ReportService.getAnalytics(period: _selectedPeriod);
      if (mounted) {
        setState(() {
          _analytics = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Fluttertoast.showToast(msg: 'Failed to load report analytics');
      }
    }
  }

  String _getPeriodLabel(String key) {
    switch (key) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'this_year':
        return 'This Year';
      default:
        return 'This Month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchAnalytics,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Period Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['today', 'this_week', 'this_month', 'this_year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_getPeriodLabel(period)),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedPeriod = period);
                        _fetchAnalytics();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const SkeletonListLoader(count: 4)
            else if (_analytics == null)
              const Center(child: Text('Failed to load reports', style: TextStyle(color: AppColors.textSecondary)))
            else ...[
              // Revenue Overview Card
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Revenue', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(_getPeriodLabel(_analytics!.period), style: const TextStyle(color: AppColors.successText, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${_analytics!.totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('${_analytics!.completedJobs}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              const Text('Completed Jobs', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                          Container(height: 28, width: 1, color: AppColors.cardBorder),
                          Column(
                            children: [
                              Text('₹${_analytics!.avgJobValue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              const Text('Avg Job Value', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                          Container(height: 28, width: 1, color: AppColors.cardBorder),
                          Column(
                            children: [
                              Text('${_analytics!.totalJobs}', style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              const Text('Total Cards', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Revenue Trend Chart Card
              const Text('Revenue Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daily Revenue & Volume Timeline', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              const Text('Revenue', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_analytics!.trendData.isEmpty)
                        const SizedBox(height: 120, child: Center(child: Text('No data for selected period', style: TextStyle(color: AppColors.textSecondary))))
                      else
                        SizedBox(
                          height: 170,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _analytics!.trendData.map((pt) {
                              final maxRev = _analytics!.trendData.fold<double>(1, (max, p) => p.revenue > max ? p.revenue : max);
                              final hasRevenue = pt.revenue > 0;
                              final hasJobs = pt.count > 0;

                              double barHeight = 8.0;
                              if (hasRevenue) {
                                barHeight = (pt.revenue / maxRev * 110).clamp(16.0, 110.0);
                              } else if (hasJobs) {
                                barHeight = 24.0;
                              }

                              return Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (hasRevenue)
                                      Text(
                                        '₹${pt.revenue >= 1000 ? '${(pt.revenue / 1000).toStringAsFixed(1)}k' : pt.revenue.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else if (hasJobs)
                                      Text(
                                        '${pt.count}j',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warningText),
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 16,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: hasRevenue
                                            ? AppColors.primary
                                            : (hasJobs ? AppColors.warningText : AppColors.cardBorder),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      pt.label,
                                      style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Top Requested Services Card
              const Text('Top Performing Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _analytics!.topServices.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No service records in this period.', style: TextStyle(color: AppColors.textSecondary))),
                        )
                      : Column(
                          children: _analytics!.topServices.map((svc) {
                            final maxCount = _analytics!.topServices.fold<int>(1, (max, s) => s.count > max ? s.count : max);
                            final ratio = (svc.count / maxCount).clamp(0.1, 1.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(svc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                      Text('₹${svc.revenue.toStringAsFixed(0)} (${svc.count} jobs)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor: AppColors.background,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Vehicle Brand Distribution
              if (_analytics!.vehicleBrands.isNotEmpty) ...[
                const Text('Vehicle Brand Share', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _analytics!.vehicleBrands.map((b) {
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(b.brand.substring(0, b.brand.length > 2 ? 2 : b.brand.length), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            ),
                            const SizedBox(height: 6),
                            Text(b.brand, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('${b.count} bikes', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
