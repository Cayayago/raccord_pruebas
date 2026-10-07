import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/module_access.dart';

/// Accesos personalizados por módulo (capa liviana sobre el rol) — ver
/// app/utils/module_access.py. Solo Administrador/Director de un
/// proyecto pueden fijar/quitar excepciones; cualquiera puede consultar
/// su propio acceso.
class ModuleAccessService {
  final ApiClient api;
  ModuleAccessService(this.api);

  String _base(String idProject, String idUser) => '/projects/$idProject/users/$idUser/module-access';

  Future<List<ModuleAccessModel>> list(String idProject, String idUser) async {
    final data = await api.get(_base(idProject, idUser));
    final map = Map<String, dynamic>.from(data as Map);
    final modulos = asListOfMap(map['modulos']);
    return modulos.map(ModuleAccessModel.fromJson).toList();
  }

  /// Fija una excepción puntual — el backend rechaza intentos de dar
  /// MÁS acceso del que el rol ya otorgaría (solo se puede restringir).
  Future<void> set(String idProject, String idUser, String modulo, String nivel) async {
    await api.put('${_base(idProject, idUser)}/$modulo', body: {'nivel': nivel});
  }

  /// Quita la excepción — vuelve al nivel por defecto del rol.
  Future<void> remove(String idProject, String idUser, String modulo) async {
    await api.delete('${_base(idProject, idUser)}/$modulo');
  }
}
