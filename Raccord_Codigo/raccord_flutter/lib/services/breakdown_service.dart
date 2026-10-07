import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/breakdown.dart';

class BreakdownService {
  final ApiClient api;
  BreakdownService(this.api);

  Future<List<DesgloseItem>> itemsByScene(String idEscena) async {
    final data = await api.get('/breakdown/items/scene/$idEscena');
    return asListOfMap(data).map(DesgloseItem.fromJson).toList();
  }

  Future<DesgloseItem> createItem(DesgloseItem item) async {
    final data = await api.post('/breakdown/items', body: item.toCreateJson());
    if (data is Map) return DesgloseItem.fromJson(Map<String, dynamic>.from(data));
    return item;
  }

  Future<void> updateItem(String id, Map<String, dynamic> changes) async {
    await api.patch('/breakdown/items/$id', body: changes);
  }

  Future<void> deleteItem(String id) async {
    await api.delete('/breakdown/items/$id');
  }

  // Antes /breakdown/pendientes no recibía proyecto — ahora lo exige
  // (Department es un catálogo global, ver breakdown_controller.py).
  Future<List<Map<String, dynamic>>> pendientesMiDepartamento(String idProject) async {
    final data = await api.get('/breakdown/pendientes/project/$idProject');
    return asListOfMap(data);
  }

  // Contenedor "desgloses" (breakdown-sheets) — antes /breakdown-sheets
  // sin filtro devolvía los de TODOS los proyectos.
  Future<List<BreakdownSheet>> sheets(String idProject) async {
    final data = await api.get('/breakdown-sheets/project/$idProject');
    return asListOfMap(data).map(BreakdownSheet.fromJson).toList();
  }

  Future<BreakdownSheet> createSheet(BreakdownSheet sheet) async {
    final data = await api.post('/breakdown-sheets', body: sheet.toCreateJson());
    if (data is Map) return BreakdownSheet.fromJson(Map<String, dynamic>.from(data));
    return sheet;
  }
}
