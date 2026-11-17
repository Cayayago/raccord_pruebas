import 'package:flutter/material.dart';

import '../../core/permissions.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';

/// Vista de "Proyecto(s)" para móvil y para los roles que NO son
/// Administrador (según el boceto): un filtro (nombre, director, estado),
/// una tarjeta con la lista paginada con flechas ◀ ▶ y, solo si [onCreate]
/// no es null, el botón "Crear Proyecto" al pie.
class ProjectsCompactView extends StatefulWidget {
  final List<Project> projects;
  final ValueChanged<Project> onOpen;
  final VoidCallback? onCreate;
  final ValueChanged<Project> onEdit;
  final ValueChanged<Project> onDelete;
  final int pageSize;

  const ProjectsCompactView({
    super.key,
    required this.projects,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    this.onCreate,
    this.pageSize = 5,
  });

  @override
  State<ProjectsCompactView> createState() => _ProjectsCompactViewState();
}

class _ProjectsCompactViewState extends State<ProjectsCompactView> {
  final _search = TextEditingController();
  String? _director; // null = todos
  String? _estado; // null = todos
  int _page = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _directores {
    final set = <String>{
      for (final p in widget.projects)
        if ((p.director ?? '').trim().isNotEmpty) p.director!.trim(),
    };
    return set.toList()..sort();
  }

  List<Project> get _filtrados {
    final q = _search.text.trim().toLowerCase();
    return widget.projects.where((p) {
      if (q.isNotEmpty && !p.projectName.toLowerCase().contains(q)) return false;
      if (_director != null && (p.director ?? '').trim() != _director) return false;
      if (_estado != null && p.estado != _estado) return false;
      return true;
    }).toList();
  }

  void _resetPage(VoidCallback fn) => setState(() {
        fn();
        _page = 0;
      });

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final paginas = (filtrados.length / widget.pageSize).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(0, paginas - 1);
    final inicio = page * widget.pageSize;
    final visibles = filtrados.skip(inicio).take(widget.pageSize).toList();
    final directores = _directores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Filtro: nombre del proyecto, director y estado ---
        Semantics(
          label: 'Búsqueda por nombre del proyecto',
          textField: true,
          child: TextField(
            controller: _search,
            onChanged: (_) => _resetPage(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre del proyecto',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Borrar búsqueda',
                      onPressed: () => _resetPage(_search.clear),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FiltroDropdown(
                hint: 'Director',
                value: _director,
                opciones: {for (final d in directores) d: d},
                onChanged: (v) => _resetPage(() => _director = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FiltroDropdown(
                hint: 'Estado',
                value: _estado,
                opciones: kEstadosProyecto,
                onChanged: (v) => _resetPage(() => _estado = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Tarjeta "Proyecto(s)" con flechas ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.video_library_outlined, size: 18, color: AppColors.azulProfundo),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Proyecto(s)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                  Text(
                    filtrados.length == widget.projects.length ? '${filtrados.length}' : '${filtrados.length} de ${widget.projects.length}',
                    style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left, size: 36),
                    tooltip: 'Página anterior',
                    onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                  ),
                  Text('${page + 1} / $paginas', style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.arrow_right, size: 36),
                    tooltip: 'Página siguiente',
                    onPressed: page < paginas - 1 ? () => setState(() => _page = page + 1) : null,
                  ),
                ],
              ),
              const Divider(height: 1),
              if (visibles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No hay proyectos para mostrar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grisMedio, fontSize: 13),
                    ),
                  ),
                )
              else
                for (final p in visibles) ...[
                  _Fila(
                    project: p,
                    onOpen: () => widget.onOpen(p),
                    // Editar/eliminar según el rol efectivo en ese proyecto.
                    onEdit: hasPermission(p.idRol, 'manage_projects') ? () => widget.onEdit(p) : null,
                    onDelete: hasPermission(p.idRol, 'manage_projects') ? () => widget.onDelete(p) : null,
                  ),
                  const Divider(height: 1),
                ],
              if (widget.onCreate != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Proyecto'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FiltroDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final Map<String, String> opciones; // valor -> etiqueta
  final ValueChanged<String?> onChanged;
  const _FiltroDropdown({required this.hint, required this.value, required this.opciones, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: opciones.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: hint),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        for (final e in opciones.entries)
          DropdownMenuItem<String?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }
}

class _Fila extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _Fila({required this.project, required this.onOpen, this.onEdit, this.onDelete});

  Color get _color {
    switch (project.estado) {
      case 'en_rodaje':
        return AppColors.success;
      case 'suspendido':
        return AppColors.warning;
      case 'finalizado':
        return AppColors.grisMedio;
      default:
        return AppColors.azulProfundo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final director = (project.director ?? '').trim();
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.projectName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    director.isEmpty ? project.estadoLabel : '${project.estadoLabel} · $director',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Editar proyecto', visualDensity: VisualDensity.compact, onPressed: onEdit),
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), tooltip: 'Eliminar proyecto', visualDensity: VisualDensity.compact, onPressed: onDelete),
            if (onEdit == null && onDelete == null) const Icon(Icons.chevron_right, color: AppColors.grisMedio),
          ],
        ),
      ),
    );
  }
}
