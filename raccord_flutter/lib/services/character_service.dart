import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/character.dart';

class CharacterService {
  final ApiClient api;
  CharacterService(this.api);

  // Antes /characters sin filtro devolvía los personajes de TODOS los
  // proyectos — ahora requiere el proyecto activo.
  Future<List<CharacterModel>> all(String idProject) async {
    final data = await api.get('/characters/project/$idProject');
    return asListOfMap(data).map(CharacterModel.fromJson).toList();
  }

  Future<CharacterModel> create(CharacterModel character) async {
    final data = await api.post('/characters', body: character.toCreateJson());
    if (data is Map) return CharacterModel.fromJson(Map<String, dynamic>.from(data));
    return character;
  }

  Future<void> update(String id, Map<String, dynamic> changes) async {
    await api.patch('/characters/$id', body: changes);
  }

  Future<void> delete(String id) async {
    await api.delete('/characters/$id');
  }
}

class ActorService {
  final ApiClient api;
  ActorService(this.api);

  // Antes /actors sin filtro devolvía los actores de TODOS los
  // proyectos — ahora requiere el proyecto activo.
  Future<List<ActorModel>> all(String idProject) async {
    final data = await api.get('/actors/project/$idProject');
    return asListOfMap(data).map(ActorModel.fromJson).toList();
  }

  Future<List<ActorModel>> byCharacter(String idPersonaje) async {
    final data = await api.get('/actors/character/$idPersonaje');
    return asListOfMap(data).map(ActorModel.fromJson).toList();
  }

  Future<ActorModel> get(String id) async {
    final data = await api.get('/actors/$id');
    return ActorModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<ActorModel> create(ActorModel actor) async {
    final data = await api.post('/actors', body: actor.toCreateJson());
    if (data is Map) return ActorModel.fromJson(Map<String, dynamic>.from(data));
    return actor;
  }

  // Edición de la ficha técnica (PATCH parcial) — agregado junto con el
  // soporte de edición en ActorFormScreen (2026-09-02); antes el actor
  // solo se podía crear, nunca editar después.
  Future<void> update(String id, Map<String, dynamic> changes) async {
    await api.patch('/actors/$id', body: changes);
  }

  Future<void> delete(String id) async {
    await api.delete('/actors/$id');
  }

  // ==========================================
  // FOTOS DEL ACTOR (en personaje / normal)
  // ==========================================
  // Mismo patrón que UserService.uploadOwnPhoto/photoBytes — el
  // binario nunca pasa por acá tal cual, solo bytes en memoria hacia
  // el backend (que a su vez lo sube a MinIO).
  Future<void> uploadFotoPersonaje(String idActor, {required List<int> bytes, required String filename, required String contentType}) async {
    await api.postFile('/actors/$idActor/foto-personaje', fieldName: 'file', bytes: bytes, filename: filename, contentType: contentType);
  }

  Future<List<int>> fotoPersonajeBytes(String idActor) {
    return api.getBytes('/actors/$idActor/foto-personaje');
  }

  Future<void> uploadFotoNormal(String idActor, {required List<int> bytes, required String filename, required String contentType}) async {
    await api.postFile('/actors/$idActor/foto-normal', fieldName: 'file', bytes: bytes, filename: filename, contentType: contentType);
  }

  Future<List<int>> fotoNormalBytes(String idActor) {
    return api.getBytes('/actors/$idActor/foto-normal');
  }
}
