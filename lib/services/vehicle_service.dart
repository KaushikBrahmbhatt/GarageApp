import '../models/vehicle.dart';
import '../models/job_card.dart';
import 'api_service.dart';

class VehicleService {
  static final _api = ApiService();

  static Future<Vehicle> create(
    int customerId,
    String vehicleNumber,
    String? brand,
    String? model,
    String? color,
  ) async {
    final data = await _api.post('/vehicles', {
      'customer_id': customerId,
      'vehicle_number': vehicleNumber,
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (model != null && model.isNotEmpty) 'model': model,
      if (color != null && color.isNotEmpty) 'color': color,
    });
    final json = data['data'] ?? data;
    return Vehicle.fromJson(json);
  }

  static Future<List<Vehicle>> list() async {
    final data = await _api.get('/vehicles');
    final list = data['data'] as List? ?? data as List? ?? [];
    return list.map((e) => Vehicle.fromJson(e)).toList();
  }

  static Future<Vehicle> get(int id) async {
    final data = await _api.get('/vehicles/$id');
    final json = data['data'] ?? data;
    return Vehicle.fromJson(json);
  }

  static Future<Vehicle> update(
    int id,
    String vehicleNumber,
    String? brand,
    String? model,
    String? color,
  ) async {
    final data = await _api.put('/vehicles/$id', {
      'vehicle_number': vehicleNumber,
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (model != null && model.isNotEmpty) 'model': model,
      if (color != null && color.isNotEmpty) 'color': color,
    });
    final json = data['data'] ?? data;
    return Vehicle.fromJson(json);
  }

  static Future<List<JobCard>> history(int vehicleId) async {
    final data = await _api.get('/vehicles/$vehicleId/history');
    final list = data['data'] as List? ?? data as List? ?? [];
    return list.map((e) => JobCard.fromJson(e)).toList();
  }
}
