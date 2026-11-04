import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/json_utils.dart';
import '../models/gallery_photo.dart';

/// Fotos de continuidad visual de una escena (mockup "Continuidad
/// Visual"). El binario vive en la base de datos — se sube con
/// multipart/form-data y se descarga aparte con [archivoBytes].
class GalleryService {
  final ApiClient api;
  GalleryService(this.api);

  Future<List<GalleryPhoto>> byScene(String idEscena) async {
    final data = await api.get('/scenes/$idEscena/fotos');
    return asListOfMap(data).map(GalleryPhoto.fromJson).toList();
  }

  /// Todas las fotos de todas las escenas del proyecto — Galería global
  /// (gallery_screen.dart). Cada foto ya trae numero_de_escena/encabezado
  /// embebidos (ver GalleryPhoto.numeroDeEscenaOrigen/encabezadoEscenaOrigen).
  // Antes /fotos sin filtro devolvía las fotos de TODOS los proyectos.
  Future<List<GalleryPhoto>> all(String idProject) async {
    final data = await api.get('/fotos/project/$idProject');
    return asListOfMap(data).map(GalleryPhoto.fromJson).toList();
  }

  Future<GalleryPhoto> upload(
    String idEscena, {
    required String tipoFoto,
    String? personajeCodigo,
    String? descripcion,
    String? notasContinuidad,
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final data = await api.postFile(
      '/scenes/$idEscena/fotos',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: {
        'tipo_foto': tipoFoto,
        if (personajeCodigo != null && personajeCodigo.isNotEmpty) 'personaje_codigo': personajeCodigo,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        if (notasContinuidad != null && notasContinuidad.isNotEmpty) 'notas_continuidad': notasContinuidad,
      },
    );
    // ApiClient._parse devuelve null si la respuesta vino sin cuerpo o
    // con un cuerpo que no pudo decodificar como JSON — antes eso hacía
    // que `data as Map` lanzara un TypeError crudo ("type Null is not a
    // subtype of type Map") que escapaba como excepción NO-ApiException
    // y quedaba sin mensaje claro para el usuario. Se convierte acá en
    // un error explícito y entendible.
    if (data is! Map) {
      throw ApiException('El servidor no confirmó la subida de la foto. Verifica tu conexión e inténtalo de nuevo.', errorCode: 'UPLOAD_NO_RESPONSE');
    }
    return GalleryPhoto.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<int>> archivoBytes(String idFoto) {
    return api.getBytes('/fotos/$idFoto/archivo');
  }

  /// Edición parcial de los detalles de una foto ya subida (visor
  /// Polaroid) — solo manda las claves presentes en [campos], nunca
  /// el archivo/binario en sí. Claves válidas: tipo_foto,
  /// personaje_codigo, descripcion, notas_continuidad.
  Future<GalleryPhoto> update(String idFoto, Map<String, dynamic> campos) async {
    final data = await api.patch('/fotos/$idFoto', body: campos);
    return GalleryPhoto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Mueve la foto a la Papelera de Reciclaje (soft-delete: Onset,
  /// Jefe de Departamento y Director pueden hacerlo — el Administrador
  /// ya no, ver app/utils/permissions.py del backend).
  Future<void> delete(String idFoto) async {
    await api.delete('/fotos/$idFoto');
  }

  /// Papelera de reciclaje del proyecto — visible para Jefe de
  /// Departamento, Director y Administrador (este último de solo
  /// lectura, ver recycle_bin_screen.dart).
  Future<List<GalleryPhoto>> papelera(String idProject) async {
    final data = await api.get('/fotos/papelera/$idProject');
    return asListOfMap(data).map(GalleryPhoto.fromJson).toList();
  }

  /// Restaura una foto desde la Papelera (solo Jefe de Departamento y
  /// Director).
  Future<void> restaurar(String idFoto) async {
    await api.post('/fotos/$idFoto/restaurar', body: const {});
  }

  /// Elimina la foto DEFINITIVAMENTE desde la Papelera (solo Jefe de
  /// Departamento y Director) — sin vuelta atrás.
  Future<void> eliminarDefinitivo(String idFoto) async {
    await api.delete('/fotos/$idFoto/definitivo');
  }
}
