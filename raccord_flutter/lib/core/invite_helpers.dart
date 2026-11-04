import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/bulk_import.dart';
import '../models/catalog.dart';
import '../services/role_service.dart';
import '../widgets/bulk_upload_button.dart';

/// Lógica de "Carga masiva" de INVITACIONES, compartida entre Roles del
/// Equipo y Crew List (2026-09-01: Crew List pasó a listar personas ya
/// registradas en la plataforma en vez de un directorio de texto libre
/// aparte, así que ambas pantallas invitan exactamente de la misma
/// forma — se extrajo acá para no duplicar este bloque).
///
/// Columnas esperadas (por nombre, insensible a mayúsculas): nombre
/// completo, correo electrónico, área/departamento (por nombre) y rol
/// (por nombre). Se resuelven nombre -> id acá mismo antes de llamar al
/// backend (que espera id_departamento/id_rol).
Future<List<BulkRowResult>> bulkInvitePeople({
  required ApiClient api,
  required String idProject,
  required String idClient,
  required List<Department> departamentos,
  required List<RoleModel> roles,
  required List<Map<String, String>> rows,
}) async {
  final results = <BulkRowResult>[];
  final pendientes = <_PendingInvite>[];

  var fila = 1;
  for (final row in rows) {
    // '__fila' = número de fila en el archivo original (lo pone el
    // diálogo de carga masiva cuando solo envía las filas válidas).
    fila = int.tryParse(row['__fila'] ?? '') ?? fila + 1;
    final nombreCompleto = _pick(row, ['nombre completo', 'nombre_completo', 'nombre']);
    final correo = _pick(row, ['correo electrónico', 'correo electronico', 'correo', 'email', 'mail']);
    final areaTexto = _pick(row, ['área/departamento', 'area/departamento', 'área', 'area', 'departamento']);
    final rolTexto = _pick(row, ['rol']);

    if (nombreCompleto == null || correo == null || areaTexto == null || rolTexto == null) {
      results.add(BulkRowResult(fila: fila, ok: false, detalle: 'Faltan columnas requeridas (nombre completo, correo, área, rol)'));
      continue;
    }

    final depto = _findDepartamento(departamentos, areaTexto);
    if (depto == null) {
      results.add(BulkRowResult(fila: fila, ok: false, detalle: 'El área/departamento "$areaTexto" no existe'));
      continue;
    }

    final rol = _findRol(roles, rolTexto);
    if (rol == null) {
      results.add(BulkRowResult(fila: fila, ok: false, detalle: 'El rol "$rolTexto" no existe'));
      continue;
    }

    pendientes.add(_PendingInvite(
      fila: fila,
      correo: correo.trim().toLowerCase(),
      item: InviteItem(nombreCompleto: nombreCompleto, mail: correo, idDepartamento: depto.idDepartamento, idRol: rol.idRol),
    ));
  }

  if (pendientes.isEmpty) return results;

  try {
    final resp = await RoleService(api).invite(
      invitados: pendientes.map((p) => p.item).toList(),
      idProject: idProject,
      idClient: idClient,
    );

    final creados = (resp['usuarios_creados'] as List? ?? []).map((e) => (e as Map)['mail'].toString().toLowerCase()).toSet();
    final errores = <String, String>{
      for (final e in (resp['errores'] as List? ?? []))
        (e as Map)['mail'].toString().toLowerCase(): e['error'].toString(),
    };

    for (final p in pendientes) {
      if (creados.contains(p.correo)) {
        results.add(BulkRowResult(fila: p.fila, ok: true, detalle: 'Invitado correctamente'));
      } else {
        results.add(BulkRowResult(fila: p.fila, ok: false, detalle: errores[p.correo] ?? 'No se pudo invitar'));
      }
    }
  } on ApiException catch (e) {
    for (final p in pendientes) {
      results.add(BulkRowResult(fila: p.fila, ok: false, detalle: e.message));
    }
  }

  return results;
}

class _PendingInvite {
  final int fila;
  final String correo;
  final InviteItem item;
  _PendingInvite({required this.fila, required this.correo, required this.item});
}

String? _pick(Map<String, String> row, List<String> posiblesLlaves) {
  for (final key in posiblesLlaves) {
    final value = row[key];
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

Department? _findDepartamento(List<Department> departamentos, String texto) {
  for (final d in departamentos) {
    if (d.nombre.toLowerCase() == texto.toLowerCase() || d.idDepartamento == texto) return d;
  }
  return null;
}

RoleModel? _findRol(List<RoleModel> roles, String texto) {
  for (final r in roles) {
    if (r.nombre.toLowerCase() == texto.toLowerCase() || r.idRol.toString() == texto) return r;
  }
  return null;
}

/// Plantilla de carga masiva de personas a invitar (Roles del Equipo y
/// Crew List). El ejemplo usa un área y un rol que SÍ existen.
BulkTemplate invitePeopleTemplate({
  required String entidad,
  required String fileName,
  required List<Department> departamentos,
  required List<RoleModel> roles,
}) {
  return BulkTemplate(
    entidad: entidad,
    fileName: fileName,
    headers: const ['nombre completo', 'correo electrónico', 'área/departamento', 'rol'],
    labels: const {
      'nombre completo': 'Nombre completo',
      'correo electrónico': 'Correo electrónico',
      'área/departamento': 'Área / Departamento',
      'rol': 'Rol',
    },
    // Opciones reales del proyecto: se ven entre paréntesis en el título
    // y como lista desplegable en el Excel.
    options: {
      'área/departamento': [for (final d in departamentos) d.nombre],
      'rol': [for (final r in roles) r.nombre],
    },
    example: [
      'Juan Pérez',
      'juan.perez@correo.com',
      departamentos.isNotEmpty ? departamentos.first.nombre : 'Dirección',
      roles.isNotEmpty ? roles.first.nombre : 'Usuario',
    ],
    required: const [
      ['nombre completo', 'nombre_completo', 'nombre'],
      ['correo electrónico', 'correo electronico', 'correo', 'email', 'mail'],
      ['área/departamento', 'area/departamento', 'área', 'area', 'departamento'],
      ['rol'],
    ],
  );
}

/// Validación previa (sin escribir nada) de una fila de invitación:
/// formato del correo y que el área y el rol existan.
String? validateInviteRow(Map<String, String> row, List<Department> departamentos, List<RoleModel> roles) {
  final correo = _pick(row, ['correo electrónico', 'correo electronico', 'correo', 'email', 'mail']);
  if (correo != null && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
    return 'El correo "$correo" no es válido';
  }
  final area = _pick(row, ['área/departamento', 'area/departamento', 'área', 'area', 'departamento']);
  if (area != null && departamentos.isNotEmpty && _findDepartamento(departamentos, area) == null) {
    return 'El área/departamento "$area" no existe';
  }
  final rol = _pick(row, ['rol']);
  if (rol != null && roles.isNotEmpty && _findRol(roles, rol) == null) {
    return 'El rol "$rol" no existe';
  }
  return null;
}
