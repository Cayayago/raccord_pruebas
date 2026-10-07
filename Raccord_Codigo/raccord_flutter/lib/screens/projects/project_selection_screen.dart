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
import 'project_form_screen.dart';

/// Mockups 3 y 6: Gestión de Proyectos.
class ProjectSelectionScreen extends StatefulWidget {
  const ProjectSelectionScreen({super.key});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  late Future<List<Project>> _future;
  // La lista de proyectos ya no se muestra de entrada: solo aparece cuando
  // la persona toca "Escoger Proyecto", para que la pantalla inicial se
  // vea limpia (solo las dos tarjetas de acción).
  bool _showProjects = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // Solo Administrador (1001) puede crear proyectos nuevos (ver
    // core/permissions.dart, espejo de app/utils/permissions.py). Para
    // el resto de roles la tarjeta "Crear Proyecto" ni siquiera se
    // muestra, así que de una vez les mostramos su lista de proyectos
    // asignados: es la única acción que tienen disponible en esta
    // pantalla.
    final session = context.read<AuthSession>();
    if (!hasPermission(session.user?.idRol, 'create_project')) {
      _showProjects = true;
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const AppWordmark(fontSize: 20),
        actions: [
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
        child: MobileRefresh(
          onRefresh: _onPullRefresh,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
          // Se centra todo el contenido y se limita su ancho máximo para
          // que, en pantallas anchas (navegador de escritorio), las
          // tarjetas no queden estiradas pegadas a los bordes — 900 en
          // vez de 640: aprovecha mejor pantallas grandes sin llegar a
          // ocupar todo el ancho (pedido explícito del usuario).
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  const Icon(Icons.movie_creation_outlined, color: AppColors.azulProfundo, size: 52),
                  const SizedBox(height: 16),
                  const Text('Gestión de Proyectos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 30)),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final session = context.watch<AuthSession>();
                    final canCreate = hasPermission(session.user?.idRol, 'create_project');
                    return Text(
                      canCreate
                          ? 'Accede a un proyecto existente o inicia uno nuevo en el sistema.'
                          : 'Accede a uno de los proyectos que tienes asignados.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.grisMedio),
                    );
                  }),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final session = context.watch<AuthSession>();
                      final canCreate = hasPermission(session.user?.idRol, 'create_project');

                      final cards = [
                        _OptionCard(
                          icon: Icons.folder_open_outlined,
                          title: 'Escoger Proyecto',
                          subtitle: 'Acceder a un proyecto existente',
                          onTap: () => setState(() => _showProjects = true),
                        ),
                        // Solo Administrador (1001) puede crear proyectos;
                        // el resto de roles (Director incluido) solo puede
                        // elegir entre los que ya tiene asignados, así que
                        // esta tarjeta directamente no se muestra para
                        // ellos en vez de aparecer deshabilitada.
                        if (canCreate)
                          _OptionCard(
                            icon: Icons.add,
                            title: 'Crear Proyecto',
                            subtitle: 'Registrar un nuevo proyecto',
                            onTap: () async {
                              final created = await showCreateProjectDialog(context);
                              if (created != null) _reload();
                            },
                          ),
                      ];

                      if (cards.length == 1) return cards.first;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 420;
                          return narrow
                              ? Column(children: [cards[0], const SizedBox(height: 12), cards[1]])
                              : Row(
                                  children: [
                                    Expanded(child: cards[0]),
                                    const SizedBox(width: 16),
                                    Expanded(child: cards[1]),
                                  ],
                                );
                        },
                      );
                    },
                  ),
                  if (_showProjects) ...[
                    const SizedBox(height: 24),
                    FutureBuilder<List<Project>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
                        if (snap.hasError) {
                          return ErrorView(message: 'No se pudieron cargar tus proyectos.', onRetry: _reload);
                        }
                        final projects = snap.data ?? [];
                        if (projects.isEmpty) {
                          return const EmptyView(
                            message: 'Todavía no tienes proyectos. Crea el primero arriba.',
                            icon: Icons.movie_filter_outlined,
                          );
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.video_library_outlined, size: 18, color: AppColors.azulProfundo),
                                    const SizedBox(width: 8),
                                    const Text('Proyectos disponibles', style: TextStyle(fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    Text('${projects.length} proyectos', style: const TextStyle(color: AppColors.grisMedio)),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              ...projects.map((p) => _ProjectTile(project: p, onTap: () => _selectProject(p))),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectProject(Project project) async {
    final session = context.read<AuthSession>();
    await session.setProject(project);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            CircleAvatar(radius: 30, backgroundColor: AppColors.surfaceVariant, child: Icon(icon, color: AppColors.azulProfundo, size: 28)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppColors.grisMedio, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  const _ProjectTile({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: const Icon(Icons.movie_outlined, color: AppColors.azulProfundo)),
      title: Text(project.projectName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(project.resumen, style: const TextStyle(color: AppColors.grisMedio)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
