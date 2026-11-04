import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/bulk_import.dart';
import '../../core/responsive.dart';
import '../../core/session.dart';
import '../../models/scene.dart';
import '../../models/script.dart';
import '../../services/scene_service.dart';
import '../../services/script_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/bulk_upload_button.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import 'scene_edit_screen.dart';
import 'scene_gallery_screen.dart';

/// Mockups 6/6.1: Escenas — lista con filtro por estado, orden y
/// paginación; el ojo abre las fotos de continuidad de la escena
/// (SceneGalleryScreen) y el lápiz abre la edición completa
/// (SceneEditScreen, que también incluye la carga de fotos).
class ScenesScreen extends StatefulWidget {
  const ScenesScreen({super.key});

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

enum _SortField { numero, diaDramatico, fecha, ciudad }

const _sortLabels = {
  _SortField.numero: 'Número de Escena',
  _SortField.diaDramatico: 'Día Dramático',
  _SortField.fecha: 'Fecha de Grabación',
  _SortField.ciudad: 'Ciudad',
};

class _ScenesScreenState extends State<ScenesScreen> {
  late Future<List<Scene>> _future;
  String? _filtroEstado;
  // Mismo filtro de "bloque de grabación" que Plan de Rodaje — pedido
  // explícito del usuario para poder ver solo las escenas de un bloque
  // también desde Escenas.
  int? _filtroBloque;
  _SortField _sortField = _SortField.numero;
  bool _sortAsc = true;
  int _page = 0;
  int _pageSize = 10;

  // Vista dividida: al seleccionar una escena (tap en la fila), se
  // muestra el PDF de su guion al lado de la lista — mismo patrón que
  // Desglose de Producción.
  Scene? _selectedScene;
  bool _vistaDividida = false;
  Future<List<int>>? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Scene>> _load() {
    final session = context.read<AuthSession>();
    return SceneService(session.api).all(session.projectId ?? '');
  }

  void _reload() => setState(() {
        _future = _load();
        _page = 0;
      });

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh).
  Future<void> _onPullRefresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  void _selectScene(Scene scene) {
    setState(() {
      _selectedScene = scene;
      // En móvil/tablet (app nativa) la vista dividida no está disponible
      // (ver build()) — solo en PC/Web —, así que no tiene sentido
      // descargar el PDF del guion completo solo para nunca mostrarlo.
      _pdfBytes = (scene.idGuion != null && canUseSplitView(context))
          ? ScriptService(context.read<AuthSession>().api).archivoBytes(scene.idGuion!)
          : null;
    });
  }

  /// El número de escena puede venir como "1", "2A", etc. — se ordena
  /// numéricamente por la parte inicial de dígitos y, si empata (o no
  /// hay dígitos), por el texto completo.
  int _compareNumero(Scene a, Scene b) {
    final na = int.tryParse(RegExp(r'^\d+').stringMatch(a.numeroDeEscena) ?? '');
    final nb = int.tryParse(RegExp(r'^\d+').stringMatch(b.numeroDeEscena) ?? '');
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    return a.numeroDeEscena.compareTo(b.numeroDeEscena);
  }

