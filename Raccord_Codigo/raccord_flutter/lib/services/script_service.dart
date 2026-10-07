import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/script.dart';

class ScriptService {
  final ApiClient api;
  ScriptService(this.api);

  Future<List<Script>> byProject(String idProject) async {
    final data = await api.get('/scripts/project/$idProject');
    return asListOfMap(data).map(Script.fromJson).toList();
  }

  Future<Script> create(Script script) async {
    final data = await api.post('/scripts', body: script.toCreateJson());
    if (data is Map) return Script.fromJson(Map<String, dynamic>.from(data));
    return script;
  }

  /// Actualización parcial (PATCH /scripts/{id}): recibe solo los campos
  /// que cambiaron (nombre, estado, numero_de_version, archivo,
  /// descripcion — ver ScriptUpdateSchema en el backend, todos
  /// opcionales).
  Future<void> update(String idGuion, Map<String, dynamic> fields) async {
    await api.patch('/scripts/$idGuion', body: fields);
  }

  Future<void> delete(String idGuion) async {
    await api.delete('/scripts/$idGuion');
  }

  /// Sube (o reemplaza) el PDF real del guion. Solo Admin/Director
  /// (permiso `upload_scripts`, el backend lo vuelve a validar del lado
  /// del servidor).
  Future<void> uploadArchivo(String idGuion, {required List<int> bytes, required String filename}) async {
    await api.postFile(
      '/scripts/$idGuion/archivo',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: 'application/pdf',
    );
  }

  /// Descarga los bytes del PDF ya cargado, para mostrarlos en el
  /// visor embebido (SfPdfViewer.memory).
  Future<List<int>> archivoBytes(String idGuion) {
    return api.getBytes('/scripts/$idGuion/archivo');
  }

  /// Segmentación automática por escenas (heurística de texto, sin IA
  /// — ver app/utils/script_parser.py en el backend). `confirmar: false`
  /// (default) solo trae la vista previa, sin escribir nada; `true`
  /// crea de verdad las escenas detectadas. El backend responde con un
  /// error de negocio (`ApiException` con `errorCode: 'INVALID_STATE'`,
  /// `'NO_FILE'`, `'PARSE_ERROR'` o `'NO_SCENES_DETECTED'`) cuando el
  /// guion no cumple los requisitos — el mensaje ya viene listo para
  /// mostrar tal cual.
  Future<Map<String, dynamic>> segmentar(String idGuion, {bool confirmar = false}) async {
    final data = await api.post('/scripts/$idGuion/segmentar', body: {'confirmar': confirmar});
    return Map<String, dynamic>.from(data as Map);
  }
}
