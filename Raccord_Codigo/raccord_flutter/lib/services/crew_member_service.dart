import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/crew_member.dart';

class CrewMemberService {
  final ApiClient api;
  CrewMemberService(this.api);

  // Antes /crew sin filtro devolvía el personal de TODOS los proyectos
  // — ahora requiere el proyecto activo.
  Future<List<CrewMember>> all(String idProject) async {
    final data = await api.get('/crew/project/$idProject');
    return asListOfMap(data).map(CrewMember.fromJson).toList();
  }

  Future<CrewMember> create(CrewMember crew) async {
    final data = await api.post('/crew', body: crew.toCreateJson());
    if (data is Map) return CrewMember.fromJson(Map<String, dynamic>.from(data));
    return crew;
  }

  Future<void> update(String id, CrewMember crew) async {
    await api.put('/crew/$id', body: crew.toCreateJson());
  }

  Future<void> delete(String id) async {
    await api.delete('/crew/$id');
  }
}
