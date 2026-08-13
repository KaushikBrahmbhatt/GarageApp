import '../models/service_item.dart';
import 'api_service.dart';

class ServiceCatalogService {
  static final _api = ApiService();

  static Future<List<ServiceCatalogItem>> list({String? query, String? type}) async {
    String endpoint = '/services';
    final queryParams = <String>[];
    if (query != null && query.isNotEmpty) {
      queryParams.add('q=${Uri.encodeComponent(query)}');
    }
    if (type != null && type.isNotEmpty && type != 'All') {
      queryParams.add('type=${type.toLowerCase()}');
    }
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final data = await _api.get(endpoint);
    final List list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((j) => ServiceCatalogItem.fromJson(j)).toList();
  }

  static Future<ServiceCatalogItem> create(String name, double price, String type) async {
    final data = await _api.post('/services', {
      'name': name,
      'price': price,
      'type': type.toLowerCase(),
    });
    final json = data['data'] ?? data;
    return ServiceCatalogItem.fromJson(json);
  }

  static Future<ServiceCatalogItem> update(int id, {String? name, double? price, String? type}) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (price != null) payload['price'] = price;
    if (type != null) payload['type'] = type.toLowerCase();

    final data = await _api.put('/services/$id', payload);
    final json = data['data'] ?? data;
    return ServiceCatalogItem.fromJson(json);
  }

  static Future<void> delete(int id) async {
    await _api.delete('/services/$id');
  }
}
