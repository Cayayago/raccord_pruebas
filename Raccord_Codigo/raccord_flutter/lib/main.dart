import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show BrowserContextMenu;
import 'package:provider/provider.dart';
// import 'package:screen_protector/screen_protector.dart'; // ver nota 2026-09-20 más abajo

import 'core/navigation_keys.dart';
import 'core/plan_change_tracker.dart';
import 'core/session.dart';
import 'core/theme_controller.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_register_screen.dart';
import 'screens/auth/two_factor_screen.dart';
import 'screens/breakdown/breakdown_screen.dart';
import 'screens/characters/actor_form_screen.dart';
import 'screens/characters/actors_screen.dart';
import 'screens/characters/characters_screen.dart';
import 'screens/characters/crew_list_screen.dart';
import 'screens/dashboard/project_dashboard_screen.dart';
import 'screens/gallery/gallery_screen.dart';
import 'screens/gallery/recycle_bin_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/projects/project_form_screen.dart';
import 'screens/projects/project_selection_screen.dart';
import 'screens/roles/roles_screen.dart';
import 'screens/scenes/scenes_screen.dart';
import 'screens/scripts/scripts_screen.dart';
import 'screens/shooting_days/shooting_days_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';
import 'widgets/inactivity_watcher.dart';
import 'widgets/offline_banner.dart';

// ==========================================
// PROTECCION CONTRA CAPTURAS DE PANTALLA
// ==========================================
// IMPORTANTE (limitacion real, no un bug): en la version WEB no existe
// ninguna API de navegador para bloquear un screenshot de verdad — ni
// Chrome, ni Edge, ni Safari la exponen. Lo unico que se puede hacer
// ahi es desalentar (deshabilitar el menu de clic derecho), nunca
// impedir una captura con Print Screen, la Herramienta de Recortes, o
// una foto con el celular a la pantalla. La proteccion real solo
// aplica cuando esta app corre como APK/IPA nativo:
//   - Android: FLAG_SECURE real — la captura sale en negro.
//   - iOS: Apple no permite bloquear el screenshot en si, pero si
//     oculta el contenido en el selector de apps (app switcher) y se
//     puede detectar cuando alguien grabo pantalla.
// El paquete screen_protector no tiene implementacion web, por eso se
// guarda todo detras de "!kIsWeb" y con try/catch: si algun dia se
// compila Raccord como app nativa, la proteccion real queda activa
// sin tocar nada mas aca.
//
// PAUSADO 2026-09-20 (temporal): screen_protector 1.5.3 no compila en
// Android con el "Built-in Kotlin" de Flutter 3.44+/AGP 9+ — bug
// confirmado y todavía abierto en el repo del paquete (issues #66,
// #67, #68, #70 en github.com/prongbang/screen_protector). Mientras
// no publiquen el fix (o se resuelva la combinación exacta de
// versiones Gradle/AGP/Kotlin), esta protección queda apagada SOLO en
// nativo para poder compilar. El deterrente web (clic derecho) sigue
// activo, no depende de este paquete. Para reactivar: descomentar el
// import de arriba, el bloque de abajo, y agregar de nuevo
// "screen_protector: ^1.5.3" en pubspec.yaml.
Future<void> _protegerPantalla() async {
  if (kIsWeb) {
    // Unico deterrente real posible en navegador: apagar el menu
    // contextual (clic derecho) que ofrece "Guardar imagen como...".
    // No bloquea capturas, solo quita un atajo comodo.
    BrowserContextMenu.disableContextMenu();
    return;
  }

  // try {
  //   await ScreenProtector.preventScreenshotOn();
  //   // En Android, ademas oculta el contenido en la vista de apps
  //   // recientes (donde Android toma una miniatura automatica).
  //   await ScreenProtector.protectDataLeakageWithBlur();
  // } catch (_) {
  //   // Si corre en una plataforma sin soporte (ej. desktop), no debe
  //   // tumbar el arranque de la app por esto.
  // }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _protegerPantalla();

  // Por defecto, cuando un widget lanza una excepción durante su
  // construcción, Flutter muestra una caja gris SIN texto (el
  // ErrorWidget por defecto no imprime el mensaje salvo en modo
  // debug con overlay rojo, y en release queda completamente en
  // blanco/gris — indistinguible del fondo). Esto es exactamente lo
  // que pasaba con el visor de PDF: si Syncfusion fallaba al
  // construirse, no se veía nada. Con este override, cualquier error
  // de construcción se ve como texto legible en pantalla, en
  // cualquier modo (debug o release), para poder diagnosticarlo.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: const Color(0xFF2A2A38),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        'Ocurrió un error al mostrar este contenido:\n${details.exceptionAsString()}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthSession()..bootstrap()),
        // Controla modo oscuro/claro desde el menú hamburguesa. Vive solo
        // en memoria a propósito: cada vez que se abre la app arranca en
        // oscuro, sin importar lo que se haya elegido en la sesión anterior.
        ChangeNotifierProvider(create: (_) => ThemeController()),
        // Cambios acumulados del Plan de Rodaje pendientes de notificar al
        // equipo (ver core/plan_change_tracker.dart).
        ChangeNotifierProvider(create: (_) => PlanChangeTracker()),
      ],
      child: const RaccordApp(),
    ),
  );
}

