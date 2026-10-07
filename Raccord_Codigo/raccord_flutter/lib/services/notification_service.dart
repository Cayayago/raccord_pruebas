import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/notification.dart';

/// Tablón informativo de Notificaciones (2026-09-27): solo Jefe de
/// Departamento y Director pueden publicar (ver "publish_notifications"
/// en permissions.dart / app/utils/permissions.py del backend).
class NotificationService {
  final ApiClient api;
  NotificationService(this.api);

  /// Notificaciones visibles para el usuario actual (generales +
  /// específicas de su departamento) — ya filtradas del lado del
  /// backend.
  Future<List<AppNotification>> all(String idProject) async {
    final data = await api.get('/notificaciones/project/$idProject');
    return asListOfMap(data).map(AppNotification.fromJson).toList();
  }

  /// Contador de no leídas — para el badge de la campana.
  Future<int> unreadCount(String idProject) async {
    final data = await api.get('/notificaciones/project/$idProject/no-leidas');
    if (data is! Map) return 0;
    return asInt(pick(Map<String, dynamic>.from(data), ['no_leidas'])) ?? 0;
  }

  /// Publica una notificación. [idsDepartamentos] solo se usa cuando
  /// [tipoAlcance] es "especifica" — puede traer VARIOS ids (pedido
  /// explícito: tanto Jefe de Departamento como Director pueden elegir
  /// más de un equipo a la vez). [fotoBytes]/[fotoNombre]/[fotoTipo]
  /// son opcionales.
  Future<AppNotification> crear(
    String idProject, {
    required String tipoAlcance,
    List<String> idsDepartamentos = const [],
    required String texto,
    String origen = kOrigenManual,
    List<int>? fotoBytes,
    String? fotoNombre,
    String? fotoTipo,
  }) async {
    final data = await api.postFile(
      '/notificaciones/project/$idProject',
      fieldName: 'file',
      bytes: fotoBytes,
      filename: fotoNombre,
      contentType: fotoTipo,
      fields: {
        'tipo_alcance': tipoAlcance,
        'texto': texto,
        'origen': origen,
        if (tipoAlcance == kAlcanceEspecifica && idsDepartamentos.isNotEmpty) 'departamentos': idsDepartamentos.join(','),
      },
    );
    if (data is! Map) {
      throw Exception('El servidor no confirmó la publicación de la notificación.');
    }
    return AppNotification.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> marcarLeida(String idNotificacion) async {
    await api.post('/notificaciones/$idNotificacion/leer', body: const {});
  }

  Future<List<int>> fotoBytes(String idNotificacion) {
    return api.getBytes('/notificaciones/$idNotificacion/foto');
  }
}
