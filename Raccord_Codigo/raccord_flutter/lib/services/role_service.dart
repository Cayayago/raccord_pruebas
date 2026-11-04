import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/catalog.dart';

class RoleService {
  final ApiClient api;
  RoleService(this.api);

  Future<List<RoleModel>> all() async {
    final data = await api.get('/roles');
    return asListOfMap(data).map(RoleModel.fromJson).toList();
  }

  /// Invita a una o varias personas a un proyecto. Cada invitado trae
  /// su propio nombre completo, correo, departamento y rol — "Invitar
  /// persona" manda una lista de un elemento; "Carga masiva" manda la
  /// misma estructura con N filas leídas de CSV/JSON. Requiere
  /// permiso invite_users (Administrador, Director, Jefe de
  /// Departamento).
  Future<Map<String, dynamic>> invite({
    required List<InviteItem> invitados,
    required String idProject,
    required String idClient,
  }) async {
    final data = await api.post('/users/invite', body: {
      'invitados': invitados.map((i) => i.toJson()).toList(),
      'id_project': idProject,
      'id_client': idClient,
    });
    return Map<String, dynamic>.from(data as Map);
  }
}

/// Una fila del formulario/archivo de invitación.
class InviteItem {
  final String nombreCompleto;
  final String mail;
  final String idDepartamento;
  final int idRol;

  InviteItem({
    required this.nombreCompleto,
    required this.mail,
    required this.idDepartamento,
    required this.idRol,
  });

  Map<String, dynamic> toJson() => {
        'nombre_completo': nombreCompleto,
        'mail': mail,
        'id_departamento': idDepartamento,
        'id_rol': idRol,
      };
}