class RaccordApp extends StatelessWidget {
  const RaccordApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      title: 'Raccord',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.mode,
      home: const _SplashGate(),
      onGenerateRoute: _onGenerateRoute,
      // Envuelve TODO el árbol de rutas (por encima del Navigator) para
      // poder detectar actividad del usuario (click/toque/scroll/tecla)
      // sin importar la pantalla en la que esté, y cerrar la sesión tras
      // 15 minutos de inactividad — ver widgets/inactivity_watcher.dart.
      // OfflineBannerWidget va POR FUERA: así el banner de "sin
      // conexión" se ve por encima de todo (incluidos diálogos), en
      // TODA la app (login, 2FA, selección de proyecto, dashboard...),
      // no solo en las pantallas con AppScaffold.
      builder: (context, child) => OfflineBannerWidget(
        child: InactivityWatcher(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  Widget page;

  switch (settings.name) {
    case '/login':
      page = const LoginRegisterScreen();
      break;
    case '/2fa':
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      page = TwoFactorScreen(
        mail: args['mail'] as String? ?? '',
        contrasena: args['contrasena'] as String? ?? '',
      );
      break;
    case '/olvide-password':
      page = const ForgotPasswordScreen();
      break;
    case '/proyectos':
      page = const ProjectSelectionScreen();
      break;
    case '/registrar-proyecto':
      page = const RegisterProjectScreen();
      break;
    case '/dashboard':
      page = const ProjectDashboardScreen();
      break;
    case '/roles':
      page = const RolesScreen();
      break;
    case '/guiones':
      page = const ScriptsScreen();
      break;
    case '/escenas':
      page = const ScenesScreen();
      break;
    case '/personajes':
      page = const CharactersScreen();
      break;
    case '/actores':
      page = const ActorsScreen();
      break;
    case '/actor-form':
      page = ActorFormScreen(idPersonaje: settings.arguments as String?);
      break;
    case '/crew-list':
      page = const CrewListScreen();
      break;
    case '/plan-rodaje':
      page = const ShootingDaysScreen();
      break;
    case '/desglose':
      page = const BreakdownScreen();
      break;
    case '/galeria':
      page = const GalleryScreen();
      break;
    case '/papelera':
      page = const RecycleBinScreen();
      break;
    case '/notificaciones':
      page = const NotificationsScreen();
      break;
    case '/perfil':
      page = const ProfileScreen();
      break;
    default:
      return null;
  }

  return MaterialPageRoute(builder: (_) => page, settings: settings);
}

/// Decide la primera pantalla según el estado de sesión persistido:
/// sin token -> Login; con token pero sin proyecto activo -> Selección
/// de proyecto; con proyecto -> Dashboard.
class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();

    if (!session.ready) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIsotipo(size: 88),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.azulProfundo),
            ],
          ),
        ),
      );
    }

    if (!session.isAuthenticated) return const LoginRegisterScreen();
    if (!session.hasProject) return const ProjectSelectionScreen();
    return const ProjectDashboardScreen();
  }
}
