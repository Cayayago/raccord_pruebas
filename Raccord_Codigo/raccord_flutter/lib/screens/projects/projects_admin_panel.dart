import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/permissions.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';

/// Panel de "Gestión de Proyectos" solo para el Administrador: lista de
/// proyectos + buscador + tabla de directores + gráficos por estado, género
/// y formato.
///
/// Es INTERACTIVO al estilo Power BI (filtrado cruzado): al tocar un
/// director, una columna de un gráfico o la búsqueda, todo lo demás se
/// filtra. Un segundo toque sobre lo mismo quita ese filtro. Cada visual
/// calcula sus cifras con los filtros de los OTROS visuales (no con el
/// suyo propio), de modo que lo seleccionado se resalta y sigue visible
/// junto a las demás opciones, como hace Power BI.
class ProjectsAdminPanel extends StatefulWidget {
  final List<Project> projects;
  final ValueChanged<Project> onOpen;
  final VoidCallback onCreate;
  final ValueChanged<Project> onEdit;
  final ValueChanged<Project> onDelete;

  const ProjectsAdminPanel({
    super.key,
    required this.projects,
    required this.onOpen,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProjectsAdminPanel> createState() => _ProjectsAdminPanelState();
}

enum _Dim { director, estado, causal, proyecto, genero, formato }

const _sinDirector = 'Sin director';

/// El campo "director" es texto libre y admite varios ("Ana, Luis" o
/// "Ana y Luis"): se separa para contar cada director por aparte.
List<String> _directoresDe(Project p) {
  final raw = (p.director ?? '').trim();
  if (raw.isEmpty) return [_sinDirector];
  final partes = raw
      .split(RegExp(r'\s*[,;/]\s*|\s+y\s+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();
  return partes.isEmpty ? [_sinDirector] : partes;
}

Color _colorEstado(String estado) {
  switch (estado) {
    case 'en_rodaje':
      return AppColors.success;
    case 'suspendido':
      return AppColors.warning;
    case 'finalizado':
      return AppColors.grisMedio;
    default:
      return AppColors.azulProfundo; // preliminar
  }
}

class _ProjectsAdminPanelState extends State<ProjectsAdminPanel> {
  final _search = TextEditingController();
  final Set<String> _directores = {};
  final Set<String> _estados = {};
  final Set<String> _causales = {};
  final Set<String> _proyectos = {}; // ids de proyecto
  final Set<String> _generos = {};
  final Set<String> _formatos = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hayFiltros =>
      _search.text.trim().isNotEmpty ||
      _directores.isNotEmpty ||
      _estados.isNotEmpty ||
      _causales.isNotEmpty ||
      _proyectos.isNotEmpty ||
      _generos.isNotEmpty ||
      _formatos.isNotEmpty;

  void _toggle(Set<String> set, String key) {
    setState(() {
      if (!set.add(key)) set.remove(key);
    });
  }

  void _limpiar() {
    setState(() {
      _search.clear();
      _directores.clear();
      _estados.clear();
      _causales.clear();
      _proyectos.clear();
      _generos.clear();
      _formatos.clear();
    });
  }

  /// ¿El proyecto cumple los filtros activos? [skip] omite el filtro de
  /// una dimensión (el visual que se está dibujando).
  bool _cumple(Project p, {_Dim? skip}) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty && !p.projectName.toLowerCase().contains(q)) return false;
    if (skip != _Dim.director && _directores.isNotEmpty && !_directoresDe(p).any(_directores.contains)) return false;
    if (skip != _Dim.estado && _estados.isNotEmpty && !_estados.contains(p.estado)) return false;
    if (skip != _Dim.causal && _causales.isNotEmpty && !_causales.contains(p.causalSuspension)) return false;
    if (skip != _Dim.proyecto && _proyectos.isNotEmpty && !_proyectos.contains(p.idProject)) return false;
    if (skip != _Dim.genero && _generos.isNotEmpty && !_generos.contains(p.genero)) return false;
    if (skip != _Dim.formato && _formatos.isNotEmpty && !_formatos.contains(p.formatoDeProduccion)) return false;
    return true;
  }

  /// Conteo por categoría para una dimensión, aplicando los filtros de las
  /// demás. Las categorías salen de TODOS los proyectos para que el gráfico
  /// no cambie de forma al filtrar.
  Map<String, int> _conteo(_Dim dim, Iterable<String> Function(Project) valores, Iterable<String> categorias) {
    final out = {for (final c in categorias) c: 0};
    for (final p in widget.projects) {
      if (!_cumple(p, skip: dim)) continue;
      for (final v in valores(p)) {
        out[v] = (out[v] ?? 0) + 1;
      }
    }
    return out;
  }

  List<_ChartItem> _items(Map<String, int> conteo, {String Function(String)? label, Color Function(String)? color}) {
    final entries = conteo.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    return entries
        .map((e) => _ChartItem(
              key: e.key,
              label: label?.call(e.key) ?? e.key,
              value: e.value,
              color: color?.call(e.key) ?? AppColors.azulProfundo,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final proyectos = widget.projects;
    final filtrados = proyectos.where(_cumple).toList();

    // --- Directores (tabla) ---
    final todosDirectores = {for (final p in proyectos) ..._directoresDe(p)};
    final conteoDir = _conteo(_Dim.director, _directoresDe, todosDirectores);
    final filasDir = conteoDir.entries.where((e) => e.value > 0 || _directores.contains(e.key)).toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });

    // --- Estado (orden fijo del catálogo) ---
    final conteoEstado = _conteo(_Dim.estado, (p) => [p.estado], kEstadosProyecto.keys);
    final itemsEstado = kEstadosProyecto.keys
        .map((k) => _ChartItem(
              key: k,
              label: kEstadosProyecto[k] ?? k,
              value: conteoEstado[k] ?? 0,
              color: _colorEstado(k),
            ))
        .toList();

    // --- Género y formato ---
    final conteoGenero = _conteo(_Dim.genero, (p) => [p.genero], {for (final p in proyectos) p.genero}..remove(''));
    final conteoFormato =
        _conteo(_Dim.formato, (p) => [p.formatoDeProduccion], {for (final p in proyectos) p.formatoDeProduccion}..remove(''));

    // --- Causal de suspensión (solo proyectos suspendidos) ---
    final conteoCausal = _conteo(
      _Dim.causal,
      (p) => p.estado == 'suspendido' && p.causalSuspension != null ? [p.causalSuspension!] : const <String>[],
      kCausalesSuspension.keys,
    );
    final itemsCausal = kCausalesSuspension.keys
        .map((k) => _ChartItem(
              key: k,
              label: kCausalesSuspension[k] ?? k,
              value: conteoCausal[k] ?? 0,
              color: AppColors.warning,
            ))
        .toList();

    // --- Usuarios por proyecto (una barra por proyecto) ---
    final itemsUsuarios = proyectos.where((p) => _cumple(p, skip: _Dim.proyecto)).map((p) {
      return _ChartItem(key: p.idProject, label: p.projectName, value: p.totalUsuarios, color: AppColors.coral);
    }).toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.label.compareTo(b.label);
      });

    // --- Tarjetas de resumen (clic = filtra por estado) ---
    final totalUsuarios = filtrados.fold<int>(0, (s, p) => s + p.totalUsuarios);
    final totalSinEstado = proyectos.where((p) => _cumple(p, skip: _Dim.estado)).length;
    final kpis = [
      _Kpi(label: 'Proyectos', value: '$totalSinEstado', icon: Icons.video_library_outlined, color: AppColors.azulProfundo, selected: _estados.isEmpty, onTap: () => setState(_estados.clear)),
      _Kpi(label: 'En rodaje', value: '${conteoEstado['en_rodaje'] ?? 0}', icon: Icons.videocam_outlined, color: _colorEstado('en_rodaje'), selected: _estados.contains('en_rodaje'), onTap: () => _toggle(_estados, 'en_rodaje')),
      _Kpi(label: 'Suspendidos', value: '${conteoEstado['suspendido'] ?? 0}', icon: Icons.pause_circle_outline, color: _colorEstado('suspendido'), selected: _estados.contains('suspendido'), onTap: () => _toggle(_estados, 'suspendido')),
      _Kpi(label: 'Finalizados', value: '${conteoEstado['finalizado'] ?? 0}', icon: Icons.check_circle_outline, color: _colorEstado('finalizado'), selected: _estados.contains('finalizado'), onTap: () => _toggle(_estados, 'finalizado')),
      _Kpi(label: 'Usuarios', value: '$totalUsuarios', icon: Icons.group_outlined, color: AppColors.coral, selected: false, onTap: null),
    ];
    final kpiRow = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final k in kpis) SizedBox(width: 170, child: k)],
    );

    final graficoCausal = _ColumnChartCard(
      title: 'Causal de suspensión',
      icon: Icons.pause_circle_outline,
      items: itemsCausal,
      selected: _causales,
      onToggle: (k) => _toggle(_causales, k),
      emptyText: 'No hay proyectos suspendidos.',
    );
    final graficoUsuarios = _ColumnChartCard(
      title: 'Usuarios por proyecto',
      icon: Icons.group_outlined,
      items: itemsUsuarios,
      selected: _proyectos,
      onToggle: (k) => _toggle(_proyectos, k),
    );

    final tabla = _DirectorTable(
      rows: filasDir,
      selected: _directores,
      total: filtrados.length,
      onToggle: (k) => _toggle(_directores, k),
    );
    final graficoEstado = _ColumnChartCard(
      title: 'Estado de proyecto',
      icon: Icons.flag_outlined,
      items: itemsEstado,
      selected: _estados,
      onToggle: (k) => _toggle(_estados, k),
    );
    final graficoGenero = _ColumnChartCard(
      title: 'Tipo de género',
      icon: Icons.theater_comedy_outlined,
      items: _items(conteoGenero, color: (_) => AppColors.azulProfundo.withOpacity(0.8)),
      selected: _generos,
      onToggle: (k) => _toggle(_generos, k),
    );
    final graficoFormato = _ColumnChartCard(
      title: 'Formato del proyecto',
      icon: Icons.movie_outlined,
      items: _items(conteoFormato, color: (_) => AppColors.moradoTech.withOpacity(0.8)),
      selected: _formatos,
      onToggle: (k) => _toggle(_formatos, k),
    );

    final lista = _ProjectListCard(
      projects: filtrados,
      totalSinFiltrar: proyectos.length,
      onOpen: widget.onOpen,
      onCreate: widget.onCreate,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );

    final buscador = Semantics(
      label: 'Búsqueda por nombre del proyecto',
      textField: true,
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Búsqueda por nombre del proyecto',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Borrar búsqueda',
                  onPressed: () => setState(() => _search.clear()),
                ),
        ),
      ),
    );

    final chips = _hayFiltros ? _filtrosActivos() : const SizedBox.shrink();

    return LayoutBuilder(builder: (context, c) {
      final ancho = c.maxWidth >= 980;

      if (ancho) {
        // Alto total fijo: la lista de proyectos llega hasta el final de la
        // última fila (Causal / Usuarios) y cada fila de gráficos reparte el
        // alto restante en partes iguales.
        return SizedBox(
          height: 1020,
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 360, child: lista),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buscador,
                  if (_hayFiltros) ...[const SizedBox(height: 12), chips],
                  const SizedBox(height: 16),
                  // Tarjetas estiradas: ocupan todo el ancho hasta el borde
                  // derecho del cuadro "Estado de proyecto".
                  Row(
                    children: [
                      for (var i = 0; i < kpis.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: kpis[i]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: tabla),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: graficoEstado),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: graficoGenero),
                        const SizedBox(width: 16),
                        Expanded(child: graficoFormato),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: graficoCausal),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: graficoUsuarios),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        );
      }

      // Pantallas angostas: todo apilado.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buscador,
          if (_hayFiltros) ...[const SizedBox(height: 12), chips],
          const SizedBox(height: 16),
          kpiRow,
          const SizedBox(height: 16),
          SizedBox(height: 420, child: lista),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: tabla),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: graficoEstado),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: graficoGenero),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: graficoFormato),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: graficoCausal),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: graficoUsuarios),
        ],
      );
    });
  }

  /// Fichas con los filtros activos (cada una se quita tocándola) + "Limpiar".
  Widget _filtrosActivos() {
    final fichas = <Widget>[];
    Widget ficha(String texto, VoidCallback onQuitar) => InputChip(
          label: Text(texto, style: const TextStyle(fontSize: 12)),
          onDeleted: onQuitar,
          visualDensity: VisualDensity.compact,
        );
    final q = _search.text.trim();
    if (q.isNotEmpty) fichas.add(ficha('Nombre: $q', () => setState(() => _search.clear())));
    for (final d in _directores) {
      fichas.add(ficha('Director: $d', () => _toggle(_directores, d)));
    }
    for (final e in _estados) {
      fichas.add(ficha('Estado: ${kEstadosProyecto[e] ?? e}', () => _toggle(_estados, e)));
    }
    for (final c in _causales) {
      fichas.add(ficha('Causal: ${kCausalesSuspension[c] ?? c}', () => _toggle(_causales, c)));
    }
    for (final id in _proyectos) {
      final nombre = widget.projects.where((p) => p.idProject == id).map((p) => p.projectName).firstOrNull ?? id;
      fichas.add(ficha('Proyecto: $nombre', () => _toggle(_proyectos, id)));
    }
    for (final g in _generos) {
      fichas.add(ficha('Género: $g', () => _toggle(_generos, g)));
    }
    for (final f in _formatos) {
      fichas.add(ficha('Formato: $f', () => _toggle(_formatos, f)));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...fichas,
        TextButton.icon(onPressed: _limpiar, icon: const Icon(Icons.filter_alt_off_outlined, size: 16), label: const Text('Limpiar filtros')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta base
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Tarjeta de resumen (KPI). Si [onTap] no es null, filtra al tocarla.
class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  const _Kpi({required this.label, required this.value, required this.icon, required this.color, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected && onTap != null ? color : AppColors.border, width: selected && onTap != null ? 1.5 : 1),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.18), child: Icon(icon, size: 18, color: color)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _CardTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.azulProfundo),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de proyectos (izquierda) + botón Crear
// ---------------------------------------------------------------------------

class _ProjectListCard extends StatefulWidget {
  final List<Project> projects;
  final int totalSinFiltrar;
  final ValueChanged<Project> onOpen;
  final VoidCallback onCreate;
  final ValueChanged<Project> onEdit;
  final ValueChanged<Project> onDelete;

  const _ProjectListCard({
    required this.projects,
    required this.totalSinFiltrar,
    required this.onOpen,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProjectListCard> createState() => _ProjectListCardState();
}

class _ProjectListCardState extends State<_ProjectListCard> {
  static const int _porPagina = 10;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final todos = widget.projects;
    final totalSinFiltrar = widget.totalSinFiltrar;
    final onOpen = widget.onOpen;
    final onEdit = widget.onEdit;
    final onDelete = widget.onDelete;
    final paginas = (todos.length / _porPagina).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(0, paginas - 1);
    final projects = todos.skip(page * _porPagina).take(_porPagina).toList();
    final contador = todos.length == totalSinFiltrar ? '$totalSinFiltrar' : '${todos.length} de $totalSinFiltrar';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            icon: Icons.video_library_outlined,
            title: 'Proyecto(s)',
            trailing: Text(contador, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: projects.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay proyectos con estos filtros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grisMedio, fontSize: 12),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = projects[i];
                      // Editar/eliminar según el rol EFECTIVO en ese proyecto
                      // (Administrador o Director); el backend lo vuelve a validar.
                      final puedeGestionar = hasPermission(p.idRol, 'manage_projects');
                      return _ProjectRow(
                        project: p,
                        onOpen: () => onOpen(p),
                        onEdit: puedeGestionar ? () => onEdit(p) : null,
                        onDelete: puedeGestionar ? () => onDelete(p) : null,
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          // Paginado sobre "Crear Proyecto".
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
          ElevatedButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Crear Proyecto'),
          ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ProjectRow({required this.project, required this.onOpen, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final director = (project.director ?? '').trim();
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: _colorEstado(project.estado), shape: BoxShape.circle),
            ),
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
            Tooltip(
              message: '${project.totalUsuarios} usuarios en el proyecto',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_outlined, size: 14, color: AppColors.grisMedio),
                  const SizedBox(width: 3),
                  Text('${project.totalUsuarios}', style: const TextStyle(fontSize: 12, color: AppColors.grisMedio)),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Editar proyecto',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                tooltip: 'Eliminar proyecto',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabla Nombre director / # Proyecto(s)
// ---------------------------------------------------------------------------

class _DirectorTable extends StatelessWidget {
  final List<MapEntry<String, int>> rows;
  final Set<String> selected;
  final int total;
  final ValueChanged<String> onToggle;

  const _DirectorTable({required this.rows, required this.selected, required this.total, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(icon: Icons.person_outline, title: 'Directores'),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: Text('Nombre director', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.grisMedio))),
              Text('# Proyecto(s)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.grisMedio)),
            ],
          ),
          const Divider(height: 12),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('Sin datos con estos filtros.', style: TextStyle(color: AppColors.grisMedio, fontSize: 12)))
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final e = rows[i];
                      final sel = selected.contains(e.key);
                      return Semantics(
                        button: true,
                        selected: sel,
                        label: 'Director ${e.key}: ${e.value} proyectos',
                        child: InkWell(
                          onTap: () => onToggle(e.key),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.azulProfundo.withOpacity(0.22) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400),
                                  ),
                                ),
                                Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Total de proyectos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              Text('$total', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gráfico de columnas clicable
// ---------------------------------------------------------------------------

class _ChartItem {
  final String key;
  final String label;
  final int value;
  final Color color;
  const _ChartItem({required this.key, required this.label, required this.value, required this.color});
}

class _ColumnChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_ChartItem> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String emptyText;

  const _ColumnChartCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.selected,
    required this.onToggle,
    this.emptyText = 'Todavía no hay datos suficientes.',
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(0, (m, e) => math.max(m, e.value));
    final sinDatos = items.isEmpty || (maxValue == 0 && selected.isEmpty);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(icon: icon, title: title),
          const SizedBox(height: 4),
          const Text('# Proyecto(s)', style: TextStyle(color: AppColors.grisMedio, fontSize: 11)),
          const SizedBox(height: 8),
          Expanded(
            child: sinDatos
                ? Center(child: Text(emptyText, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)))
                : LayoutBuilder(builder: (context, c) {
                    // Con muchas categorías el gráfico se desplaza en horizontal.
                    final anchoMin = items.length * 64.0;
                    final ancho = math.max(c.maxWidth, anchoMin);
                    final plot = SizedBox(
                      width: ancho,
                      height: c.maxHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final it in items)
                            Expanded(
                              child: _ColumnBar(
                                item: it,
                                maxValue: maxValue,
                                selected: selected.contains(it.key),
                                dimmed: selected.isNotEmpty && !selected.contains(it.key),
                                onTap: () => onToggle(it.key),
                              ),
                            ),
                        ],
                      ),
                    );
                    return ancho > c.maxWidth ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: plot) : plot;
                  }),
          ),
        ],
      ),
    );
  }
}

class _ColumnBar extends StatelessWidget {
  final _ChartItem item;
  final int maxValue;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _ColumnBar({required this.item, required this.maxValue, required this.selected, required this.dimmed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.label}: ${item.value} proyectos',
      child: Tooltip(
        message: '${item.label}: ${item.value}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    const reservaTexto = 20.0; // espacio de la cifra sobre la columna
                    final disponible = math.max(0.0, c.maxHeight - reservaTexto);
                    final alto = maxValue == 0 ? 0.0 : (item.value / maxValue) * disponible;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${item.value}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: dimmed ? AppColors.grisMedio : null),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: item.value > 0 ? math.max(alto - 4, 4) : 2,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(dimmed ? 0.28 : 0.9),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            border: selected ? Border.all(color: Colors.white, width: 1.5) : null,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
