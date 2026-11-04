import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/shooting_day.dart';

class ShootingDayService {
  final ApiClient api;
  ShootingDayService(this.api);

  // Antes /shooting-days sin filtro devolvía el plan de rodaje de
  // TODOS los proyectos — ahora requiere el proyecto activo.
  Future<List<ShootingDay>> all(String idProject) async {
    final data = await api.get('/shooting-days/project/$idProject');
    return asListOfMap(data).map(ShootingDay.fromJson).toList();
  }

  Future<ShootingDay> create(ShootingDay day) async {
    final data = await api.post('/shooting-days', body: day.toCreateJson());
    if (data is Map) return ShootingDay.fromJson(Map<String, dynamic>.from(data));
    return day;
  }

  Future<void> update(String id, Map<String, dynamic> changes) async {
    await api.patch('/shooting-days/$id', body: changes);
  }

  Future<void> delete(String id) async {
    await api.delete('/shooting-days/$id');
  }
}
