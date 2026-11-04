import '../core/json_utils.dart';

/// Persona del equipo de producción ("Crew List" del menú lateral) —
/// pedido explícito del usuario: directorio de TODAS las personas que
/// trabajan en el proyecto (tengan o no cuenta de acceso a la
/// plataforma), con nombre, cargo, departamento y celular para poder
/// contactarlas. Independiente de "usuarios" (cuentas de acceso) y de
/// "personajes"/"actores" (cast de ficción).
class CrewMember {
  final String? idCrew;
  final String nombre;
  final String cargo;
  final String? idDepartamento;
  final String? departamentoNombre;
  final String? celular;
  final String? correo;
  final String? notas;
  // Obligatorio para crear (ver crew_member_schema.py en el backend).
  final String? idProject;

  CrewMember({
    this.idCrew,
    required this.nombre,
    required this.cargo,
    this.idDepartamento,
    this.departamentoNombre,
    this.celular,
    this.correo,
    this.notas,
    this.idProject,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      idCrew: asString(pick(json, ['id_crew'])),
      nombre: asString(pick(json, ['nombre'])) ?? '',
      cargo: asString(pick(json, ['cargo'])) ?? '',
      idDepartamento: asString(pick(json, ['id_departamento'])),
      departamentoNombre: asString(pick(json, ['departamento_nombre'])),
      celular: asString(pick(json, ['celular'])),
      correo: asString(pick(json, ['correo'])),
      notas: asString(pick(json, ['notas'])),
      idProject: asString(pick(json, ['id_project'])),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'nombre': nombre,
        'cargo': cargo,
        if (idDepartamento != null && idDepartamento!.isNotEmpty) 'id_departamento': idDepartamento,
        if (celular != null && celular!.isNotEmpty) 'celular': celular,
        if (correo != null && correo!.isNotEmpty) 'correo': correo,
        if (notas != null && notas!.isNotEmpty) 'notas': notas,
        if (idProject != null) 'id_project': idProject,
      };
}
