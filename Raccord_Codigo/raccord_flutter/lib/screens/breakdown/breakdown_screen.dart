import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/pdf_export.dart';
import '../../core/responsive.dart';
import '../../core/session.dart';
import '../../core/watermark.dart';
import '../../models/breakdown.dart';
import '../../models/scene.dart';
import '../../services/breakdown_service.dart';
import '../../services/scene_service.dart';
import '../../services/script_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';
import '../scenes/scenes_screen.dart' show colorForEstadoEscena;

/// Íconos por categoría de desglose — puramente decorativo, para que la
/// grilla se pueda "leer" de un vistazo en vez de solo texto plano
/// (mismo espíritu que las tarjetas de categoría de FilmScript).
const Map<String, IconData> _kIconoCategoria = {
  'Props': Icons.inventory_2_outlined,
  'Extras': Icons.groups_outlined,
  'Bits': Icons.category_outlined,
  'SFX': Icons.whatshot_outlined,
  'Sonido': Icons.graphic_eq_outlined,
  'Stunts': Icons.sports_martial_arts_outlined,
  'Vestuario': Icons.checkroom_outlined,
  'Maquillaje/Pelo': Icons.face_retouching_natural_outlined,
  'Maquillaje FX': Icons.masks_outlined,
  'Cámara': Icons.videocam_outlined,
  'VFX': Icons.auto_awesome_outlined,
  'Armas': Icons.shield_outlined,
  'Vehículos': Icons.directions_car_outlined,
  'Animales': Icons.pets_outlined,
  'Arte': Icons.palette_outlined,
  'Música': Icons.music_note_outlined,
  'Crew Adicional': Icons.badge_outlined,
  'Notas': Icons.sticky_note_2_outlined,
};

IconData _iconoCategoria(String categoria) => _kIconoCategoria[categoria] ?? Icons.label_outline;

// Paleta cíclica para el borde superior de cada tarjeta de categoría —
// igual idea que los colores por categoría de la hoja de desglose de
// FilmScript (ELENCO, EXTRAS, UTILERÍA... cada una con su color).
const List<Color> _kPaletaCategorias = [
  Color(0xFFE0685A), // elenco/props - rojo coral
  Color(0xFFE0A23D), // extras - ámbar
  Color(0xFFC9A227), // bits - dorado
  Color(0xFFD6544A), // sfx - rojo
  Color(0xFF3D9E8F), // sonido - verde azulado
  Color(0xFFB0464E), // stunts - vino
  Color(0xFFD98FA3), // vestuario - rosa
  Color(0xFFE0A6AE), // maquillaje/pelo - rosa claro
  Color(0xFF9A6FD0), // maquillaje fx - violeta
  Color(0xFF4A90D9), // cámara - azul
  Color(0xFF7B5FCF), // vfx - morado tech
  Color(0xFF708090), // armas - gris pizarra
  Color(0xFF3D9E6F), // vehículos - verde
  Color(0xFFA0824A), // animales - marrón
  Color(0xFF5FA8D3), // arte - celeste
  Color(0xFF8F6FD0), // música - lila
  Color(0xFF4A8FD9), // crew adicional - azul
  Color(0xFFC2A15C), // notas - beige oscuro
];

Color _colorCategoria(String categoria) {
  final i = kCategoriasDesglose.indexOf(categoria);
  return _kPaletaCategorias[(i < 0 ? 0 : i) % _kPaletaCategorias.length];
}

/// Mockup 11: Desglose de Producción — rediseñado siguiendo el
/// referente de FilmScript que trajo el usuario: header de escena con
/// los datos clave como "badges", grilla de tarjetas por categoría
/// (todas visibles, no solo las que tienen items) y un toggle de
/// "Vista dividida" que muestra el PDF del guion al lado del desglose.
class BreakdownScreen extends StatefulWidget {
  const BreakdownScreen({super.key});

