import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/plan_change_tracker.dart';
import '../core/responsive.dart';
import '../core/session.dart';
import '../core/theme_controller.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Botón de acción con ícono + texto para el AppBar (ej. "Agregar
/// Persona", "Invitar persona") que se colapsa a solo el ícono (con
/// tooltip) en pantallas angostas — mismo criterio que
/// [BulkUploadButton]. Antes estos botones con label fijo, sumados a los
/// demás íconos del AppBar, eran los que desbordaban la barra en móvil y
/// tapaban el logo con el aviso de overflow de Flutter.
class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const AppBarActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobileScreen(context)) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: label,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: backgroundColor != null ? Colors.white : null,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: backgroundColor != null ? ElevatedButton.styleFrom(backgroundColor: backgroundColor) : null,
    );
  }
}

/// Los 8 módulos del proyecto (mockups 7, 7.1). Se usan tanto en las
/// tarjetas del dashboard como en el menú lateral de todas las pantallas
/// "dentro" de un proyecto.
// Orden pedido explícitamente por el usuario (2026-09-01): Guión,
// Escenas, Desglose, Plan de Rodaje, Personajes, Cast List, Galería,
// Crew List, Roles.
const appSideMenuItems = [
  ('Guión', Icons.description_outlined, '/guiones'),
  ('Escenas', Icons.movie_filter_outlined, '/escenas'),
  ('Desglose', Icons.checklist_outlined, '/desglose'),
  ('Plan de Rodaje', Icons.event_note_outlined, '/plan-rodaje'),
  ('Personajes', Icons.people_outline, '/personajes'),
  ('Cast List', Icons.theater_comedy_outlined, '/actores'),
  ('Galería', Icons.photo_library_outlined, '/galeria'),
  // Papelera de Reciclaje de fotos (2026-09-23): solo Jefe de
  // Departamento, Director y Administrador (este de solo lectura) la
  // ven — Onset y Usuario ni siquiera saben que existe.
  ('Papelera de Reciclaje', Icons.delete_outline, '/papelera'),
  // Crew List va casi al final del menú porque es el listado de TODAS
  // las personas del proyecto (no solo elenco) — pedido explícito del
  // usuario para no confundirlo con "Cast List".
  ('Crew List', Icons.badge_outlined, '/crew-list'),
  ('Roles', Icons.admin_panel_settings_outlined, '/roles'),
];

// Nombre de la ruta que solo debe verse para roles que sí invitan gente
// al proyecto (Administrador/Director/Jefe de Departamento) — Onset y
// Usuario nunca invitan a nadie, así que ni siquiera deben ver la
// entrada "Roles" en el menú (antes salía para todos los roles, aunque
// el backend ya la rechazaba con 403 para estos dos).
const _kRestrictedMenuRoute = '/roles';

// Papelera de Reciclaje: solo para quienes tienen "view_recycle_bin"
// (Jefe de Departamento, Director y Administrador — Onset y Usuario no
// la ven en absoluto, ver app/utils/permissions.py).
const _kRecycleBinMenuRoute = '/papelera';

// Ruta -> clave de módulo (ver app/utils/module_access.py / ModuloAccesos
// en models/module_access.dart) — para que el menú también respete una
// excepción puntual de "Personalizar accesos" (nivel "sin_acceso"),
// además de la regla de rol de arriba.
const Map<String, String> _kMenuRouteModulo = {
  '/guiones': 'guion',
  '/escenas': 'escenas',
  '/desglose': 'desglose',
  '/plan-rodaje': 'plan_rodaje',
  '/personajes': 'personajes',
  '/actores': 'cast',
  '/galeria': 'galeria',
  '/papelera': 'galeria', // la Papelera comparte el módulo "galeria" (ver override "Personalizar accesos")
  '/crew-list': 'crew_list',
  '/roles': 'roles',
};

