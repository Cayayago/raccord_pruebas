/// Dirección base del backend FastAPI (api_usuarios).
///
/// Por defecto apunta SIEMPRE a http://127.0.0.1:8000, sin importar la
/// plataforma. Esto es intencional: NO se adivina 10.0.2.2 para Android,
/// porque esa dirección solo existe dentro del Emulador de Android — en
/// un celular/tablet físico (que es como se prueba Raccord, por cable
/// USB) esa IP no apunta a ningún lado y la app se queda "cargando"
/// para siempre sin dar ningún error.
///
/// En su lugar, tanto el emulador como un dispositivo físico llegan al
/// backend en 127.0.0.1:8000 usando el mismo mecanismo de ADB:
///
///   adb reverse tcp:8000 tcp:8000
///
/// Ese comando reenvía el puerto 8000 del propio dispositivo/emulador
/// hacia el 127.0.0.1:8000 de la PC (por USB/ADB, funciona incluso en
/// modo avión). Hay que correrlo una vez por cada vez que se conecta el
/// cable (se puede volver a correr sin problema si ya estaba activo).
/// Con eso hecho, `flutter run` funciona tal cual, sin flags extra.
///
/// Si en algún caso se necesita apuntar a otra IP (backend remoto, LAN,
/// etc.), sobreescribe en tiempo de compilación con:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
///
/// También se puede cambiar en caliente con [ApiConfig.override] (por
/// ejemplo desde una pantalla de configuración) para pruebas rápidas.
class ApiConfig {
  ApiConfig._();

  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String? _override;

  static void override(String url) {
    _override = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl {
    if (_override != null && _override!.isNotEmpty) return _override!;
    if (_fromEnv.isNotEmpty) return _fromEnv;
    return 'http://127.0.0.1:8000';
  }
}
