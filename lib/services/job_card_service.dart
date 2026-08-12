import '../models/job_card.dart';
import '../models/job_card_item.dart';
import 'api_service.dart';

class JobCardService {
  static final _api = ApiService();

  static Future<List<JobCard>> list({String? date, String? status}) async {
    String query = '';
    if (date != null) query += '?date=$date';
    if (status != null) query += '${query.isEmpty ? '?' : '&'}status=$status';
    final data = await _api.get('/job-cards$query');
    final list = data['data'] as List? ?? data as List? ?? [];
    return list.map((e) => JobCard.fromJson(e)).toList();
  }

  static Future<JobCard> get(int id) async {
    final data = await _api.get('/job-cards/$id');
    final json = data['data'] ?? data;
    return JobCard.fromJson(json);
  }

  static Future<JobCard> create(
    int vehicleId,
    int customerId,
    List<Map<String, dynamic>> items,
  ) async {
    final data = await _api.post('/job-cards', {
      'vehicle_id': vehicleId,
      'customer_id': customerId,
      'items': items,
    });
    final json = data['data'] ?? data;
    return JobCard.fromJson(json);
  }

  static Future<JobCard> updateStatus(int id, String status) async {
    final data = await _api.patch('/job-cards/$id/status', {'status': status});
    final json = data['data'] ?? data;
    return JobCard.fromJson(json);
  }

  static Future<JobCardItem> addItem(int jobCardId, Map<String, dynamic> item) async {
    final data = await _api.post('/job-card-items', {
      'job_card_id': jobCardId,
      ...item,
    });
    final json = data['data'] ?? data;
    return JobCardItem.fromJson(json);
  }

  static Future<JobCardItem> updateItem(int itemId, Map<String, dynamic> changes) async {
    final data = await _api.patch('/job-card-items/$itemId', changes);
    final json = data['data'] ?? data;
    return JobCardItem.fromJson(json);
  }

  static Future<void> deleteItem(int itemId) async {
    await _api.delete('/job-card-items/$itemId');
  }
}