/// Reemplaza los `showModalBottomSheet` (hoja pegada al borde inferior)
/// por un diálogo centrado en pantalla — se ve mejor en Web/Desktop, que
/// es donde corre esta app la mayor parte del tiempo. El formulario que
/// se le pasa ya trae su propio scroll/padding interno (ver
/// `_SceneFormSheet`, `_ScriptFormSheet`, etc.), así que acá solo se
/// limita el ancho/alto máximo del diálogo.
Future<T?> showCenteredFormSheet<T>(BuildContext context, Widget child) {
  return showDialog<T>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: child,
      ),
    ),
  );
}

/// Panel con los 8 módulos, usado como contenido del `endDrawer` tipo
/// "hamburguesa" que ahora aparece en TODAS las pantallas dentro de un
/// proyecto (no solo el dashboard), para que la navegación entre módulos
/// esté siempre a un toque de distancia.
class AppSideMenu extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const AppSideMenu({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final session = context.watch<AuthSession>();
    // "Roles" (invitar/gestionar el equipo) solo tiene sentido para
    // quienes SÍ pueden invitar gente al proyecto (Administrador,
    // Director, Jefe de Departamento) — Onset y Usuario nunca invitan a
    // nadie, así que ni siquiera deben ver la entrada en el menú, aunque
    // el backend ya la rechazaba con 403 para ellos. Se evalúa contra el
    // rol EFECTIVO en el proyecto activo (session.can), no el rol global.
    final visibleItems = appSideMenuItems.where((item) {
      if (item.$3 == _kRestrictedMenuRoute && !session.can('invite_users')) return false;
      if (item.$3 == _kRecycleBinMenuRoute && !session.can('view_recycle_bin')) return false;
      final modulo = _kMenuRouteModulo[item.$3];
      if (modulo != null && !session.canSeeModule(modulo)) return false;
      return true;
    });

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ...visibleItems.map((item) => ListTile(
              leading: Icon(item.$2, size: 20),
              title: Text(item.$1),
              onTap: () => onSelect(item.$3),
            )),
        const Divider(),
        SwitchListTile(
          secondary: Icon(themeController.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 20),
          title: const Text('Modo oscuro'),
          subtitle: const Text('Por defecto siempre inicia oscuro', style: TextStyle(fontSize: 11)),
          value: themeController.isDark,
          onChanged: (_) => themeController.toggle(),
        ),
      ],
    );
  }
}

/// Antepone el nombre del proyecto activo al título de la pantalla
/// ("Nubes - Guiones" en vez de solo "Guiones") — pedido explícito del
/// usuario (2026-09-01), aplicado en TODAS las pantallas porque todas
/// pasan por este mismo AppScaffold. Si todavía no hay proyecto activo
/// (ej. la pantalla de "Escoger/Crear Proyecto") se deja el título tal
/// cual, sin anteponer nada.
///
/// Excepción explícita (mismo pedido, 2026-09-01): el Dashboard pasa el
/// nombre del proyecto COMO título (porque ahí no hay un nombre de
/// pantalla distinto que mostrar) — si se antepusiera igual, saldría
/// duplicado ("Nubes - Nubes"). Cuando `title` ya es exactamente el
/// nombre del proyecto, se deja tal cual en vez de repetirlo.
String _titleWithProject(AuthSession session, String title) {
  final nombre = session.projectName;
  if (!session.hasProject || nombre == null || nombre.isEmpty) return title;
  if (title == nombre) return title;
  return '$nombre - $title';
}

// El logo/wordmark y el título del AppBar deben verse SIEMPRE del mismo
// tamaño en cualquier pantalla — pedido explícito del usuario
// (2026-09-20): antes variaban según el ancho de pantalla (más chicos en
// móvil) y además un `FittedBox` los reescalaba según cuánto espacio
// sobrara en cada pantalla puntual, dando tamaños inconsistentes de una
// pantalla a otra. Si el espacio no alcanza, lo que cede es el TEXTO del
// título (se trunca con "...") o se recortan/ocultan otros íconos de la
// barra — nunca el logo.
const kAppWordmarkFontSize = 18.0;
const kAppBarTitleFontSize = 15.0;