  @override
  State<BreakdownScreen> createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends State<BreakdownScreen> {
  late Future<List<Scene>> _scenesFuture;
  Scene? _selectedScene;
  List<DesgloseItem>? _items;
  bool _loadingItems = false;
  String? _itemsError;
  bool _vistaDividida = false;

  Future<List<int>>? _pdfBytes;

  /// Todas las escenas ya cargadas (mismo Future que alimenta el
  /// selector de arriba) — se guardan acá aparte porque el header de la
  /// escena seleccionada necesita ver las fechas de grabación de TODAS
  /// las escenas para calcular el día de rodaje (ver
  /// [_diaDeRodajeCalculado]), no solo la seleccionada.
  List<Scene> _allScenes = [];

  // Guard contra condición de carrera: si el usuario selecciona una
  // escena y, antes de que esa petición termine, selecciona otra (o
  // reintenta), la respuesta de la petición VIEJA llegaba después y su
  // `finally` apagaba `_loadingItems` de la petición NUEVA (todavía en
  // vuelo) sin datos ni error que mostrar — la pantalla quedaba
  // "congelada" sin spinner y sin contenido, indistinguible de un
  // cuelgue real. Cada llamada a `_selectScene` toma un número de turno;
  // solo la última en curso puede tocar el estado.
  int _selectToken = 0;

  @override
  void initState() {
    super.initState();
    _scenesFuture = _loadScenes();
  }

  Future<List<Scene>> _loadScenes() async {
    final session = context.read<AuthSession>();
    final scenes = await SceneService(session.api).all(session.projectId ?? '');
    scenes.sort(_compareNumeroEscena);
    if (mounted) setState(() => _allScenes = scenes);
    return scenes;
  }

  /// El número de escena puede venir como "1", "2A", "10", etc. — un
  /// `compareTo` de texto ordena "10" antes que "2" (orden alfabético).
  /// Acá se ordena numéricamente por la parte inicial de dígitos y, si
  /// empata (o no hay dígitos), por el texto completo — mismo criterio
  /// que usa la pantalla de Escenas.
  int _compareNumeroEscena(Scene a, Scene b) {
    final na = int.tryParse(RegExp(r'^\d+').stringMatch(a.numeroDeEscena) ?? '');
    final nb = int.tryParse(RegExp(r'^\d+').stringMatch(b.numeroDeEscena) ?? '');
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    return a.numeroDeEscena.compareTo(b.numeroDeEscena);
  }

  /// Día de rodaje = posición cronológica (1, 2, 3...) de la fecha de
  /// grabación de esta escena entre TODAS las fechas de grabación
  /// distintas usadas en las escenas del proyecto — no es un campo que
  /// se edite a mano, se recalcula solo a partir de las fechas ya
  /// asignadas. Ej.: fechas de grabación 01, 05, 06, 07, 12 de agosto ->
  /// día de rodaje 1, 2, 3, 4, 5 respectivamente. Si luego alguien
  /// asigna una fecha 10 de agosto a otra escena, esa pasa a ser el día
  /// de rodaje 5 y el 12 de agosto pasa a ser el día 6 (pedido explícito
  /// del usuario).
  int? _diaDeRodajeCalculado(Scene scene, List<Scene> todasLasEscenas) {
    final fecha = scene.fechaDeGrabacion;
    if (fecha == null) return null;
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final fechas = todasLasEscenas
        .map((s) => s.fechaDeGrabacion)
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();
    final idx = fechas.indexOf(dia);
    return idx == -1 ? null : idx + 1;
  }

  Future<void> _selectScene(Scene scene) async {
    final token = ++_selectToken;
    setState(() {
      _selectedScene = scene;
      _loadingItems = true;
      _itemsError = null;
      _items = null;
      _pdfBytes = null;
    });

    final session = context.read<AuthSession>();
    // La vista dividida (y por lo tanto el PDF del guion) solo existe en
    // PC/Web, y solo tiene sentido descargarlo si además está prendida —
    // antes se descargaba igual aunque estuviera apagada.
    if (scene.idGuion != null && canUseSplitView(context) && _vistaDividida) {
      // Con llaves para que el callback de setState devuelva void y no
      // el Future de archivoBytes() (mismo bug que en crew_list_screen.dart
      // — con body de una sola expresión, Dart hace que setState()
      // "devuelva" el Future en vez de nada, y Flutter lo rechaza antes
      // de reconstruir el widget).
      setState(() {
        _pdfBytes = ScriptService(session.api).archivoBytes(scene.idGuion!);
      });
    }
    try {
      final items = await BreakdownService(session.api).itemsByScene(scene.idEscena!);
      // Si mientras esta petición estaba en vuelo el usuario ya
      // seleccionó OTRA escena (token cambió), esta respuesta llegó
      // tarde y no debe pisar el estado de la selección actual.
      if (!mounted || token != _selectToken) return;
      setState(() => _items = items);
    } on ApiException catch (e) {
      if (!mounted || token != _selectToken) return;
      setState(() => _itemsError = e.message);
    } catch (_) {
      if (!mounted || token != _selectToken) return;
      setState(() => _itemsError = 'No se pudo cargar el desglose.');
    } finally {
      if (mounted && token == _selectToken) setState(() => _loadingItems = false);
    }
  }

  void _reloadItems() {
    if (_selectedScene != null) _selectScene(_selectedScene!);
  }

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh) — un
  // caso recarga la lista de escenas (cuando todavía no hay ninguna
  // seleccionada), el otro recarga el desglose de la escena elegida.
  Future<void> _onPullRefreshScenes() async {
    setState(() => _scenesFuture = _loadScenes());
    try {
      await _scenesFuture;
    } catch (_) {}
  }

