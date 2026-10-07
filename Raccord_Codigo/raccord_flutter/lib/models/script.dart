import '../core/json_utils.dart';

const kEstadosGuion = ['Borrador', 'Revisión', 'Aprobado', 'En Rodaje', 'Archivado'];

class Script {
  final String? idGuion;
  final String numeroDeVersion;
  final DateTime fechaDeEmision;
  final String estado;
  final String archivo;
  final String nombre;
  final String? descripcion;
  final String? idProject;
  // PDF real (guardado en la BD, ver POST/GET /scripts/{id}/archivo).
  // archivoNombre != null quiere decir que este guion ya tiene un PDF
  // cargado.
  final String? archivoNombre;
  final int? archivoTamano;

  Script({
    this.idGuion,
    required this.numeroDeVersion,
    required this.fechaDeEmision,
    required this.estado,
    required this.archivo,
    required this.nombre,
    this.descripcion,
    this.idProject,
    this.archivoNombre,
    this.archivoTamano,
  });

  bool get tienePdf => archivoNombre != null && archivoNombre!.isNotEmpty;

  factory Script.fromJson(Map<String, dynamic> json) {
    final fecha = asString(pick(json, ['fecha_de_emision']));
    return Script(
      idGuion: asString(pick(json, ['id_guion'])),
      numeroDeVersion: asString(pick(json, ['numero_de_version'])) ?? '',
      fechaDeEmision: fecha != null ? (DateTime.tryParse(fecha) ?? DateTime.now()) : DateTime.now(),
      estado: asString(pick(json, ['estado'])) ?? 'Borrador',
      archivo: asString(pick(json, ['archivo'])) ?? '',
      nombre: asString(pick(json, ['nombre'])) ?? '',
      descripcion: asString(pick(json, ['descripcion'])),
      idProject: asString(pick(json, ['id_project'])),
      archivoNombre: asString(pick(json, ['archivo_nombre'])),
      archivoTamano: asInt(pick(json, ['archivo_tamano'])),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'numero_de_version': numeroDeVersion,
        'fecha_de_emision': fechaDeEmision.toIso8601String().split('T').first,
        'estado': estado,
        'archivo': archivo,
        'nombre': nombre,
        if (descripcion != null && descripcion!.isNotEmpty) 'descripcion': descripcion,
        if (idProject != null) 'id_project': idProject,
      };
}