/// Scaffold estándar de las pantallas "dentro" de un proyecto: barra
/// superior con wordmark + botón volver opcional + menú de usuario
/// (Perfil / Salir) + menú lateral de módulos, como en los mockups 7,
/// 7.1 y 8.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  // Por defecto el botón "volver" hace un pop normal. Algunas pantallas
  // (como el dashboard del proyecto) llegan aquí con la pila de
  // navegación vacía porque se usó pushNamedAndRemoveUntil, así que
  // necesitan indicar explícitamente a dónde volver.
  final VoidCallback? onBack;
  // Si se pasa un drawer explícito, se usa ese. Si no, y `showModuleMenu`
  // es true (el default), se arma automáticamente el menú de los 8
  // módulos — así todas las pantallas dentro de un proyecto tienen la
  // hamburguesa sin tener que repetir el drawer en cada una.
  final Widget? endDrawer;
  final bool showModuleMenu;
  // Ícono de casa en la barra superior que lleva directo al Dashboard —
  // en todas las pantallas menos el Dashboard mismo (ahí no tiene
  // sentido, ya está en el dashboard).
  final bool showHome;
  // El ícono de notificaciones antes aparecía en TODAS las pantallas —
  // pedido explícito del usuario: dejarlo solo en el Dashboard (que es
  // quien lo activa con showNotifications: true) y liberar ese espacio
  // en el resto, tanto porque no hay nada nuevo que notificar ahí como
  // para darle más aire al logo/título en pantallas angostas.
  final bool showNotifications;
  // Solo el Plan de Rodaje lo activa: al salir (volver, menú, casa, perfil,
  // cambiar proyecto, salir) y haber cambios pendientes, muestra el
  // diálogo "Notificar estos cambios al equipo" — ver
  // core/plan_change_tracker.dart.
  final bool guardPlanChanges;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack = false,
    this.actions,
    this.floatingActionButton,
    this.onBack,
    this.endDrawer,
    this.showModuleMenu = true,
    this.showHome = true,
    this.showNotifications = false,
    this.guardPlanChanges = false,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();

    // Fuerza que TODO lo que esta pantalla recibe ya construido (body,
    // endDrawer personalizado, acciones, FAB) se tire y se reconstruya
    // desde cero al cambiar de modo claro/oscuro — pedido explícito del
    // usuario ("si o si todo debe quedar ajustado al nuevo modo"). El
    // problema: muchas pantallas pintan con `AppColors.bg/surface/...`
    // (getters planos, no un InheritedWidget) en vez de
    // `Theme.of(context)`. Cuando el usuario cambia el modo desde el
    // menú, `ThemeController.notifyListeners()` solo obliga a
    // reconstruirse a los widgets que lo escuchan directamente — y como
    // `body`/`actions`/etc. ya vienen armados por la pantalla que llama
    // a `AppScaffold` (son la MISMA instancia de widget de antes),
    // Flutter los da por "sin cambios" y nunca vuelve a ejecutar su
    // build(), dejándolos con los colores del modo anterior hasta que
    // algo más los reconstruya (navegar y volver, etc.). Envolverlos acá
    // en una Key distinta por modo obliga a Flutter a descartar ese
    // árbol entero y reconstruirlo, sin tocar la pila de navegación.
    final themeMode = context.watch<ThemeController>().mode;
    final themeKey = ValueKey(themeMode);

    // El bloque de `actions` con scroll horizontal reportaba su ancho de
    // CONTENIDO completo (no el disponible) al AppBar, lo que hacía que
    // el NavigationToolbar le diera todo ese espacio y el título quedara
    // tapado/solapado por los íconos. Se acota explícitamente el ancho
    // máximo del bloque de acciones con un `ConstrainedBox`, para que
    // reporte ESE ancho (y no el de todo su contenido) y realmente
    // recorte/scrollee en vez de solaparse con el logo/título — el logo
    // y el título en sí mantienen SIEMPRE el mismo tamaño (ver
    // kAppWordmarkFontSize/kAppBarTitleFontSize arriba).
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    // Con guardPlanChanges, antes de abandonar la pantalla se ofrece
    // notificar los cambios acumulados; false = quedarse en la pantalla.
    Future<bool> canLeave() async {
      if (!guardPlanChanges) return true;
      return PlanChangeTracker.confirmLeave(context);
    }

    final effectiveEndDrawer = endDrawer ??
        (showModuleMenu
            ? Drawer(
                child: SafeArea(
                  child: AppSideMenu(onSelect: (route) async {
                    Navigator.of(context).pop(); // cierra el drawer
                    if (!await canLeave()) return;
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamed(route);
                  }),
                ),
              )
            : null);

    final scaffold = Scaffold(
      endDrawer: effectiveEndDrawer == null ? null : KeyedSubtree(key: themeKey, child: effectiveEndDrawer),
      appBar: AppBar(
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (!await canLeave()) return;
                  if (!context.mounted) return;
                  if (onBack != null) {
                    onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
        automaticallyImplyLeading: showBack,
        // El logo NUNCA se achica (tamaño fijo, kAppWordmarkFontSize) — lo
        // único que cede espacio si la pantalla es angosta es el título
        // (Flexible + ellipsis: se trunca con "..." en vez de desbordar).
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppWordmark(fontSize: kAppWordmarkFontSize),
            if (title.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(width: 1, height: 18, color: AppColors.border),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _titleWithProject(session, title),
                  style: const TextStyle(fontSize: kAppBarTitleFontSize),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        // Todas las acciones (home, las que trae cada pantalla,
        // notificaciones, menú y avatar) se envuelven en un solo scroll
        // horizontal en vez de una Row plana: con varias pantallas
        // agregando 1-2 íconos propios (Roles, Escenas, Desglose...),
        // en móvil angosto (~360-400px) la suma de íconos ya no cabe y
        // una Row normal dentro de `actions` no protege contra overflow
        // (a diferencia del `title`, que sí tiene `Flexible`+ellipsis).
        // El scroll horizontal garantiza que nunca se corte ni se salga
        // de pantalla, a costa de requerir un swipe si sobran íconos.
        actions: [
          ConstrainedBox(
            // Sin este límite explícito, un SingleChildScrollView dentro
            // de `actions` reporta el ancho de TODO su contenido (no el
            // disponible) al AppBar — acotarlo fuerza a que realmente
            // recorte/scrollee en vez de solaparse con el wordmark.
            constraints: BoxConstraints(maxWidth: isNarrow ? screenWidth * 0.42 : double.infinity),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHome)
                    IconButton(
                      icon: const Icon(Icons.home_outlined),
                      tooltip: 'Ir al Dashboard',
                      onPressed: () async {
                        if (!await canLeave()) return;
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
                      },
                    ),
                if (actions != null) KeyedSubtree(key: themeKey, child: Row(mainAxisSize: MainAxisSize.min, children: actions!)),
                // Solo en el Dashboard (showNotifications: true) — pedido
                // explícito del usuario: en el resto de pantallas no
                // aporta nada y solo le quita espacio al logo/título.
                // Desde 2026-09-27 ya es el módulo real de Notificaciones
                // (antes solo mostraba "próximamente"), con badge de no
                // leídas — ver _NotificationsBellButton más abajo.
                if (showNotifications) const _NotificationsBellButton(),
                if (effectiveEndDrawer != null)
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Menú',
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: CircleAvatar(
                    backgroundColor: AppColors.azulProfundo,
                    radius: 16,
                    child: Text(
                      (session.user?.nombre.isNotEmpty ?? false) ? session.user!.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  onSelected: (value) async {
                    if (!await canLeave()) return;
                    if (!context.mounted) return;
                    if (value == 'perfil') {
                      Navigator.of(context).pushNamed('/perfil');
                    } else if (value == 'proyectos') {
                      await session.clearProject();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/proyectos', (r) => false);
                      }
                    } else if (value == 'salir') {
                      await session.logout();
                      // El login siempre debe quedar en oscuro, sin
                      // importar el modo que tenía elegido el usuario.
                      if (context.mounted) context.read<ThemeController>().resetToDark();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'perfil', child: Row(children: [Icon(Icons.person_outline, size: 18), SizedBox(width: 10), Text('Perfil')])),
                    PopupMenuItem(value: 'proyectos', child: Row(children: [Icon(Icons.movie_creation_outlined, size: 18), SizedBox(width: 10), Text('Cambiar proyecto')])),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'salir', child: Row(children: [Icon(Icons.logout, size: 18, color: AppColors.error), SizedBox(width: 10), Text('Salir', style: TextStyle(color: AppColors.error))])),
                  ],
                ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: KeyedSubtree(key: themeKey, child: body)),
      floatingActionButton: floatingActionButton == null ? null : KeyedSubtree(key: themeKey, child: floatingActionButton!),
    );

    if (!guardPlanChanges) return scaffold;

    // Botón/gesto "atrás" del sistema (Android, navegador): si hay cambios
    // pendientes se intercepta y se ofrece notificarlos antes de salir.
    final hasPending = context.watch<PlanChangeTracker>().hasPending;
    return PopScope(
      canPop: !hasPending,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await PlanChangeTracker.confirmLeave(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: scaffold,
    );
  }
}

/// Campana de Notificaciones (2026-09-27): pide el contador de no
/// leídas una vez al construirse y muestra un badge si hay alguna. Al
/// tocarla, navega a /notificaciones — desde ahí, al volver, la
/// próxima vez que este botón se reconstruya (ej. al reabrir el
/// Dashboard) el contador se vuelve a pedir solo.
class _NotificationsBellButton extends StatefulWidget {
  const _NotificationsBellButton();

  @override
  State<_NotificationsBellButton> createState() => _NotificationsBellButtonState();
}

class _NotificationsBellButtonState extends State<_NotificationsBellButton> {
  late Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<int> _load() {
    final session = context.read<AuthSession>();
    if (!session.hasProject) return Future.value(0);
    return NotificationService(session.api).unreadCount(session.projectId!);
  }

  Future<void> _abrir() async {
    await Navigator.of(context).pushNamed('/notificaciones');
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _future,
      builder: (context, snap) {
        final noLeidas = snap.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notificaciones',
              onPressed: _abrir,
            ),
            if (noLeidas > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Text(
                    noLeidas > 9 ? '9+' : '$noLeidas',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tarjeta de módulo usada en el dashboard del proyecto (mockup 7).
class ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        // El ícono, el padding y el texto se calculan proporcionales al
        // ancho real de la tarjeta (no de la pantalla completa) — así en
        // PC se ven grandes de verdad, y en la grilla 2x2 de móvil (donde
        // cada tarjeta es más angosta) todo se achica en conjunto en vez
        // de quedar un ícono chico con un padding/botón de tamaño fijo
        // "sobrando" espacio, que era lo que las hacía verse infladas.
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final radius = (w * 0.22).clamp(22.0, 46.0);
          final padding = (w * 0.12).clamp(10.0, 20.0);
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: radius,
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white, size: radius * 0.9),
                ),
                SizedBox(height: padding * 0.7),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: w < 160 ? 13 : 14),
                ),
                SizedBox(height: padding * 0.6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: w < 160 ? ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), textStyle: const TextStyle(fontSize: 12)) : null,
                    child: const Text('Ver más'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
