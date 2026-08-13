import '../models/report_analytics.dart';
import 'api_service.dart';

class ReportService {
  static final _api = ApiService();

  static Future<ReportAnalytics> getAnalytics({String period = 'this_month'}) async {
    final data = await _api.get('/reports/analytics?period=$period');
    final json = data['data'] ?? data;
    return ReportAnalytics.fromJson(json);
  }
}
