import '../core/json_utils.dart';

/// Catálogos del módulo Inventario (espejo de inventory_schema.py).
/// Tipo y color se guardan como texto: si un elemento trae un valor que
/// ya no está en estas listas, los desplegables lo incluyen igual.
const kGenerosInventario = ['Masculino', 'Femenino'];

const kTiposInventario = [
  'Prenda superior',
  'Prenda inferior',
  'Vestido',
  'Traje completo',
  'Abrigos',
  'Zapatos',
  'Joyas',
  'Accesorios',
  'Sombreros y gorras',
  'Bolsos y maletas',
  'Utilería',
  'Decoración',
  'Utensilio',
  'Mobiliario',
  'Electrónicos',
  'Documentos y papelería',
  'Libros y arte',
  'Herramientas',
  'Instrumentos musicales',
  'Armas y utilería de acción',
  'Vehículos',
  'Alimentos y bebidas (props)',
  'Maquillaje y peluquería',
  'Textiles y telas',
  'Iluminación',
  'Productos de aseo',
  'Materiales',
  'Otros',
];

const kColoresInventario = [
  'Negro',
  'Blanco',
  'Gris',
  'Plateado',
  'Dorado',
  'Rojo',
  'Vinotinto',
  'Naranja',
  'Amarillo',
  'Verde',
  'Verde oliva',
  'Turquesa',
  'Celeste',
  'Azul',
  'Azul oscuro',
  'Morado',
  'Rosado',
  'Beige',
  'Café',
  'Crema',
  'Multicolor',
  'Estampado',
  'Transparente',
];

/// Máximo de fotos por elemento (individuales, sin collage): p. ej.
/// frente, atrás y detalle. Debe coincidir con MAX_FOTOS del backend.
const kMaxFotosInventario = 3;

/// Referencia a una foto de un elemento; el binario se pide aparte con
/// InventoryService.fotoBytes(idFoto).
class InventoryPhotoRef {
  final String idFoto;
  final int orden;
  const InventoryPhotoRef({required this.idFoto, required this.orden});
}

/// Un elemento del inventario (vestuario, utilería, joyas...).
class InventoryItem {
  final String idItem;
  final String idProject;
  final String codigo;
  final String tipo;
  final String? colorPredominante;
  final String? genero;
  final String? descripcion;
  final int cantidad;
  final String? origen;
  final String? destino;
  final String? composicion;
  final String? idDepartamento;
  final String? departamentoNombre;
  final List<InventoryPhotoRef> fotos;
  final DateTime? fechaIngreso;
  final DateTime? fechaActualizacion;

  bool get tieneFoto => fotos.isNotEmpty;

  InventoryItem({
    required this.idItem,
    required this.idProject,
    required this.codigo,
    required this.tipo,
    this.colorPredominante,
    this.genero,
    this.descripcion,
    required this.cantidad,
    this.origen,
    this.destino,
    this.composicion,
    this.idDepartamento,
    this.departamentoNombre,
    this.fotos = const [],
    this.fechaIngreso,
    this.fechaActualizacion,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final fecha = asString(pick(json, ['fecha_actualizacion']));
    final ingreso = asString(pick(json, ['fecha_ingreso']));
    return InventoryItem(
      idItem: asString(pick(json, ['id_item'])) ?? '',
      idProject: asString(pick(json, ['id_project'])) ?? '',
      codigo: asString(pick(json, ['codigo'])) ?? '',
      tipo: asString(pick(json, ['tipo'])) ?? 'Otros',
      colorPredominante: asString(pick(json, ['color_predominante'])),
      genero: asString(pick(json, ['genero'])),
      descripcion: asString(pick(json, ['descripcion'])),
      cantidad: asInt(pick(json, ['cantidad'])) ?? 1,
      origen: asString(pick(json, ['origen'])),
      destino: asString(pick(json, ['destino'])),
      composicion: asString(pick(json, ['composicion'])),
      idDepartamento: asString(pick(json, ['id_departamento'])),
      departamentoNombre: asString(pick(json, ['departamento_nombre'])),
      fotos: asListOfMap(json['fotos'])
          .map((f) => InventoryPhotoRef(
                idFoto: asString(pick(f, ['id_foto'])) ?? '',
                orden: asInt(pick(f, ['orden'])) ?? 1,
              ))
          .where((f) => f.idFoto.isNotEmpty)
          .toList(),
      fechaIngreso: ingreso != null ? DateTime.tryParse(ingreso) : null,
      fechaActualizacion: fecha != null ? DateTime.tryParse(fecha) : null,
    );
  }
}

/// Una página del listado de inventario.
class InventoryPage {
  final List<InventoryItem> items;
  final int total;
  final int unidades;
  final int page;
  final int totalPages;
  const InventoryPage({
    required this.items,
    required this.total,
    required this.unidades,
    required this.page,
    required this.totalPages,
  });
}
