import '../core/json_utils.dart';

const kCategoriasDesglose = [
  'Props',
  'Extras',
  'Bits',
  'SFX',
  'Sonido',
  'Stunts',
  'Vestuario',
  'Maquillaje/Pelo',
  'Maquillaje FX',
  'Cámara',
  'VFX',
  'Armas',
  'Vehículos',
  'Animales',
  'Arte',
  'Música',
  'Crew Adicional',
  'Notas',
];

const kEstadosDesglose = ['pendiente', 'en_progreso', 'completado'];
const kPrioridadesDesglose = ['alta', 'media', 'baja'];

class DesgloseItem {
  final String? id;
  final String idEscena;
  final String? idDepartamento;
  final String categoria;
  final String nombreItem;
  final int? cantidad;
  final String? notas;

  DesgloseItem({
    this.id,
    required this.idEscena,
    this.idDepartamento,
    required this.categoria,
    required this.nombreItem,
    this.cantidad,
    this.notas,
  });

  factory DesgloseItem.fromJson(Map<String, dynamic> json) {
    return DesgloseItem(
      id: asString(pick(json, ['id', 'id_desglose_item'])),
      idEscena: asString(pick(json, ['id_escena'])) ?? '',
      idDepartamento: asString(pick(json, ['id_departamento'])),
      categoria: asString(pick(json, ['categoria'])) ?? '',
      nombreItem: asString(pick(json, ['nombre_item'])) ?? '',
      cantidad: asInt(pick(json, ['cantidad'])),
      notas: asString(pick(json, ['notas'])),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'id_escena': idEscena,
        if (idDepartamento != null && idDepartamento!.isNotEmpty) 'id_departamento': idDepartamento,
        'categoria': categoria,
        'nombre_item': nombreItem,
        if (cantidad != null) 'cantidad': cantidad,
        if (notas != null && notas!.isNotEmpty) 'notas': notas,
      };
}

class BreakdownSheet {
  final String? idDesglose;
  final String version;
  final int? semanaGrabacion;
  final int? diaRodaje;
  final String? horaInicio;
  final String? horaFin;
  final String? location;
  final String requerimientos;
  final bool activo;
  // Obligatorio para crear (ver breakdown_sheet_schema.py en el backend).
  final String? idProject;

  BreakdownSheet({
    this.idDesglose,
    required this.version,
    this.semanaGrabacion,
    this.diaRodaje,
    this.horaInicio,
    this.horaFin,
    this.location,
    required this.requerimientos,
    this.activo = true,
    this.idProject,
  });

  factory BreakdownSheet.fromJson(Map<String, dynamic> json) {
    return BreakdownSheet(
      idDesglose: asString(pick(json, ['id_desglose'])),
      version: asString(pick(json, ['version'])) ?? '',
      semanaGrabacion: asInt(pick(json, ['semana_grabacion'])),
      diaRodaje: asInt(pick(json, ['dia_rodaje'])),
      horaInicio: asString(pick(json, ['hora_inicio'])),
      horaFin: asString(pick(json, ['hora_fin'])),
      location: asString(pick(json, ['location'])),
      requerimientos: asString(pick(json, ['requerimientos'])) ?? '',
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
        'requerimientos': requerimientos,
        'activo': activo,
        if (idProject != null) 'id_project': idProject,
      };
}
