import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/catalog.dart';

class DepartmentService {
  final ApiClient api;
  DepartmentService(this.api);

  Future<List<Department>> all() async {
    final data = await api.get('/departments');
    return asListOfMap(data).map(Department.fromJson).toList();
  }

  Future<Department> create(String nombre, String ubicacion) async {
    final data = await api.post('/departments', body: {
      'nombre': nombre,
      'ubicacion': ubicacion,
    });
    return Department.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
