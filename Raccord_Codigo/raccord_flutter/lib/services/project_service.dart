import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/project.dart';

class ProjectService {
  final ApiClient api;
  ProjectService(this.api);

  Future<List<Project>> myProjects(String idUser) async {
    final data = await api.get('/users/$idUser/projects');
    return asListOfMap(data).map(Project.fromJson).toList();
  }

  Future<List<Project>> all() async {
    final data = await api.get('/projects');
    return asListOfMap(data).map(Project.fromJson).toList();
  }

  Future<Project> get(String id) async {
    final data = await api.get('/projects/$id');
    return Project.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Crea el proyecto Y lo vincula al usuario que lo crea, en un solo
  /// paso (POST /projects/create) — es lo que usan los mockups
  /// "Registra Proyecto" / "Crear Proyecto".
  Future<Project> createAndLink({
    required String projectName,
    required String formatoDeProduccion,
    required String genero,
    String? sinopsis,
    String? director,
    required String idClient,
    required String idUser,
  }) async {
    final data = await api.post('/projects/create', body: {
      'project_name': projectName,
      'formato_de_produccion': formatoDeProduccion,
      'genero': genero,
      if (sinopsis != null && sinopsis.isNotEmpty) 'sinopsis': sinopsis,
      if (director != null && director.isNotEmpty) 'director': director,
      'id_client': idClient,
      'id_user': idUser,
    });
    // El endpoint devuelve el id_project creado (string) según el
    // controller; para tener el objeto completo, se recarga la lista.
    // En ambos casos, quien crea el proyecto SIEMPRE queda vinculado
    // con rol Administrador (1001) — ver create_project_and_link en
    // project_controller.py — así que se fija a mano acá: ni GET
    // /projects/{id} ni la respuesta de creación traen id_rol (ese
    // campo solo lo agrega GET /users/{id}/projects).
    if (data is String) {
      return (await get(data)).withIdRol(1001);
    }
    return Project.fromJson(Map<String, dynamic>.from(data as Map)).withIdRol(1001);
  }
}
