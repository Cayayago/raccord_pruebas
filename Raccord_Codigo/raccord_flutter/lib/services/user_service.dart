import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/user.dart';

class UserService {
  final ApiClient api;
  UserService(this.api);

  Future<AppUser> get(String id) async {
    final data = await api.get('/users/$id');
    return AppUser.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<AppUser>> byProject(String idProject) async {
    final data = await api.get('/users/project/$idProject');
    return asListOfMap(data).map(AppUser.fromJson).toList();
  }

  Future<void> updatePartial(String id, Map<String, dynamic> changes) async {
    await api.patch('/users/$id', body: changes);
  }

  /// Suspende ("suspendido") o reactiva ("activo") a otra persona del
  /// equipo — nunca borra su información, solo le bloquea el login
  /// hasta que alguien con permiso lo reactive. El backend valida quién
  /// puede tocar a quién (Administrador/Director: todo el proyecto;
  /// Jefe de Departamento: solo su propio departamento).
  Future<void> setEstado(String id, String estado) async {
    await api.patch('/users/$id/estado', body: {'estado': estado});
  }

  /// Auto-edición del propio perfil (PATCH /users/me) — a diferencia de
  /// [updatePartial], no requiere permiso `full_management`: cualquier
  /// usuario autenticado puede llamar esto, y el backend siempre opera
  /// sobre su propio registro (nunca acepta un id). El backend además
  /// solo conoce los campos "seguros" (nombre, apellido, identificación,
  /// celular, dirección, fecha de nacimiento) — mail, rol, departamento,
  /// proyecto y estado quedan fuera de este endpoint a propósito.
  Future<void> updateOwnProfile(Map<String, dynamic> changes) async {
    await api.patch('/users/me', body: changes);
  }

  /// Cambia la contraseña del usuario autenticado. El backend exige y
  /// valida `contrasenaActual` antes de aceptar la nueva.
  Future<void> changePassword({required String contrasenaActual, required String nuevaContrasena}) async {
    await api.post('/users/me/password', body: {
      'contrasena_actual': contrasenaActual,
      'nueva_contrasena': nuevaContrasena,
    });
  }

  /// Sube (o reemplaza) la foto de perfil propia. Se guarda en MinIO
  /// (bucket "perfiles"), nunca en Postgres.
  Future<void> uploadOwnPhoto({required List<int> bytes, required String filename, required String contentType}) async {
    await api.postFile(
      '/users/me/foto',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  /// Descarga los bytes de la foto de perfil de cualquier usuario (para
  /// mostrarla en un CircleAvatar). Lanza ApiException con 404 si el
  /// usuario todavía no tiene foto — quien llama debe mostrar el
  /// avatar con iniciales en ese caso, igual que en Roles del Equipo.
  Future<List<int>> photoBytes(String idUser) {
    return api.getBytes('/users/$idUser/foto');
  }
}
