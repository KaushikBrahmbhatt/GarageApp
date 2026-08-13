import '../models/customer.dart';
import 'api_service.dart';

class CustomerService {
  static final _api = ApiService();

  static Future<List<Customer>> search(String query) async {
    final data = await _api.get('/customers/search?q=${Uri.encodeComponent(query)}');
    final list = data['data'] as List? ?? data as List? ?? [];
    return list.map((e) => Customer.fromJson(e)).toList();
  }

  static Future<Customer> create(String name, String phone, String? email) async {
    final data = await _api.post('/customers', {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    // API returns resource directly or wrapped in data
    final json = data['data'] ?? data;
    return Customer.fromJson(json);
  }

  static Future<Customer> get(int id) async {
    final data = await _api.get('/customers/$id');
    final json = data['data'] ?? data;
    return Customer.fromJson(json);
  }

  static Future<Customer> update(int id, String name, String phone, String? email) async {
    final data = await _api.put('/customers/$id', {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    final json = data['data'] ?? data;
    return Customer.fromJson(json);
  }
}
