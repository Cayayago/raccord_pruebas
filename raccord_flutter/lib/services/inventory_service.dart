import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/json_utils.dart';
import '../models/inventory_item.dart';

/// Módulo Inventario — ver inventory_routes.py en el backend.
class InventoryService {
  final ApiClient api;
  InventoryService(this.api);

  Future<InventoryPage> list(
    String idProject, {
    String q = '',
    String? tipo,
    String? color,
    String? genero,
    String? idDepartamento,
    int page = 1,
    int pageSize = 60,
  }) async {
    final params = <String, String>{
      if (q.isNotEmpty) 'q': q,
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
      if (color != null && color.isNotEmpty) 'color': color,
      if (genero != null && genero.isNotEmpty) 'genero': genero,
      if (idDepartamento != null && idDepartamento.isNotEmpty) 'id_departamento': idDepartamento,
      'page': '$page',
      'page_size': '$pageSize',
    };
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final data = await api.get('/inventario/project/$idProject?$qs');
    final map = Map<String, dynamic>.from(data as Map);
    return InventoryPage(
      items: asListOfMap(map['items']).map(InventoryItem.fromJson).toList(),
      total: (map['total'] as num?)?.toInt() ?? 0,
      unidades: (map['unidades'] as num?)?.toInt() ?? 0,
      page: (map['page'] as num?)?.toInt() ?? page,
      totalPages: (map['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  /// Crea el elemento (con foto opcional). Si [codigo] va vacío el
  /// backend asigna INV-0001, INV-0002...
  Future<InventoryItem> create(
    String idProject, {
    required String tipo,
    String? codigo,
    String? colorPredominante,
    String? genero,
    String? descripcion,
    int cantidad = 1,
    String? origen,
    String? destino,
    String? composicion,
    String? idDepartamento,
    String? fechaIngreso,
    List<int>? bytes,
    String? filename,
    String? contentType,
  }) async {
    String? v(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final fields = <String, String>{
      'tipo': tipo,
      'cantidad': '$cantidad',
      if (v(codigo) != null) 'codigo': v(codigo)!,
      if (v(colorPredominante) != null) 'color_predominante': v(colorPredominante)!,
      if (v(genero) != null) 'genero': v(genero)!,
      if (v(descripcion) != null) 'descripcion': v(descripcion)!,
      if (v(origen) != null) 'origen': v(origen)!,
      if (v(destino) != null) 'destino': v(destino)!,
      if (v(composicion) != null) 'composicion': v(composicion)!,
      if (v(idDepartamento) != null) 'id_departamento': v(idDepartamento)!,
      if (v(fechaIngreso) != null) 'fecha_ingreso': v(fechaIngreso)!,
    };
    final data = await api.postFile(
      '/inventario/project/$idProject',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: fields,
    );
    if (data is! Map) {
      throw ApiException('El servidor no confirmó la creación del elemento. Inténtalo de nuevo.', errorCode: 'NO_RESPONSE');
    }
    return InventoryItem.fromJson(Map<String, dynamic>.from(data));
  }

  /// Edición parcial: solo viajan las claves de [campos].
  Future<InventoryItem> update(String idItem, Map<String, dynamic> campos) async {
    final data = await api.patch('/inventario/$idItem', body: campos);
    return InventoryItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Agrega una foto individual al elemento (máximo 3 por elemento).
  Future<InventoryItem> addPhoto(
    String idItem, {
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final data = await api.postFile(
      '/inventario/$idItem/fotos',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    if (data is! Map) {
      throw ApiException('El servidor no confirmó la subida de la foto. Inténtalo de nuevo.', errorCode: 'NO_RESPONSE');
    }
    return InventoryItem.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<int>> fotoBytes(String idFoto) => api.getBytes('/inventario/fotos/$idFoto/archivo');

  Future<void> deletePhoto(String idFoto) async {
    await api.delete('/inventario/fotos/$idFoto');
  }

  Future<void> delete(String idItem) async {
    await api.delete('/inventario/$idItem');
  }
}
