import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import '../../core/dropdown_format.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../models/catalog.dart';
import '../../models/inventory_item.dart';
import '../../services/department_service.dart';
import '../../services/inventory_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';

const _kModulo = 'inventario';
const _kPageSize = 60;

/// Módulo Inventario: elementos físicos de la producción (vestuario,
/// utilería, joyas, decoración...) con su foto, en una cuadrícula
/// parecida a la Galería. Cada foto muestra su CANTIDAD en la esquina
/// superior; al tocarla se abre en formato Polaroid con todos los
/// datos, desde donde se puede editar (datos y foto) o eliminar.
///
/// Todos los roles parten con el mismo acceso; se restringe por persona
/// desde Roles del Equipo > "Personalizar accesos" (módulo Inventario):
/// ver = solo consultar, editar = crear/editar, administrar = eliminar.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  String? _tipo;
  String? _color;
  String? _genero;
  int _page = 1;

  late Future<InventoryPage> _future;
  final Map<String, Future<List<int>>> _fotos = {};

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<InventoryPage> _fetch() {
    final session = context.read<AuthSession>();
    return InventoryService(session.api).list(
      session.projectId ?? '',
      q: _search.text.trim(),
      tipo: _tipo,
      color: _color,
      genero: _genero,
      page: _page,
      pageSize: _kPageSize,
    );
  }

  void _reload({bool resetPage = false}) {
    // Con llaves: setState no debe devolver un Future.
    setState(() {
      if (resetPage) _page = 1;
      _future = _fetch();
    });
  }

  Future<void> _onPullRefresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  /// Un Future por foto (los ids son únicos y la imagen nunca cambia),
  /// para no volver a descargarla cada vez que se reconstruye la cuadrícula.
  Future<List<int>> _fotoBytes(String idFoto) {
    return _fotos.putIfAbsent(idFoto, () => InventoryService(context.read<AuthSession>().api).fotoBytes(idFoto));
  }

  Future<void> _openForm([InventoryItem? item]) async {
    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InventoryFormDialog(existing: item),
    );
    if (guardado == true) _reload();
  }

  Future<void> _openViewer(InventoryItem item) async {
    final session = context.read<AuthSession>();
    final cambio = await showDialog<bool>(
      context: context,
      builder: (_) => _InventoryViewerDialog(
        item: item,
        fotoBytes: _fotoBytes,
        canEdit: session.hasModuleLevel(_kModulo, 'editar'),
        canDelete: session.hasModuleLevel(_kModulo, 'administrar'),
      ),
    );
    if (cambio == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canEdit = session.hasModuleLevel(_kModulo, 'editar');

    return AppScaffold(
      title: 'Inventario',
      showBack: true,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar elemento'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<InventoryPage>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
                  if (snap.hasError) {
                    final err = snap.error;
                    return ErrorView(
                      message: err is ApiException ? err.message : 'No se pudo cargar el inventario.',
                      onRetry: _reload,
                    );
                  }
                  final page = snap.data!;
                  final hayFiltros = _search.text.trim().isNotEmpty || _tipo != null || _color != null || _genero != null;

                  if (page.items.isEmpty) {
                    return MobileRefresh(
                      onRefresh: _onPullRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          EmptyView(
                            message: hayFiltros
                                ? 'Ningún elemento coincide con los filtros.'
                                : 'Todavía no hay elementos en el inventario.',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${page.total} elemento(s)  ·  ${page.unidades} unidad(es) en total',
                          style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: MobileRefresh(
                          onRefresh: _onPullRefresh,
                          child: GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 90),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 210,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemCount: page.items.length,
                            itemBuilder: (context, i) {
                              final item = page.items[i];
                              return _InventoryTile(
                                item: item,
                                foto: item.tieneFoto ? _fotoBytes(item.fotos.first.idFoto) : null,
                                onTap: () => _openViewer(item),
                              );
                            },
                          ),
                        ),
                      ),
                      if (page.totalPages > 1) _buildPager(page),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

    Widget filtro(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
      return SizedBox(
        width: 190,
        child: DropdownButtonFormField<String?>(
          initialValue: value,
          isExpanded: true,
          decoration: deco(hint),
          dropdownColor: Theme.of(context).colorScheme.surface,
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('$hint (todos)')),
            ...sortedAlpha<String>(items, (s) => s)
                .map((e) => DropdownMenuItem<String?>(value: e, child: Text(capitalizeFirst(e), overflow: TextOverflow.ellipsis))),
          ],
          onChanged: onChanged,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por código, descripción, origen...',
              isDense: true,
            ),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                if (mounted) _reload(resetPage: true);
              });
            },
          ),
        ),
        filtro('Tipo', _tipo, kTiposInventario, (v) {
          _tipo = v;
          _reload(resetPage: true);
        }),
        filtro('Color', _color, kColoresInventario, (v) {
          _color = v;
          _reload(resetPage: true);
        }),
        filtro('Género', _genero, kGenerosInventario, (v) {
          _genero = v;
          _reload(resetPage: true);
        }),
      ],
    );
  }

  Widget _buildPager(InventoryPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page.page > 1
                ? () {
                    _page = page.page - 1;
                    _reload();
                  }
                : null,
          ),
          Text('Página ${page.page} de ${page.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page.page < page.totalPages
                ? () {
                    _page = page.page + 1;
                    _reload();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Miniatura de la cuadrícula
// ============================================================
class _InventoryTile extends StatelessWidget {
  final InventoryItem item;
  final Future<List<int>>? foto;
  final VoidCallback onTap;

  const _InventoryTile({required this.item, required this.foto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.surfaceVariant,
              child: foto == null
                  ? const Center(child: Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.grisMedio))
                  : FutureBuilder<List<int>>(
                      future: foto,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                        }
                        if (snap.hasError || snap.data == null) {
                          return const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grisMedio));
                        }
                        return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
                      },
                    ),
            ),
            // Cantidad: esquina superior de la imagen.
            Positioned(top: 6, right: 6, child: _QuantityBadge(cantidad: item.cantidad)),
            // Si tiene más de una foto, se avisa con un contador.
            if (item.fotos.length > 1)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('${item.fotos.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            // Franja inferior con código y tipo.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    Text(
                      item.tipo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  final int cantidad;
  const _QuantityBadge({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.moradoTech,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Text(
        '×$cantidad',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

// ============================================================
// Visor Polaroid con detalles, editar y eliminar
// ============================================================
class _InventoryViewerDialog extends StatefulWidget {
  final InventoryItem item;
  final Future<List<int>> Function(String idFoto) fotoBytes;
  final bool canEdit;
  final bool canDelete;

  const _InventoryViewerDialog({required this.item, required this.fotoBytes, required this.canEdit, required this.canDelete});

  @override
  State<_InventoryViewerDialog> createState() => _InventoryViewerDialogState();
}

class _InventoryViewerDialogState extends State<_InventoryViewerDialog> {
  bool _deleting = false;
  int _fotoActual = 0; // índice de la foto que se está viendo

  InventoryItem get _item => widget.item;

  void _irAFoto(int i) {
    if (i < 0 || i >= _item.fotos.length) return;
    setState(() => _fotoActual = i);
  }

  Widget _flecha(IconData icono, VoidCallback? onTap) {
    return Material(
      color: onTap == null ? Colors.black26 : Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icono, size: 22, color: onTap == null ? Colors.white38 : Colors.white),
        ),
      ),
    );
  }

  Future<void> _edit() async {
    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InventoryFormDialog(existing: _item),
    );
    if (guardado == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await confirmDelete(
      context,
      message: '¿Eliminar "${_item.codigo}" del inventario? Se borran también sus fotos y no se puede deshacer.',
    );
    if (!confirmed) return;
    setState(() => _deleting = true);
    final session = context.read<AuthSession>();
    try {
      await InventoryService(session.api).delete(_item.idItem);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 10))],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: Colors.black,
                            child: _item.fotos.isEmpty
                                ? const Center(child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white38))
                                : FutureBuilder<List<int>>(
                                    key: ValueKey(_item.fotos[_fotoActual].idFoto),
                                    future: widget.fotoBytes(_item.fotos[_fotoActual].idFoto),
                                    builder: (context, snap) {
                                      if (snap.hasError) {
                                        return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40));
                                      }
                                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                                      return InteractiveViewer(
                                        minScale: 1,
                                        maxScale: 5,
                                        child: Center(child: Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.contain)),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        Positioned(top: 8, right: 8, child: _QuantityBadge(cantidad: _item.cantidad)),
                        if (_item.fotos.length > 1) ...[
                          Positioned(
                            left: 6,
                            top: 0,
                            bottom: 0,
                            child: Center(child: _flecha(Icons.chevron_left, _fotoActual > 0 ? () => _irAFoto(_fotoActual - 1) : null)),
                          ),
                          Positioned(
                            right: 6,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _flecha(
                                Icons.chevron_right,
                                _fotoActual < _item.fotos.length - 1 ? () => _irAFoto(_fotoActual + 1) : null,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _item.fotos.length; i++)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == _fotoActual ? Colors.white : Colors.white38,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Papel blanco del Polaroid: textos siempre oscuros.
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_item.codigo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(_item.tipo, style: const TextStyle(color: Color(0xFF666666))),
                        const SizedBox(height: 10),
                        _fila('Color predominante', _item.colorPredominante),
                        _fila('Género', _item.genero),
                        _fila('Cantidad', '${_item.cantidad}'),
                        _fila('Fecha de ingreso', _item.fechaIngreso == null ? null : _fmtFecha(_item.fechaIngreso!)),
                        _fila('Departamento', _item.departamentoNombre),
                        _fila('Composición', _item.composicion),
                        _fila('Origen', _item.origen),
                        _fila('Destino', _item.destino),
                        _fila('Descripción', _item.descripcion),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.canDelete)
                        TextButton.icon(
                          onPressed: _deleting ? null : _delete,
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          label: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
                        ),
                      if (widget.canEdit)
                        TextButton.icon(
                          onPressed: _deleting ? null : _edit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                      TextButton(
                        onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fila(String label, String? valor) {
    if (valor == null || valor.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Color(0xFF777777), fontSize: 12)),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

// ============================================================
// Formulario crear / editar
// ============================================================
enum _FotoOrigen { camara, archivos }

String _two(int n) => n.toString().padLeft(2, '0');

/// dd/mm/aaaa para mostrar.
String _fmtFecha(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// aaaa-mm-dd para enviar al backend.
String _isoFecha(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

class _InventoryFormDialog extends StatefulWidget {
  final InventoryItem? existing;
  const _InventoryFormDialog({this.existing});

  @override
  State<_InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<_InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _codigo = TextEditingController(text: widget.existing?.codigo ?? '');
  late final _cantidad = TextEditingController(text: '${widget.existing?.cantidad ?? 1}');
  late final _descripcion = TextEditingController(text: widget.existing?.descripcion ?? '');
  late final _origen = TextEditingController(text: widget.existing?.origen ?? '');
  late final _destino = TextEditingController(text: widget.existing?.destino ?? '');
  late final _composicion = TextEditingController(text: widget.existing?.composicion ?? '');

  late String _tipo = widget.existing?.tipo ?? kTiposInventario.first;
  late String? _color = widget.existing?.colorPredominante;
  late String? _genero = widget.existing?.genero;
  late String? _idDepto = widget.existing?.idDepartamento;

  // Fecha de ingreso: hoy por defecto al crear; editable con el calendario.
  late DateTime _fechaIngreso = widget.existing?.fechaIngreso ?? DateTime.now();

  Future<void> _pickFechaIngreso() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoy.year + 5, 12, 31),
    );
    if (elegida != null && mounted) setState(() => _fechaIngreso = elegida);
  }

  List<Department> _departamentos = [];

  // Fotos (máximo 3, individuales): las ya guardadas, las que se
  // marcaron para quitar al guardar y las nuevas pendientes de subir.
  late final List<InventoryPhotoRef> _fotosExistentes = List.of(widget.existing?.fotos ?? const <InventoryPhotoRef>[]);
  final List<String> _fotosAEliminar = [];
  final List<_NuevaFoto> _fotosNuevas = [];
  final Map<String, Future<List<int>>> _miniaturas = {};

  Future<List<int>> _miniatura(String idFoto) => _miniaturas.putIfAbsent(
        idFoto,
        () => InventoryService(context.read<AuthSession>().api).fotoBytes(idFoto),
      );
  bool _saving = false;

  int get _totalFotos => _fotosExistentes.length + _fotosNuevas.length;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _cargarDepartamentos();
  }

  @override
  void dispose() {
    for (final c in [_codigo, _cantidad, _descripcion, _origen, _destino, _composicion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDepartamentos() async {
    try {
      final deps = await DepartmentService(context.read<AuthSession>().api).all();
      if (mounted) setState(() => _departamentos = deps);
    } catch (_) {
      // Sin departamentos el campo simplemente queda vacío.
    }
  }

  /// Valores guardados que ya no están en el catálogo se conservan.
  List<String> _catalogWith(List<String> base, String? actual) {
    if (actual == null || actual.isEmpty || base.contains(actual)) return base;
    return [actual, ...base];
  }

  Future<_FotoOrigen?> _askSource() {
    final showCamera = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    return showDialog<_FotoOrigen>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text('¿De dónde quieres subir la foto?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (showCamera)
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Tomar foto con la cámara'),
                    onTap: () => Navigator.of(ctx).pop(_FotoOrigen.camara),
                  ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Elegir de la galería / carpeta'),
                  onTap: () => Navigator.of(ctx).pop(_FotoOrigen.archivos),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (_totalFotos >= kMaxFotosInventario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo $kMaxFotosInventario fotos por elemento. Quita una para agregar otra.')),
      );
      return;
    }
    final origen = await _askSource();
    if (origen == null) return;

    Uint8List? bytes;
    String? nombre;
    if (origen == _FotoOrigen.camara) {
      try {
        final foto = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (foto == null) return;
        bytes = await foto.readAsBytes();
        nombre = foto.name;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo acceder a la cámara. Verifica los permisos del navegador/dispositivo.')),
          );
        }
        return;
      }
    } else {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked == null) return;
      bytes = await picked.readAsBytes();
      nombre = picked.name;
    }

    if (mounted) {
      setState(() => _fotosNuevas.add(_NuevaFoto(bytes!, nombre ?? 'foto.jpg')));
    }
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String? _requiredCantidad(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 0) return 'Número entero (0 o más)';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<AuthSession>();
    final service = InventoryService(session.api);
    final cantidad = int.parse(_cantidad.text.trim());

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await service.update(widget.existing!.idItem, {
          'codigo': _codigo.text.trim(),
          'tipo': _tipo,
          'color_predominante': _color,
          'genero': _genero,
          'descripcion': _descripcion.text.trim(),
          'cantidad': cantidad,
          'origen': _origen.text.trim(),
          'destino': _destino.text.trim(),
          'composicion': _composicion.text.trim(),
          'id_departamento': _idDepto,
          'fecha_ingreso': _isoFecha(_fechaIngreso),
        });
        // Primero se quitan las marcadas (libera cupo) y luego se suben las nuevas.
        for (final id in _fotosAEliminar) {
          await service.deletePhoto(id);
        }
        for (final f in _fotosNuevas) {
          await service.addPhoto(
            widget.existing!.idItem,
            bytes: f.bytes,
            filename: f.nombre,
            contentType: _contentTypeFor(f.nombre),
          );
        }
      } else {
        final creado = await service.create(
          session.projectId ?? '',
          tipo: _tipo,
          codigo: _codigo.text,
          colorPredominante: _color,
          genero: _genero,
          descripcion: _descripcion.text,
          cantidad: cantidad,
          origen: _origen.text,
          destino: _destino.text,
          composicion: _composicion.text,
          idDepartamento: _idDepto,
          fechaIngreso: _isoFecha(_fechaIngreso),
        );
        // Las fotos se suben una a una (individuales, sin collage).
        try {
          for (final f in _fotosNuevas) {
            await service.addPhoto(
              creado.idItem,
              bytes: f.bytes,
              filename: f.nombre,
              contentType: _contentTypeFor(f.nombre),
            );
          }
        } on ApiException catch (e) {
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Elemento creado, pero una foto no se pudo subir: ${e.message}. Edítalo para volver a intentarlo.')),
            );
          }
          return;
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Elemento actualizado' : 'Elemento agregado al inventario')),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar elemento' : 'Agregar elemento',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPhotoPicker(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              label: 'Código',
                              hint: 'Opcional: se asigna solo (INV-0001...)',
                              controller: _codigo,
                              validator: (v) => (_isEditing && (v ?? '').trim().isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              label: 'Cantidad',
                              controller: _cantidad,
                              keyboardType: TextInputType.number,
                              validator: _requiredCantidad,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppSearchDropdown(
                        label: 'Tipo de elemento',
                        value: _tipo,
                        hint: 'Escribe o selecciona el tipo',
                        items: _catalogWith(kTiposInventario, _tipo),
                        onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppSearchDropdown(
                              label: 'Color predominante',
                              value: _color,
                              hint: 'Selecciona color',
                              items: _catalogWith(kColoresInventario, _color),
                              onChanged: (v) => setState(() => _color = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppDropdown<String?>(
                              label: 'Género',
                              value: _genero,
                              hint: 'Sin especificar',
                              items: [null, ...kGenerosInventario],
                              labelBuilder: (g) => g ?? 'Sin especificar',
                              onChanged: (v) => setState(() => _genero = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppDropdown<String?>(
                        // La lista llega async: la key fuerza a reconstruir el
                        // desplegable (usa initialValue) cuando ya está cargada.
                        key: ValueKey('depto-${_departamentos.length}'),
                        label: 'Departamento al que pertenece',
                        value: _departamentos.any((d) => d.idDepartamento == _idDepto) ? _idDepto : null,
                        hint: 'Sin departamento',
                        items: [null, ..._departamentos.map((d) => d.idDepartamento)],
                        labelBuilder: (id) {
                          if (id == null) return 'Sin departamento';
                          final d = _departamentos.where((x) => x.idDepartamento == id);
                          return d.isEmpty ? id : d.first.nombre;
                        },
                        onChanged: (v) => setState(() => _idDepto = v),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _saving ? null : _pickFechaIngreso,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de ingreso',
                            suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          child: Text(_fmtFecha(_fechaIngreso)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(label: 'Composición', hint: 'Ej. 100% algodón, cuero, metal...', controller: _composicion),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Origen',
                        hint: 'Ej. Propio, Bodega Central, Alquiler...',
                        controller: _origen,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Destino',
                        hint: 'Ej. Se vende, Devuelto, Lo tiene Arte...',
                        controller: _destino,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(label: 'Descripción', controller: _descripcion, maxLines: 3),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEditing ? 'Guardar cambios' : 'Agregar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb({required Widget image, required VoidCallback onRemove}) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: _saving ? null : onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final puedeAgregar = _totalFotos < kMaxFotosInventario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos ($_totalFotos/$kMaxFotosInventario) · ej. frente, atrás y detalle',
          style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final f in _fotosExistentes)
              _thumb(
                image: FutureBuilder<List<int>>(
                  future: _miniatura(f.idFoto),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: 110, height: 110);
                    }
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: snap.hasError
                            ? const Icon(Icons.broken_image_outlined, color: AppColors.grisMedio)
                            : const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  },
                ),
                onRemove: () => setState(() {
                  _fotosExistentes.remove(f);
                  _fotosAEliminar.add(f.idFoto);
                }),
              ),
            for (final n in _fotosNuevas)
              _thumb(
                image: Image.memory(n.bytes, fit: BoxFit.cover, width: 110, height: 110),
                onRemove: () => setState(() => _fotosNuevas.remove(n)),
              ),
            if (puedeAgregar)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _saving ? null : _pickPhoto,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.grisMedio),
                      SizedBox(height: 6),
                      Text('Agregar foto', style: TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Foto elegida en el formulario que aún no se ha subido.
class _NuevaFoto {
  final Uint8List bytes;
  final String nombre;
  const _NuevaFoto(this.bytes, this.nombre);
}