  List<Scene> _filterSort(List<Scene> scenes) {
    var list = _filtroEstado == null ? scenes : scenes.where((s) => s.estado == _filtroEstado).toList();
    if (_filtroBloque != null) {
      list = list.where((s) => s.bloqueGrabacion == _filtroBloque).toList();
    }
    list = [...list];
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case _SortField.numero:
          cmp = _compareNumero(a, b);
          break;
        case _SortField.diaDramatico:
          cmp = (a.diaDramatico ?? 0).compareTo(b.diaDramatico ?? 0);
          break;
        case _SortField.fecha:
          final fa = a.fechaDeGrabacion;
          final fb = b.fechaDeGrabacion;
          if (fa == null && fb == null) {
            cmp = 0;
          } else if (fa == null) {
            cmp = 1;
          } else if (fb == null) {
            cmp = -1;
          } else {
            cmp = fa.compareTo(fb);
          }
          break;
        case _SortField.ciudad:
          cmp = (a.ciudad ?? '').compareTo(b.ciudad ?? '');
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canEdit = session.can('create_scenes');
    // La vista dividida (guion en PDF al lado de la lista) solo se ofrece
    // en PC/Web — pedido explícito del usuario: en móvil/tablet (app
    // nativa) nunca debe aparecer, sin importar el ancho de pantalla.
    final splitViewAllowed = canUseSplitView(context);
    final mostrarVistaDividida = _vistaDividida && splitViewAllowed;

    return AppScaffold(
      title: 'Escenas',
      showBack: true,
      actions: [
        if (_selectedScene != null && splitViewAllowed)
          IconButton(
            icon: Icon(_vistaDividida ? Icons.vertical_split : Icons.vertical_split_outlined),
            tooltip: _vistaDividida ? 'Cerrar vista dividida' : 'Vista dividida con el guion',
            color: _vistaDividida ? AppColors.azulProfundo : null,
            onPressed: () => setState(() => _vistaDividida = !_vistaDividida),
          ),
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BulkUploadButton(onRows: _bulkCreate, onDone: _reload),
          ),
      ],
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear Escena'),
            )
          : null,
      body: FutureBuilder<List<Scene>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: 'No se pudieron cargar las escenas.', onRetry: _reload);
          final all = snap.data ?? [];
          if (all.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [EmptyView(message: 'Todavía no hay escenas registradas.', icon: Icons.movie_filter_outlined)],
              ),
            );
          }

          final filtered = _filterSort(all);
          final totalPages = filtered.isEmpty ? 1 : ((filtered.length - 1) ~/ _pageSize) + 1;
          final page = _page.clamp(0, totalPages - 1);
          final start = page * _pageSize;
          final pageItems = filtered.skip(start).take(_pageSize).toList();
          final bloquesDisponibles = all.map((s) => s.bloqueGrabacion).whereType<int>().toSet().toList()..sort();

          final listaEscenas = _buildListaEscenas(context, canEdit, filtered, pageItems, totalPages, page, bloquesDisponibles);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: mostrarVistaDividida && _selectedScene != null
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      // En pantallas angostas (móvil/tablet chico) los dos
                      // paneles lado a lado quedan inutilizables (guion y
                      // lista comprimidos con `flex`). A partir de 760px se
                      // ven lado a lado como antes; por debajo, se apilan
                      // verticalmente (guion arriba con alto fijo + lista
                      // debajo), igual que en `scene_edit_screen.dart`.
                      final wide = constraints.maxWidth > 760;
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: _buildScriptPane(context)),
                            const SizedBox(width: 16),
                            const VerticalDivider(width: 1),
                            const SizedBox(width: 16),
                            Expanded(flex: 6, child: listaEscenas),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 420, child: _buildScriptPane(context)),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          // `listaEscenas` trae internamente un ListView
                          // dentro de un Expanded (pensado para vivir dentro
                          // de la Row ancha con stretch); envuelto acá en un
                          // Expanded propio para que reciba una altura
                          // acotada del Column apilado y no truene por alto
                          // sin límite.
                          Expanded(child: listaEscenas),
                        ],
                      );
                    },
                  )
                : listaEscenas,
          );
        },
      ),
    );
  }

  Widget _buildScriptPane(BuildContext context) {
    if (_pdfBytes == null) {
      return const EmptyView(message: 'Esta escena no tiene un guion asociado.', icon: Icons.picture_as_pdf_outlined);
    }
    return FutureBuilder<List<int>>(
      future: _pdfBytes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snap.hasError) {
          // El backend responde 404 cuando el guion todavía no tiene PDF
          // cargado — eso es un estado normal (informativo), no una
          // falla real, así que se muestra como EmptyView en vez de
          // ErrorView (que se ve como un error/bug).
          if (snap.error is ApiException && (snap.error as ApiException).statusCode == 404) {
            return const EmptyView(
              message: 'El guion de esta escena todavía no tiene un PDF cargado.\nSube el PDF desde el módulo Guión para poder verlo aquí.',
              icon: Icons.picture_as_pdf_outlined,
            );
          }
          final message = snap.error is ApiException ? (snap.error as ApiException).message : 'No se pudo cargar el guion.';
          return ErrorView(message: message, onRetry: () => _selectScene(_selectedScene!));
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return const EmptyView(message: 'Este guion todavía no tiene un PDF cargado.', icon: Icons.picture_as_pdf_outlined);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PdfViewer.data(
            Uint8List.fromList(bytes),
            sourceName: 'guion-escenas-${_selectedScene?.idGuion}',
            params: PdfViewerParams(backgroundColor: AppColors.bg),
          ),
        );
      },
    );
  }

  Widget _buildListaEscenas(
    BuildContext context,
    bool canEdit,
    List<Scene> filtered,
    List<Scene> pageItems,
    int totalPages,
    int page,
    List<int> bloquesDisponibles,
  ) {
    return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.grisMedio),
                        const SizedBox(width: 8),
                        DropdownButton<String?>(
                          value: _filtroEstado,
                          underline: const SizedBox.shrink(),
                          dropdownColor: AppColors.surfaceVariant,
                          hint: const Text('Todos los estados'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Todos los estados')),
                            ...kEstadosEscena.map((e) => DropdownMenuItem<String?>(value: e, child: Text(e))),
                          ],
                          onChanged: (v) => setState(() {
                            _filtroEstado = v;
                            _page = 0;
                          }),
                        ),
                      ],
                    ),
                    if (bloquesDisponibles.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Bloque de grabación: ', style: TextStyle(color: AppColors.grisMedio)),
                          DropdownButton<int?>(
                            value: _filtroBloque,
                            underline: const SizedBox.shrink(),
                            dropdownColor: AppColors.surfaceVariant,
                            hint: const Text('Todos'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                              ...bloquesDisponibles.map((b) => DropdownMenuItem<int?>(value: b, child: Text('Bloque $b'))),
                            ],
                            onChanged: (v) => setState(() {
                              _filtroBloque = v;
                              _page = 0;
                            }),
                          ),
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Ordenar por: ', style: TextStyle(color: AppColors.grisMedio)),
                        DropdownButton<_SortField>(
                          value: _sortField,
                          underline: const SizedBox.shrink(),
                          dropdownColor: AppColors.surfaceVariant,
                          items: _SortField.values
                              .map((f) => DropdownMenuItem(value: f, child: Text(_sortLabels[f]!)))
                              .toList(),
                          onChanged: (v) => setState(() => _sortField = v ?? _sortField),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: _sortAsc ? 'Ascendente' : 'Descendente',
                          icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                          onPressed: () => setState(() => _sortAsc = !_sortAsc),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: pageItems.isEmpty
                      ? const EmptyView(message: 'No hay escenas con ese estado.', icon: Icons.filter_alt_off_outlined)
                      : MobileRefresh(
                          onRefresh: _onPullRefresh,
                          child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _SceneRow(
                            scene: pageItems[i],
                            canEdit: canEdit,
                            selected: _selectedScene?.idEscena != null && _selectedScene?.idEscena == pageItems[i].idEscena,
                            onTap: () => _selectScene(pageItems[i]),
                            onView: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SceneGalleryScreen(scene: pageItems[i])),
                            ),
                            onEdit: () async {
                              final changed = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(builder: (_) => SceneEditScreen(scene: pageItems[i])),
                              );
                              if (changed == true) _reload();
                            },
                            onDelete: () => _delete(pageItems[i]),
                          ),
                        ),
                        ),
                ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PaginationBar(
                    page: page,
                    totalPages: totalPages,
                    totalItems: filtered.length,
                    pageSize: _pageSize,
                    itemLabel: 'escena(s)',
                    onPageChanged: (p) => setState(() => _page = p),
                    onPageSizeChanged: (size) => setState(() {
                      _pageSize = size;
                      _page = 0;
                    }),
                  ),
                ],
              ],
            );
  }

  Future<void> _openForm(BuildContext context) async {
    final created = await showCenteredFormSheet<bool>(
      context,
      const _SceneFormSheet(),
    );
    if (created == true) _reload();
  }

  Future<void> _delete(Scene s) async {
    final idEscena = s.idEscena;
    if (idEscena == null) return;

    final confirmed = await confirmDelete(
      context,
      message:
          '¿Eliminar la escena "#${s.numeroDeEscena} · ${s.encabezado}"? '
          'También se eliminarán sus fotos de continuidad, el cast asignado y su desglose. '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;

    final session = context.read<AuthSession>();
    try {
      await SceneService(session.api).delete(idEscena);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escena eliminada')));
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ==========================================
  // CARGA MASIVA
  // ==========================================
  // Columnas esperadas (encabezado, sin importar mayúsculas): numero
  // (o numero_de_escena), encabezado, descripcion, vista (o
  // modo_vista), momento (o momento_dia), ciudad, dia (o
  // dia_dramatico), estado. Solo "numero" y "encabezado" son
  // obligatorias — el resto queda vacío/"Pendiente" si no se llena.
  Future<List<BulkRowResult>> _bulkCreate(List<Map<String, String>> rows) async {
    final session = context.read<AuthSession>();
    final service = SceneService(session.api);
    final results = <BulkRowResult>[];

    var fila = 1;
    for (final row in rows) {
      fila++;
      final numero = _pick(row, ['numero_de_escena', 'numero', 'escena']);
      final encabezado = _pick(row, ['encabezado', 'titulo', 'título']);

      if (numero == null || encabezado == null) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: 'Faltan columnas requeridas (numero, encabezado)'));
        continue;
      }

      final estadoTexto = _pick(row, ['estado']);
      final estado = estadoTexto != null && kEstadosEscena.contains(estadoTexto) ? estadoTexto : 'Pendiente';

      try {
        await service.create(Scene(
          numeroDeEscena: numero,
          encabezado: encabezado,
          descripcion: _pick(row, ['descripcion', 'descripción']),
          modoVista: _pick(row, ['modo_vista', 'vista']),
          momentoDia: _pick(row, ['momento_dia', 'momento']),
          ciudad: _pick(row, ['ciudad']),
          diaDramatico: int.tryParse(_pick(row, ['dia_dramatico', 'dia', 'día']) ?? ''),
          estado: estado,
        ));
        results.add(BulkRowResult(fila: fila, ok: true, detalle: 'Creada correctamente'));
      } on ApiException catch (e) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: e.message));
      } catch (e) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: e.toString()));
      }
    }

    return results;
  }

  String? _pick(Map<String, String> row, List<String> posiblesLlaves) {
    for (final key in posiblesLlaves) {
      final value = row[key];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

Color colorForEstadoEscena(String estado) {
  switch (estado) {
    case 'Finalizada':
      return AppColors.success;
    case 'En proceso':
      return AppColors.warning;
    case 'Eliminada':
      return AppColors.grisMedio;
    default:
      return AppColors.error;
  }
}

class _SceneRow extends StatelessWidget {
  final Scene scene;
  final bool canEdit;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SceneRow({
    required this.scene,
    required this.canEdit,
    this.selected = false,
    this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.azulProfundo : AppColors.border, width: selected ? 2 : 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Las 3 columnas de ancho fijo (`_Field` con su etiqueta
              // apilada arriba) quedan ilegibles en móvil/tablet vertical
              // (se comprimen y el texto se envuelve varias veces). Por
              // debajo de 560px se usa una tarjeta compacta: encabezado en
              // negrita arriba + chips pequeños (día dramático, estado)
              // abajo, sin repetir etiquetas ("Encabezado", "Estado", etc.)
              // que ya se explican solas por su ícono/estilo.
              final wide = constraints.maxWidth > 560;
              if (wide) {
                return Row(
                  children: [
                    // El número de escena (antes visible como "Escena #N")
                    // se mantiene en el modelo/BD y se sigue usando para
                    // ordenar y en el resto de la app (Desglose, Plan de
                    // Rodaje) — pedido explícito del usuario: solo se
                    // oculta de esta lista.
                    Expanded(flex: 6, child: _Field('Encabezado', scene.encabezado)),
                    Expanded(
                      flex: 3,
                      child: _Field('Día Dramático', scene.diaDramatico != null ? '${scene.diaDramatico}' : '—'),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estado', style: TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                          const SizedBox(height: 6),
                          StatusPill(label: scene.estado, color: colorForEstadoEscena(scene.estado)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      tooltip: 'Ver fotos de continuidad',
                      onPressed: onView,
                    ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Editar escena',
                        onPressed: onEdit,
                      ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        tooltip: 'Eliminar escena',
                        onPressed: onDelete,
                      ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          scene.encabezado,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      // Íconos más chicos (18px) y sin el padding grande
                      // por defecto de IconButton, para que no dominen la
                      // tarjeta en una pantalla angosta.
                      _CompactIconButton(icon: Icons.visibility_outlined, tooltip: 'Ver fotos de continuidad', onPressed: onView),
                      if (canEdit) _CompactIconButton(icon: Icons.edit_outlined, tooltip: 'Editar escena', onPressed: onEdit),
                      if (canEdit) _CompactIconButton(icon: Icons.delete_outline, tooltip: 'Eliminar escena', onPressed: onDelete, color: AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (scene.diaDramatico != null)
                        _InfoChip(icon: Icons.auto_stories_outlined, label: 'Día ${scene.diaDramatico}'),
                      StatusPill(label: scene.estado, color: colorForEstadoEscena(scene.estado)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Ícono compacto (18px, sin el padding/tamaño mínimo por defecto de
/// [IconButton], que en pantallas angostas hacía que 2-3 botones ya
/// ocuparan un tercio de la tarjeta) — usado solo en la tarjeta de
/// móvil de [_SceneRow].
class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  const _CompactIconButton({required this.icon, required this.tooltip, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Chip pequeño con ícono + texto, para mostrar datos secundarios (día
/// dramático, etc.) sin repetir una etiqueta encima del valor — mismo
/// patrón usado en la tarjeta de Roles del Equipo.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grisMedio),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Field(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );
  }
}

class _SceneFormSheet extends StatefulWidget {
  const _SceneFormSheet();

  @override
  State<_SceneFormSheet> createState() => _SceneFormSheetState();
}

class _SceneFormSheetState extends State<_SceneFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _encabezado = TextEditingController();
  final _descripcion = TextEditingController();
  final _ciudad = TextEditingController();
  String? _modoVista;
  String? _momentoDia;
  String _estado = kEstadosEscena.first;
  bool _loading = false;

  // Guion de origen de la escena — obligatorio para crearla (ver
  // id_guion en el backend), pedido explícito del usuario (2026-09-02):
  // antes no había forma de elegirlo desde este formulario y el
  // backend rechazaba la creación con "id_guion es obligatorio". Solo
  // se ofrecen guiones "Aprobado" o "En Rodaje" — los demás estados
  // (Borrador, Revisión, Archivado) no están listos para desglosarse en
  // escenas.
  Future<List<Script>>? _guiones;
  String? _idGuion;

  @override
  void initState() {
    super.initState();
    final session = context.read<AuthSession>();
    _guiones = ScriptService(session.api).byProject(session.projectId ?? '').then(
          (list) => list.where((s) => s.estado == 'Aprobado' || s.estado == 'En Rodaje').toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nueva Escena', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            FutureBuilder<List<Script>>(
              future: _guiones,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final guiones = snap.data ?? [];
                if (guiones.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No hay guiones en estado "Aprobado" o "En Rodaje" en este proyecto. '
                      'Cambia el estado del guion desde el módulo Guión para poder crear escenas.',
                      style: TextStyle(color: AppColors.grisMedio, fontSize: 12),
                    ),
                  );
                }
                return AppDropdown<String>(
                  label: 'Guion',
                  value: _idGuion,
                  hint: 'Selecciona el guion de origen',
                  items: guiones.map((g) => g.idGuion!).toList(),
                  labelBuilder: (id) {
                    final g = guiones.firstWhere((g) => g.idGuion == id);
                    return '${g.nombre} · v${g.numeroDeVersion} · ${g.estado}';
                  },
                  onChanged: (v) => setState(() => _idGuion = v),
                );
              },
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Encabezado', hint: 'Título de la escena', controller: _encabezado, validator: _req),
            const SizedBox(height: 16),
            AppTextField(label: 'Descripción', hint: 'Descripción de la escena', controller: _descripcion, maxLines: 3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Espacio',
                    value: _modoVista,
                    hint: 'Seleccione espacio',
                    items: kModosVista,
                    labelBuilder: (e) => e.toUpperCase(),
                    onChanged: (v) => setState(() => _modoVista = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Momento',
                    value: _momentoDia,
                    hint: 'Seleccione momento',
                    items: kMomentosDia,
                    labelBuilder: (e) => e,
                    onChanged: (v) => setState(() => _momentoDia = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AppTextField(label: 'Ciudad', hint: 'Ciudad donde se grabará', controller: _ciudad)),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Estado',
                    value: _estado,
                    items: kEstadosEscena,
                    labelBuilder: (e) => e,
                    onChanged: (v) => setState(() => _estado = v ?? _estado),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idGuion == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona el guion de origen de la escena')));
      return;
    }

    setState(() => _loading = true);
    final session = context.read<AuthSession>();

    try {
      // El campo "Escena (Número)" ya no se pide en este formulario
      // (pedido explícito del usuario) — se calcula solo, como el
      // siguiente consecutivo dentro de ESTE guion (1, 2, 3...).
      final existentes = await SceneService(session.api).byScript(_idGuion!);
      final siguienteNumero = (existentes.length + 1).toString();

      await SceneService(session.api).create(Scene(
        numeroDeEscena: siguienteNumero,
        encabezado: _encabezado.text.trim(),
        descripcion: _descripcion.text.trim(),
        idGuion: _idGuion,
        modoVista: _modoVista,
        momentoDia: _momentoDia,
        ciudad: _ciudad.text.trim(),
        estado: _estado,
      ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
