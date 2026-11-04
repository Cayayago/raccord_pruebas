import '../core/json_utils.dart';

class ShootingDay {
  final String? idRodaje;
  final String version;
  final int? semanaGrabacion;
  final int? diaRodaje;
  final String? horaInicio;
  final String? horaFin;
  final String? location;
  final String? notas;
  final bool activo;
  // Obligatorio para crear (ver shooting_day_schema.py en el backend).
  final String? idProject;

  ShootingDay({
    this.idRodaje,
    required this.version,
    this.semanaGrabacion,
    this.diaRodaje,
    this.horaInicio,
    this.horaFin,
    this.location,
    this.notas,
    this.activo = true,
    this.idProject,
  });

  factory ShootingDay.fromJson(Map<String, dynamic> json) {
    return ShootingDay(
      idRodaje: asString(pick(json, ['id_rodaje'])),
      version: asString(pick(json, ['version'])) ?? '',
      semanaGrabacion: asInt(pick(json, ['semana_grabacion'])),
      diaRodaje: asInt(pick(json, ['dia_rodaje'])),
      horaInicio: asString(pick(json, ['hora_inicio'])),
      horaFin: asString(pick(json, ['hora_fin'])),
      location: asString(pick(json, ['location'])),
      notas: asString(pick(json, ['notas'])),
      activo: asBool(pick(json, ['activo'])) ?? true,
      idProject: asString(pick(json, ['id_project'])),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'version': version,
        if (semanaGrabacion != null) 'semana_grabacion': semanaGrabacion,
        if (diaRodaje != null) 'dia_rodaje': diaRodaje,
        if (horaInicio != null && horaInicio!.isNotEmpty) 'hora_inicio': horaInicio,
        if (horaFin != null && horaFin!.isNotEmpty) 'hora_fin': horaFin,
        if (location != null && location!.isNotEmpty) 'location': location,
        if (notas != null && notas!.isNotEmpty) 'notas': notas,
        'activo': activo,
        if (idProject != null) 'id_project': idProject,
      };
}
