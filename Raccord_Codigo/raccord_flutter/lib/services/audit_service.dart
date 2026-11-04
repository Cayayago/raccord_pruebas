import '../core/api_client.dart';
import '../core/json_utils.dart';

class AuditService {
  final ApiClient api;

  AuditService(this.api);

  Future<Map<String, dynamic>> listar({
    int page = 1,
    int limit = 20,
    String? action,
    String? module,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (action != null && action.isNotEmpty) 'action': action,
      if (module != null && module.isNotEmpty) 'module': module,
    };

    final data = await api.get('/audit-logs', query: query);

    if (data is! Map) {
      throw Exception(
          'La respuesta de auditoría no tiene el formato esperado.');
    }

    final result = Map<String, dynamic>.from(data);
    final pagination = result['pagination'];

    return {
      'items': asListOfMap(result['items']),
      'pagination': pagination is Map
          ? Map<String, dynamic>.from(pagination)
          : <String, dynamic>{},
    };
  }
}
