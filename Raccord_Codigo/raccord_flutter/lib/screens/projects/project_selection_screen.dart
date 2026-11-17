import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions.dart';
import '../../core/session.dart';
import '../../core/theme_controller.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';
import '../../core/onboarding_service.dart';
import 'project_edit_dialog.dart';
import 'project_form_screen.dart';
import 'projects_admin_panel.dart';
import 'projects_compact_view.dart';
import 'projects_tour.dart';

/// Gestión de Proyectos.
///
/// - Administrador en pantalla ancha (PC): panel interactivo con gráficos
///   y filtrado cruzado ([ProjectsAdminPanel]).
/// - Móvil y demás roles: vista compacta con filtro, lista paginada con
///   flechas y, solo para el Administrador, "Crear Proyecto"
///   ([ProjectsCompactView]).
class ProjectSelectionScreen extends StatefulWidget {
  const ProjectSelectionScreen({super.key});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  // Ancho mínimo para mostrar el panel de gráficos del Administrador.
  static const double _anchoPanel = 1000;

  late Future<List<Project>> _future;

  // --- Onboarding (recorrido guiado) ---
  final _tourKeys = ProjectsTourKeys();
  OnboardingService? _onb;
  OnboardingState _onbState = OnboardingState.hidden;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // Después del primer frame para que las llaves del recorrido ya
    // estén montadas y no haya errores de renderizado.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initOnboarding());
  }

  /// El recorrido solo existe en el panel del Administrador en PC.
  bool get _panelActivo {
    final session = context.read<AuthSession>();
    final isAdmin = hasPermission(session.user?.idRol, 'create_project');
    return isAdmin && MediaQuery.of(context).size.width >= _anchoPanel;
  }

  Future<void> _initOnboarding() async {
    if (!mounted) return;
    final id = context.read<AuthSession>().user?.idUser;
    if (id == null || id.isEmpty) return;

    _onb = OnboardingService(userId: id, tourId: 'projects');
    final estado = await _onb!.evaluate();
    if (!mounted) return;
    setState(() => _onbState = estado);

    // Primer ingreso: se lanza solo, sin "Saltar", cuando ya cargaron
    // los proyectos y el panel está dibujado.
    if (!estado.mandatory || !_panelActivo) return;
    try {
      await _future;
    } catch (_) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _lanzarTour(obligatorio: true);
    });
  }

  void _lanzarTour({required bool obligatorio}) {
    if (_tourKeys.lista.currentContext == null) return; // panel aún no dibujado
    showProjectsTour(context, _tourKeys, mandatory: obligatorio, onEnd: _alTerminarTour);
  }

  Future<void> _alTerminarTour() async {
    await _onb?.markCompleted();
    final estado = await _onb?.evaluate();
    if (mounted && estado != null) setState(() => _onbState = estado);
  }

  Future<List<Project>> _load() {
    final session = context.read<AuthSession>();
    final service = ProjectService(session.api);
    return service.myProjects(session.user?.idUser ?? '');
  }

  // Con llaves para que el callback de setState devuelva void y no el
  // Future de _load() (ver crew_list_screen.dart para el detalle del bug).
  void _reload() => setState(() {
        _future = _load();
      });

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh).
  Future<void> _onPullRefresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    // Solo Administrador (1001) puede crear proyectos (ver
    // core/permissions.dart, espejo de app/utils/permissions.py).
    final isAdmin = hasPermission(session.user?.idRol, 'create_project');
    final ancho = MediaQuery.of(context).size.width;
    final usaPanel = isAdmin && ancho >= _anchoPanel;

    return Scaffold(
      appBar: AppBar(
        title: const AppWordmark(fontSize: 20),
        actions: [
          // Días 1-7 con el recorrido completado: botón opcional (con
          // "Saltar"). Pasada la semana desaparece solo.
          if (usaPanel && _onbState.showButton)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: () => _lanzarTour(obligatorio: false),
                icon: const Icon(Icons.help_outline, size: 20),
                label: const Text('Ver Recorrido'),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            onSelected: (v) async {
              if (v == 'perfil') Navigator.of(context).pushNamed('/perfil');
              if (v == 'salir') {
                await session.logout();
                // El login siempre debe quedar en oscuro, sin importar
                // el modo que tenía elegido el usuario.
                if (context.mounted) context.read<ThemeController>().resetToDark();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'perfil', child: Text('Perfil')),
              PopupMenuItem(value: 'salir', child: Text('Salir')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
        // En PC el panel ocupa el alto disponible de la ventana (se adapta
        // al zoom/tamaño) para que todo quepa sin desplazarse; por debajo
        // del mínimo vuelve a aparecer el scroll.
        const reservado = 16 * 2 + 78; // padding vertical + encabezado
        final altoPanel = (c.maxHeight - reservado).clamp(640.0, 2000.0);
        return MobileRefresh(
          onRefresh: _onPullRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: usaPanel ? 16 : 32, horizontal: usaPanel ? 20 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: usaPanel ? 2400 : 640),
                child: Column(
                  children: [
                    if (!usaPanel) ...[
                      const Icon(Icons.movie_creation_outlined, color: AppColors.azulProfundo, size: 44),
                      const SizedBox(height: 12),
                    ],
                    Text('Gestión de Proyectos', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: usaPanel ? 24 : 28)),
                    SizedBox(height: usaPanel ? 4 : 8),
                    Text(
                      usaPanel
                          ? 'Filtra tocando un director o una columna de los gráficos.'
                          : (isAdmin
                              ? 'Accede a un proyecto existente o inicia uno nuevo.'
                              : 'Accede a uno de los proyectos que tienes asignados.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.grisMedio),
                    ),
                    SizedBox(height: usaPanel ? 12 : 24),
                    FutureBuilder<List<Project>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
                        if (snap.hasError) {
                          return ErrorView(message: 'No se pudieron cargar tus proyectos.', onRetry: _reload);
                        }
                        final projects = snap.data ?? [];
                        if (usaPanel) {
                          return ProjectsAdminPanel(
                            height: altoPanel,
                            tourKeys: _tourKeys,
                            projects: projects,
                            onOpen: _selectProject,
                            onCreate: _crear,
                            onEdit: _editar,
                            onDelete: _eliminar,
                          );
                        }
                        if (projects.isEmpty && !isAdmin) {
                          return const EmptyView(
                            message: 'Todavía no tienes proyectos asignados.',
                            icon: Icons.movie_filter_outlined,
                          );
                        }
                        return ProjectsCompactView(
                          projects: projects,
                          onOpen: _selectProject,
                          onCreate: isAdmin ? _crear : null,
                          onEdit: _editar,
                          onDelete: _eliminar,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        }),
      ),
    );
  }

  Future<void> _crear() async {
    final created = await showCreateProjectDialog(context);
    if (created != null) _reload();
  }

  Future<void> _editar(Project p) async {
    final saved = await showEditProjectDialog(context, p);
    if (saved) _reload();
  }

  Future<void> _eliminar(Project p) async {
    final ok = await confirmDelete(
      context,
      title: '¿Eliminar proyecto?',
      message: 'Se eliminará "${p.projectName}" con todo su contenido. Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    final session = context.read<AuthSession>();
    try {
      await ProjectService(session.api).delete(p.idProject);
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo eliminar el proyecto.')));
    }
  }

  Future<void> _selectProject(Project project) async {
    final session = context.read<AuthSession>();
    await session.setProject(project);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
  }
}
