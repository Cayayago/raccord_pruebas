import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/scene.dart';

class SceneService {
  final ApiClient api;
  SceneService(this.api);

  // Antes /scenes sin filtro devolvía las escenas de TODOS los
  // proyectos (ver scene_routes.py en el backend) — ahora requiere el
  // proyecto activo.
  Future<List<Scene>> all(String idProject) async {
    final data = await api.get('/scenes/project/$idProject');
    return asListOfMap(data).map(Scene.fromJson).toList();
  }

  Future<List<Scene>> byScript(String idGuion) async {
    final data = await api.get('/scenes/script/$idGuion');
    return asListOfMap(data).map(Scene.fromJson).toList();
  }

  Future<Scene> get(String id) async {
    final data = await api.get('/scenes/$id');
    return Scene.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Scene> create(Scene scene) async {
    final data = await api.post('/scenes', body: scene.toCreateJson());
    if (data is Map) return Scene.fromJson(Map<String, dynamic>.from(data));
    return scene;
  }

  Future<void> updatePartial(String id, Map<String, dynamic> changes) async {
    await api.patch('/scenes/$id', body: changes);
  }

  Future<void> delete(String id) async {
    await api.delete('/scenes/$id');
  }

  // Cast (escenas_personajes)
  Future<List<Map<String, dynamic>>> cast(String idEscena) async {
    final data = await api.get('/scenes/$idEscena/cast');
    return asListOfMap(data);
  }

  Future<void> addToCast(String idEscena, String idPersonaje) async {
    await api.post('/scenes/$idEscena/cast', body: {'id_personaje': idPersonaje});
  }

  Future<void> removeFromCast(String idEscena, String idPersonaje) async {
    await api.delete('/scenes/$idEscena/cast/$idPersonaje');
  }
}