  Future<void> _onPullRefreshItems() async {
    _reloadItems();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canManage = session.can('manage_general_breakdown');
    final canDownload = session.can('download_files');
    // La vista dividida (guion en PDF al lado del desglose) solo se
    // ofrece en PC/Web — en móvil/tablet (app nativa) nunca debe
    // aparecer, sin importar el ancho de pantalla.
    final splitViewAllowed = canUseSplitView(context);
    final mostrarVistaDividida = _vistaDividida && splitViewAllowed;

    return AppScaffold(
      title: 'Desglose de Producción',
      showBack: true,
      actions: [
        if (_selectedScene != null && canDownload)
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Descargar desglose de esta escena (PDF)',
            onPressed: (_items == null || _items!.isEmpty) ? null : () => _download(),
          ),
        if (_selectedScene != null && splitViewAllowed)
          IconButton(
            icon: Icon(_vistaDividida ? Icons.vertical_split : Icons.vertical_split_outlined),
            tooltip: _vistaDividida ? 'Cerrar vista dividida' : 'Vista dividida con el guion',
            color: _vistaDividida ? AppColors.azulProfundo : null,
            onPressed: () => setState(() => _vistaDividida = !_vistaDividida),
          ),
      ],
      floatingActionButton: canManage && _selectedScene != null
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar item'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Elige una escena para ver y editar sus requerimientos por categoría.',
              style: TextStyle(color: AppColors.grisMedio),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Scene>>(
              future: _scenesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                if (snap.hasError) {
                  return const Text('No se pudieron cargar las escenas.', style: TextStyle(color: AppColors.error));
                }
                return _SceneSearchField(
                  scenes: snap.data ?? [],
                  selected: _selectedScene,
                  onSelected: _selectScene,
                );
              },
            ),
            const SizedBox(height: 20),
            if (_selectedScene == null)
              Expanded(
                child: MobileRefresh(
                  onRefresh: _onPullRefreshScenes,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EmptyView(message: 'Busca y selecciona una escena para ver su desglose.', icon: Icons.checklist_outlined),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: mostrarVistaDividida
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          // Igual que en Escenas: en pantallas angostas
                          // (móvil/tablet chico) el guion y el desglose lado
                          // a lado quedan ilegibles. Por debajo de 760px se
                          // apilan verticalmente (guion arriba con alto
                          // fijo, desglose debajo con scroll propio).
                          final wide = constraints.maxWidth > 760;
                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 5, child: _buildScriptPane(context)),
                                const SizedBox(width: 16),
                                const VerticalDivider(width: 1),
                                const SizedBox(width: 16),
                                Expanded(flex: 6, child: _buildDesglosePane(context, canManage)),
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
                              Expanded(child: _buildDesglosePane(context, canManage)),
                            ],
                          );
                        },
                      )
                    : _buildDesglosePane(context, canManage),
              ),
          ],
        ),
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
            sourceName: 'guion-desglose-${_selectedScene?.idGuion}',
            params: PdfViewerParams(backgroundColor: AppColors.bg),
          ),
        );
      },
    );
  }

  Widget _buildDesglosePane(BuildContext context, bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectedSceneHeader(
          scene: _selectedScene!,
          diaDeRodaje: _diaDeRodajeCalculado(_selectedScene!, _allScenes),
        ),
        const SizedBox(height: 16),
        if (_loadingItems) const Expanded(child: LoadingView()),
        if (!_loadingItems && _itemsError != null) Expanded(child: ErrorView(message: _itemsError!, onRetry: _reloadItems)),
        if (!_loadingItems && _itemsError == null && _items != null)
          Expanded(
            child: MobileRefresh(
              onRefresh: _onPullRefreshItems,
              child: _CategoryCardsGrid(
                items: _items!,
                canManage: canManage,
                onAdd: (categoria) => _openForm(context, initialCategoria: categoria),
                onEdit: (item) => _openForm(context, existing: item),
                onDelete: (item) => _deleteItem(item),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, {DesgloseItem? existing, String? initialCategoria}) async {
    if (_selectedScene == null) return;
    final saved = await showCenteredFormSheet<bool>(
      context,
      _BreakdownItemFormSheet(scene: _selectedScene!, existing: existing, initialCategoria: initialCategoria),
    );
    if (saved == true) _reloadItems();
  }

  /// Exporta a PDF los items de desglose de la escena seleccionada —
  /// mismo botón "Descargar" que se agregó también en Plan de Rodaje.
  /// Decisión explícita del usuario: todas las descargas de reportes van
  /// en PDF, ninguna en CSV/Excel.
  Future<void> _download() async {
    if (_selectedScene == null || _items == null) return;
    try {
      final session = context.read<AuthSession>();
      final guardado = await exportTablePdf(
        fileName: 'desglose_esc_${_selectedScene!.numeroDeEscena}',
        titulo: 'Desglose de Producción — ESC ${_selectedScene!.numeroDeEscena}',
        subtitulo: _selectedScene!.encabezado,
        headers: const ['Categoría', 'Item', 'Cantidad', 'Notas'],
        rows: [
          for (final item in _items!)
            [
              item.categoria,
              item.nombreItem,
              item.cantidad?.toString() ?? '',
              item.notas ?? '',
            ],
        ],
        marcaAguaTexto: watermarkTextFor(session),
      );
      // guardado == false: la persona cerró el selector "Guardar como"
      // sin elegir carpeta — no es un error, no hace falta avisar nada.
      if (mounted && guardado) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF guardado correctamente')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo generar el archivo.')));
      }
    }
  }

  Future<void> _deleteItem(DesgloseItem item) async {
    final ok = await confirmDelete(
      context,
      title: '¿Eliminar item de desglose?',
      message: '¿Eliminar "${item.nombreItem}"? Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted || item.id == null) return;

    final session = context.read<AuthSession>();
    try {
      await BreakdownService(session.api).deleteItem(item.id!);
      _reloadItems();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

/// Selector de escena con autocompletado — reemplaza el campo de texto
/// donde antes había que escribir el ID de memoria.
class _SceneSearchField extends StatelessWidget {
  final List<Scene> scenes;
  final Scene? selected;
  final ValueChanged<Scene> onSelected;

  const _SceneSearchField({required this.scenes, required this.selected, required this.onSelected});

  // Pedido explícito del usuario: en este selector solo se muestra el
  // encabezado de la escena, sin anteponer el número (antes se mostraba
  // "1 — ESC 1. INT...", ahora solo "ESC 1. INT..." tal cual está
  // guardado en la escena).
  static String _label(Scene s) => s.encabezado;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Scene>(
      displayStringForOption: _label,
      initialValue: TextEditingValue(text: selected != null ? _label(selected!) : ''),
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return scenes;
        return scenes.where((s) => s.numeroDeEscena.toLowerCase().contains(q) || s.encabezado.toLowerCase().contains(q));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return _SceneSearchTextField(
          controller: controller,
          focusNode: focusNode,
          fallbackText: selected != null ? _label(selected!) : '',
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surfaceVariant,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 480),
              child: list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Sin resultados.', style: TextStyle(color: AppColors.grisMedio)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final s = list[i];
                        return ListTile(
                          dense: true,
                          leading: Container(width: 8, height: 8, decoration: BoxDecoration(color: colorForEstadoEscena(s.estado), shape: BoxShape.circle)),
                          title: Text(_label(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          onTap: () => onSelected(s),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// TextField del [_SceneSearchField]. Se necesita como widget aparte
/// (con estado propio) porque el `Autocomplete` de Flutter, tal como
/// viene de fábrica, solo vuelve a llamar a `optionsBuilder` cuando el
/// TEXTO del campo cambia — no cuando el campo simplemente recupera el
/// foco. Por eso, al seleccionar una escena y luego volver a tocar la
/// barra de búsqueda, el usuario no veía de nuevo la lista: el campo
/// quedaba listo para escribir, mostrando el nombre de la escena ya
/// seleccionada en vez de las opciones (reporte explícito del usuario,
/// reproducible tanto en Web como en móvil).
///
/// La solución: al ganar el foco, se limpia el texto (lo que sí dispara
/// `optionsBuilder` con una consulta vacía → devuelve todas las escenas
/// → Autocomplete muestra la lista completa de inmediato, sin que el
/// usuario tenga que escribir nada). Si el usuario toca fuera del campo
/// sin volver a elegir una escena, se restaura el texto de la escena que
/// ya estaba seleccionada para que no parezca que se perdió la
/// selección.
class _SceneSearchTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String fallbackText;

  const _SceneSearchTextField({
    required this.controller,
    required this.focusNode,
    required this.fallbackText,
  });

  @override
  State<_SceneSearchTextField> createState() => _SceneSearchTextFieldState();
}

class _SceneSearchTextFieldState extends State<_SceneSearchTextField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      if (widget.controller.text.isNotEmpty) {
        widget.controller.clear();
      }
    } else {
      if (widget.controller.text.trim().isEmpty && widget.fallbackText.isNotEmpty) {
        widget.controller.text = widget.fallbackText;
      }
    }
    // Para que la flecha de abajo rote y quede apuntando hacia arriba
    // mientras la lista está desplegada (foco activo).
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final abierto = widget.focusNode.hasFocus;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        labelText: 'Escena',
        hintText: 'Busca por número o toca la flecha para ver todas...',
        prefixIcon: const Icon(Icons.search),
        // Flecha explícita para desplegar/cerrar la lista completa de
        // escenas sin tener que escribir nada — pedido explícito del
        // usuario, funciona igual en móvil y en Web. Tocarla solo
        // alterna el foco del campo: al ganarlo, _onFocusChange (arriba)
        // ya limpia el texto, lo que dispara `optionsBuilder` con una
        // consulta vacía y el Autocomplete muestra TODAS las escenas; al
        // perderlo, se cierra sola (mismo comportamiento que tocar fuera
        // del campo). Elegir una escena de la lista ya la cierra solo,
        // sin necesidad de nada extra acá.
        suffixIcon: IconButton(
          icon: AnimatedRotation(
            turns: abierto ? 0.5 : 0,
            duration: const Duration(milliseconds: 150),
            child: const Icon(Icons.keyboard_arrow_down),
          ),
          tooltip: abierto ? 'Cerrar lista' : 'Ver todas las escenas',
          onPressed: () {
            if (abierto) {
              widget.focusNode.unfocus();
            } else {
              widget.focusNode.requestFocus();
            }
          },
        ),
      ),
    );
  }
}

/// Header de la escena seleccionada — inspirado en el bloque superior
/// de la hoja de desglose de FilmScript (ESCENA N°, SET, LOCACIÓN,
/// SECUENCIA, DÍA DE GUION... como "badges" en vez de texto corrido).
/// La escena es la fuente única de datos: estos mismos campos son los
/// que alimentan también el Plan de Rodaje, así que se muestran todos
/// los que tengan valor, sin necesidad de un botón de edición aparte
/// (para editar, el usuario ya cuenta con el módulo Escenas y con las
/// filas editables del Plan de Rodaje).
class _SelectedSceneHeader extends StatelessWidget {
  final Scene scene;
  final int? diaDeRodaje;
  const _SelectedSceneHeader({required this.scene, this.diaDeRodaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(scene.encabezado, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              StatusPill(label: scene.estado, color: colorForEstadoEscena(scene.estado)),
            ],
          ),
          if (scene.descripcion != null && scene.descripcion!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              scene.descripcion!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // El número de escena queda oculto acá (pedido explícito
              // del usuario) — sigue disponible en el modelo/BD, solo no
              // se muestra en este header.
              if (scene.modoVista != null)
                _HeaderBadge(
                  label: 'ESPACIO',
                  value: scene.modoVista!.toUpperCase(),
                ),
              if (scene.momentoDia != null)
                _HeaderBadge(
                  label: 'MOMENTO',
                  value: labelMomento(scene.momentoDia),
                ),
              if (scene.pagina != null) _HeaderBadge(label: 'PÁGINA', value: '${scene.pagina}'),
              if (scene.ciudad != null && scene.ciudad!.isNotEmpty) _HeaderBadge(label: 'CIUDAD/LOCACIÓN', value: scene.ciudad!),
              if (scene.diaDramatico != null) _HeaderBadge(label: 'DÍA DRAMÁTICO', value: '${scene.diaDramatico}'),
              if (scene.fechaDeGrabacion != null)
                _HeaderBadge(label: 'FECHA DE GRABACIÓN', value: scene.fechaDeGrabacion!.toIso8601String().split('T').first),
              if (diaDeRodaje != null)
                _HeaderBadge(label: 'DÍA DE RODAJE', value: '$diaDeRodaje')
              else
                const _HeaderBadge(label: 'DÍA DE RODAJE', value: 'Sin fecha de grabación'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _HeaderBadge({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grisMedio, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Grilla de tarjetas por categoría — TODAS las categorías del catálogo
/// se muestran (incluso vacías), cada una con su color e ícono propio y
/// un botón "+" para agregar directo a esa categoría. Mismo espíritu
/// visual que la hoja de desglose de FilmScript (ELENCO, EXTRAS,
/// UTILERÍA... en tarjetas de colores), adaptado a nuestro modelo de
/// datos real (lista de items por categoría, no un solo cuadro de texto).
class _CategoryCardsGrid extends StatelessWidget {
  final List<DesgloseItem> items;
  final bool canManage;
  final ValueChanged<String> onAdd;
  final ValueChanged<DesgloseItem> onEdit;
  final ValueChanged<DesgloseItem> onDelete;

  const _CategoryCardsGrid({
    required this.items,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final porCategoria = <String, List<DesgloseItem>>{};
    for (final item in items) {
      (porCategoria[item.categoria] ??= []).add(item);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 168,
        ),
        itemCount: kCategoriasDesglose.length,
        itemBuilder: (context, i) {
          final categoria = kCategoriasDesglose[i];
          return _CategoryCard(
            categoria: categoria,
            items: porCategoria[categoria] ?? const [],
            canManage: canManage,
            onAdd: () => onAdd(categoria),
            onEdit: onEdit,
            onDelete: onDelete,
          );
        },
      );
    });
  }
}

class _CategoryCard extends StatelessWidget {
  final String categoria;
  final List<DesgloseItem> items;
  final bool canManage;
  final VoidCallback onAdd;
  final ValueChanged<DesgloseItem> onEdit;
  final ValueChanged<DesgloseItem> onDelete;

  const _CategoryCard({
    required this.categoria,
    required this.items,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorCategoria(categoria);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
            child: Row(
              children: [
                Icon(_iconoCategoria(categoria), size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    categoria.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
                  ),
                ),
                if (canManage)
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onAdd,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 16, color: AppColors.grisMedio),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('Sin items', style: const TextStyle(color: AppColors.grisMedio, fontSize: 11)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return _CategoryItemRow(item: item, canManage: canManage, onEdit: () => onEdit(item), onDelete: () => onDelete(item));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItemRow extends StatelessWidget {
  final DesgloseItem item;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryItemRow({required this.item, required this.canManage, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canManage ? onEdit : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.cantidad != null ? '${item.nombreItem} (${item.cantidad})' : item.nombreItem,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (canManage)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 13, color: AppColors.grisMedio),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownItemFormSheet extends StatefulWidget {
  final Scene scene;
  final DesgloseItem? existing;
  final String? initialCategoria;
  const _BreakdownItemFormSheet({required this.scene, this.existing, this.initialCategoria});

  @override
  State<_BreakdownItemFormSheet> createState() => _BreakdownItemFormSheetState();
}

class _BreakdownItemFormSheetState extends State<_BreakdownItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreItem = TextEditingController(text: widget.existing?.nombreItem ?? '');
  late final _cantidad = TextEditingController(text: widget.existing?.cantidad?.toString() ?? '');
  late final _notas = TextEditingController(text: widget.existing?.notas ?? '');
  late String _categoria = widget.existing?.categoria ?? widget.initialCategoria ?? kCategoriasDesglose.first;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Sin esto, en móvil con el teclado abierto (el diálogo tiene
      // maxHeight:680 fijo) el Form+Column plano se desborda — ver
      // auditoría de responsive.
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_isEdit ? 'Editar' : 'Agregar'} item — ESC ${widget.scene.numeroDeEscena}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Categoría',
              value: _categoria,
              items: kCategoriasDesglose,
              labelBuilder: (e) => e,
              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Item', hint: 'Ej: Carta sellada con lacre rojo', controller: _nombreItem, validator: _req),
            const SizedBox(height: 16),
            AppTextField(label: 'Cantidad', controller: _cantidad, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            AppTextField(label: 'Notas', controller: _notas, maxLines: 2),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Guardar cambios' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    try {
      if (_isEdit) {
        await BreakdownService(session.api).updateItem(widget.existing!.id!, {
          'categoria': _categoria,
          'nombre_item': _nombreItem.text.trim(),
          'cantidad': int.tryParse(_cantidad.text.trim()),
          'notas': _notas.text.trim(),
        });
      } else {
        await BreakdownService(session.api).createItem(DesgloseItem(
          idEscena: widget.scene.idEscena!,
          categoria: _categoria,
          nombreItem: _nombreItem.text.trim(),
          cantidad: int.tryParse(_cantidad.text.trim()),
          notas: _notas.text.trim(),
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
