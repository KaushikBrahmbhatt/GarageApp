import 'api_service.dart';
import '../models/garage.dart';

class GarageService {
  static final ApiService _api = ApiService();

  static Future<Garage> getGarage() async {
    final response = await _api.get('/garage');
    final json = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    return Garage.fromJson(json);
  }

  static Future<Garage> updateGarage({
    required String name,
    String? ownerName,
    String? address,
    String? phone,
    String? email,
  }) async {
    final response = await _api.put('/garage', {
      'name': name,
      if (ownerName != null) 'owner_name': ownerName,
      'address': address,
      'phone': phone,
      'email': email,
    });
    final json = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    return Garage.fromJson(json);
  }
}
