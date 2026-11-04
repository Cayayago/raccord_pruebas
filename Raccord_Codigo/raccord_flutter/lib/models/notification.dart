import '../core/json_utils.dart';

/// Alcance de una notificación: "general" (todo el equipo del
/// proyecto) o "especifica" (uno o más departamentos puntuales — tanto
/// Jefe de Departamento como Director pueden elegir varios a la vez).
const kAlcanceGeneral = 'general';
const kAlcanceEspecifica = 'especifica';

/// Origen: "manual" (alguien la escribió desde la pantalla de
/// Notificaciones) o "plan_rodaje" (se generó sola a partir de cambios
/// hechos en Plan de Rodaje).
const kOrigenManual = 'manual';
const kOrigenPlanRodaje = 'plan_rodaje';

class NotificationDepartamentoRef {
  final String idDepartamento;
  final String nombre;

  NotificationDepartamentoRef({required this.idDepartamento, required this.nombre});

  factory NotificationDepartamentoRef.fromJson(Map<String, dynamic> json) {
    return NotificationDepartamentoRef(
      idDepartamento: asString(pick(json, ['id_departamento'])) ?? '',
      nombre: asString(pick(json, ['nombre'])) ?? '',
    );
  }
}

/// Notificación del tablón informativo del proyecto (ver
/// notification_service.dart / notifications_screen.dart).
class AppNotification {
  final String idNotificacion;
  final String idProject;
  final String? idUserAutor;
  final String? autorNombre;
  final String tipoAlcance;
  final String origen;
  final String texto;
  final bool tieneFoto;
  final DateTime? fechaCreacion;
  final bool leida;
  final List<NotificationDepartamentoRef> departamentos;

  AppNotification({
    required this.idNotificacion,
    required this.idProject,
    this.idUserAutor,
    this.autorNombre,
    required this.tipoAlcance,
    required this.origen,
    required this.texto,
    required this.tieneFoto,
    this.fechaCreacion,
    required this.leida,
    this.departamentos = const [],
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final fecha = asString(pick(json, ['fecha_creacion']));
    final deps = pick(json, ['departamentos']);
    return AppNotification(
      idNotificacion: asString(pick(json, ['id_notificacion'])) ?? '',
      idProject: asString(pick(json, ['id_project'])) ?? '',
      idUserAutor: asString(pick(json, ['id_user_autor'])),
      autorNombre: asString(pick(json, ['autor_nombre'])),
      tipoAlcance: asString(pick(json, ['tipo_alcance'])) ?? kAlcanceGeneral,
      origen: asString(pick(json, ['origen'])) ?? kOrigenManual,
      texto: asString(pick(json, ['texto'])) ?? '',
      tieneFoto: pick(json, ['tiene_foto']) == true,
      fechaCreacion: fecha != null ? DateTime.tryParse(fecha) : null,
      leida: pick(json, ['leida']) == true,
      departamentos: deps is List
          ? deps.map((d) => NotificationDepartamentoRef.fromJson(Map<String, dynamic>.from(d as Map))).toList()
          : const [],
    );
  }
}
