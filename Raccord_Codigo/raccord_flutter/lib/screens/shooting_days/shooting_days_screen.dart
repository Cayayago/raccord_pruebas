import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/pdf_export.dart';
import '../../core/plan_change_tracker.dart';
import '../../core/session.dart';
import '../../core/watermark.dart';
import '../../models/scene.dart';
import '../../models/shooting_day.dart';
import '../../services/scene_service.dart';
import '../../services/shooting_day_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import '../scenes/scene_edit_screen.dart';

// ==========================================
// ESPACIO/MOMENTO SIN COLORES (antes stripboard con colores tipo
// FilmScript: verde EXT día, amarillo INT día, azul INT noche, morado
// EXT noche)
// ==========================================
// El cliente reportó que ese color-coding interfiere con su propio uso
// de colores para otras segmentaciones — pedido explícito: reemplazar
// el color por íconos (ver kMomentoIconos en models/scene.dart) sin
// tocar el texto. `labelModoMomento` se mantiene solo como clave interna
// de orden/comparación (Plan de Rodaje ordena por "Momento del Día"),
// nunca se muestra combinado en pantalla.
// Los emojis de `kMomentoIconos` (models/scene.dart) no están en la
// fuente Montserrat de la app ni en ninguna que Flutter Web empaquete
// por defecto — el navegador cae a un fallback "Noto" que no incluye
// y tira la advertencia "Could not find a set of Noto fonts..." en la
// consola. Se reemplazan acá por íconos reales de Material (mismo
// propósito: distinguir el momento del día sin usar color), que sí
// vienen en la fuente de íconos de Flutter.
IconData iconoMomentoData(String? momento) {
  switch (momento) {
    case 'dia':
    case 'amanecer':
      return Icons.wb_sunny_outlined;
    case 'noche':
    case 'atardecer':
    case 'anochecer':
      return Icons.nightlight_outlined;
    default:
      return Icons.schedule_outlined;
  }
}

String labelModoMomento(String? modoVista, String? momentoDia) {
  final modo = (modoVista ?? '?').toUpperCase();
  final momento = momentoDia == null ? '?' : (momentoDia.contains('noche') ? 'NOCHE' : 'DÍA');
  return '$modo · $momento';
}

/// Parsea "HH:MM:SS" (formato hora del backend) a [TimeOfDay] para
/// poder abrir el time picker con el valor actual preseleccionado.
TimeOfDay? _parseHora(String? hhmmss) {
  if (hhmmss == null || hhmmss.isEmpty) return null;
  final partes = hhmmss.split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

/// Muestra la hora en formato local (respeta 12h/24h del dispositivo,
/// igual que el resto de la app) o "Pendiente" si todavía no se
/// definió — mismo texto que usa el referente de FilmScript.
String _formatHora(BuildContext context, String? hhmmss) {
  final t = _parseHora(hhmmss);
  if (t == null) return 'Pendiente';
  return t.format(context);
}

/// Orden del stripboard: respeta `ordenRodaje` (posición manual por
/// drag-and-drop) cuando existe; las escenas sin orden manual quedan al
/// final, ordenadas por número de escena como antes.
int _ordenStripboard(Scene a, Scene b) {
  final oa = a.ordenRodaje;
  final ob = b.ordenRodaje;
  if (oa != null && ob != null) return oa.compareTo(ob);
  if (oa != null) return -1;
  if (ob != null) return 1;
  return a.numeroDeEscena.compareTo(b.numeroDeEscena);
}

/// Orden por número de escena — igual criterio que Escenas: numérico por
/// la parte inicial de dígitos ("1", "2A", "10"...), no alfabético.
int _compareNumeroEscena(Scene a, Scene b) {
  final na = int.tryParse(RegExp(r'^\d+').stringMatch(a.numeroDeEscena) ?? '');
  final nb = int.tryParse(RegExp(r'^\d+').stringMatch(b.numeroDeEscena) ?? '');
  if (na != null && nb != null && na != nb) return na.compareTo(nb);
  return a.numeroDeEscena.compareTo(b.numeroDeEscena);
}

/// Opciones del selector "Ordenar por" de las escenas sin día asignado
/// — pedido explícito del usuario. Las escenas YA asignadas a un día
/// mantienen su orden manual (drag-and-drop en el stripboard), que es
/// intencional, así que este selector solo aplica a la lista de
/// escenas sin día.
enum _SortField { numero, momento, reparto, locacion, fecha }

const _sortFieldLabels = {
  _SortField.numero: 'Número de Escena',
  _SortField.momento: 'Momento del Día',
  _SortField.reparto: 'ID de Reparto',
  _SortField.locacion: 'Locación de Rodaje',
  _SortField.fecha: 'Fecha de Grabación',
};

/// Clave de reparto para ordenar: códigos de personaje asignados,
/// ordenados y unidos — las escenas sin reparto quedan agrupadas al
/// final (en orden ascendente) con un caracter que ordena después de
/// cualquier código real.
String _repartoSortKey(Scene s, Map<String, List<Map<String, dynamic>>> castByScene) {
  final cast = s.idEscena != null ? (castByScene[s.idEscena] ?? const []) : const [];
  if (cast.isEmpty) return '~~~';
  final codigos = cast.map((c) => c['codigo_personaje']?.toString() ?? '').toList()..sort();
  return codigos.join(',');
}

int _compareScenesBy(
  Scene a,
  Scene b,
  _SortField field,
  bool asc,
  Map<String, List<Map<String, dynamic>>> castByScene,
) {
  int cmp;
  switch (field) {
    case _SortField.numero:
      cmp = _compareNumeroEscena(a, b);
      break;
    case _SortField.momento:
      cmp = labelModoMomento(a.modoVista, a.momentoDia).compareTo(labelModoMomento(b.modoVista, b.momentoDia));
      break;
    case _SortField.reparto:
      cmp = _repartoSortKey(a, castByScene).compareTo(_repartoSortKey(b, castByScene));
      break;
    case _SortField.locacion:
      final la = a.locacionRodaje ?? '';
      final lb = b.locacionRodaje ?? '';
      if (la.isEmpty && lb.isEmpty) {
        cmp = 0;
      } else if (la.isEmpty) {
        cmp = 1;
      } else if (lb.isEmpty) {
        cmp = -1;
      } else {
        cmp = la.compareTo(lb);
      }
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
  }
  return asc ? cmp : -cmp;
}

/// Diálogo simple de una sola línea (o varias, con [maxLines]) para
/// editar rápido un campo de texto sin salir del stripboard — usado
/// para Locación de rodaje, Tiempo estimado y Notas.
Future<String?> _promptText(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Guardar')),
      ],
    ),
  );
}

/// Leyenda de íconos de Momento — se muestra una sola vez arriba de la
/// lista de días. Reemplaza la antigua leyenda de colores (ver nota más
/// arriba): cada ícono representa un momento del día, sin usar color.
class _StripboardLegend extends StatelessWidget {
  const _StripboardLegend();

  @override
  Widget build(BuildContext context) {
    Widget chip(String momento) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconoMomentoData(momento), size: 14, color: AppColors.grisMedio),
            const SizedBox(width: 5),
            Text(labelMomento(momento), style: const TextStyle(fontSize: 11, color: AppColors.grisMedio, fontWeight: FontWeight.w600)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: kMomentosDia.map(chip).toList(),
    );
  }
}

/// Mockup 10: Plan de Rodaje. Cada día muestra las escenas que tiene
/// asignadas (relación real en el backend: `Scene.id_rodaje` apunta a
/// este día — no hay una tabla intermedia), con un diálogo para
/// asignar/quitar escenas sin salir de esta pantalla.
class ShootingDaysScreen extends StatefulWidget {
  const ShootingDaysScreen({super.key});

  @override
  State<ShootingDaysScreen> createState() => _ShootingDaysScreenState();
}

class _PlanData {
  final List<ShootingDay> days;
  final List<Scene> scenes;
  // Reparto (personajes) asignado a cada escena, precargado de una sola
  // vez acá — antes cada fila del stripboard (_RepartoBadges) lo pedía
  // por su cuenta de forma perezosa, lo cual funcionaba para mostrarlo
  // pero no alcanzaba para poder ORDENAR por "ID de reparto" (no hay
  // forma de ordenar por un dato que todavía no se cargó).
  //
  // Antes esto se armaba con un GET /scenes/{id}/cast POR escena en
  // paralelo (Future.wait) — con ~129 escenas en un proyecto real, el
  // límite de conexiones HTTP concurrentes del cliente terminaba
  // sirviendo esas ~129 peticiones en oleadas, y en la red real de un
  // dispositivo físico (a diferencia de localhost) eso tardaba decenas
  // de segundos. Ahora el backend embebe el cast de TODAS las escenas
  // en la MISMA respuesta de `sceneService.all()` (ver Scene.cast en
  // models/scene.dart y scene_controller.py), así que esto solo
  // reorganiza datos que ya llegaron — 0 peticiones adicionales.
  final Map<String, List<Map<String, dynamic>>> castByScene;
  _PlanData({required this.days, required this.scenes, required this.castByScene});
}

class _ShootingDaysScreenState extends State<ShootingDaysScreen> {
  late Future<_PlanData> _future;
  _PlanData? _lastData;
  // Orden de la lista de escenas SIN día asignado — las que ya están en
  // un día mantienen su orden manual (drag-and-drop), que es intencional.
  _SortField _sortField = _SortField.numero;
  bool _sortAsc = true;
  // Filtro por bloque de grabación (null = todos) — pedido explícito del
  // usuario, mismo filtro también disponible en la pantalla Escenas.
  int? _filtroBloque;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PlanData> _load() async {
    final session = context.read<AuthSession>();
    final sceneService = SceneService(session.api);
    final idProject = session.projectId ?? '';
    final results = await Future.wait([
      ShootingDayService(session.api).all(idProject),
      sceneService.all(idProject),
    ]);
    final days = results[0] as List<ShootingDay>;
    final scenes = results[1] as List<Scene>;

    // `scene.cast` ya viene embebido en la respuesta de `sceneService.all()`
    // (ver comentario en _PlanData.castByScene). Si por lo que sea llega
    // null (ej. backend viejo sin este campo todavía desplegado), se cae
    // a lista vacía para esa escena en vez de romper la pantalla.
    final castByScene = <String, List<Map<String, dynamic>>>{};
    for (final s in scenes) {
      final id = s.idEscena;
      if (id != null) castByScene[id] = s.cast ?? const <Map<String, dynamic>>[];
    }

    return _PlanData(days: days, scenes: scenes, castByScene: castByScene);
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
    final canManage = session.can('create_scenes');
    final canDownload = session.can('download_files');

    return AppScaffold(
      title: 'Plan de Rodaje',
      showBack: true,
      guardPlanChanges: true,
      actions: [
        if (canDownload)
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Descargar plan de rodaje (PDF)',
            onPressed: _lastData == null ? null : () => _download(_lastData!),
          ),
      ],
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo día'),
            )
          : null,
      body: FutureBuilder<_PlanData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: 'No se pudo cargar el plan de rodaje.', onRetry: _reload);

          final data = snap.data!;
          // El botón "Descargar" del AppBar (actions, arriba) lee
          // _lastData para decidir si está habilitado — pero esa lista
          // de actions se construye en el build() de MÁS ARRIBA, antes
          // de llegar aquí, así que el IconButton ya quedó armado con
          // onPressed=null (deshabilitado) la primera vez que este
          // FutureBuilder entra en este builder. Mutar _lastData solo
          // no repinta ese IconButton: FutureBuilder únicamente
          // reconstruye SU PROPIO subárbol al resolver, no el build()
          // completo del State. Por eso el ícono se veía deshabilitado
          // "apenas ingreso" pese a que la tabla ya tenía datos. Se
          // programa un setState() para el siguiente frame SOLO la
          // primera vez que llega esta data (evita loop: en rebuilds
          // posteriores la referencia ya es la misma), forzando un
          // repintado completo que arma el botón ya habilitado.
          if (!identical(_lastData, data)) {
            _lastData = data;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
          final days = [...data.days]..sort((a, b) {
              final da = a.diaRodaje ?? 999999;
              final db_ = b.diaRodaje ?? 999999;
              if (da != db_) return da.compareTo(db_);
              return a.version.compareTo(b.version);
            });

          // Filtro por bloque de grabación — se calcula sobre TODAS las
          // escenas (no solo las visibles) para que el dropdown siempre
          // ofrezca todos los bloques que existen, incluso con un
          // filtro ya aplicado.
          final bloquesDisponibles = data.scenes.map((s) => s.bloqueGrabacion).whereType<int>().toSet().toList()..sort();
          final scenesFiltradas =
              _filtroBloque == null ? data.scenes : data.scenes.where((s) => s.bloqueGrabacion == _filtroBloque).toList();

          // Relación real: `Scene.idRodaje` apunta al día. Se agrupa acá
          // (una sola pasada) en vez de pedirle al backend un endpoint
          // por día, para no hacer N peticiones.
          final porDia = <String, List<Scene>>{};
          final sinDia = <Scene>[];
          for (final s in scenesFiltradas) {
            if (s.idRodaje != null && s.idRodaje!.isNotEmpty) {
              (porDia[s.idRodaje!] ??= []).add(s);
            } else {
              sinDia.add(s);
            }
          }
          for (final lista in porDia.values) {
            lista.sort(_ordenStripboard);
          }
          sinDia.sort((a, b) => _compareScenesBy(a, b, _sortField, _sortAsc, data.castByScene));

          // Antes, si no había días creados TODAVÍA se ocultaba la lista
          // entera de escenas (aunque sí existieran escenas cargadas) —
          // pedido explícito del usuario: las escenas deben aparecer
          // listadas sí o sí, tengan o no un día de rodaje asignado.
          // Solo se muestra el estado vacío si de verdad no hay nada
          // (ni días ni escenas).
          if (days.isEmpty && data.scenes.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyView(message: 'Todavía no hay días de rodaje ni escenas planificadas.', icon: Icons.event_note_outlined),
                ],
              ),
            );
          }

          return MobileRefresh(
            onRefresh: _onPullRefresh,
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const _StripboardLegend(),
              const SizedBox(height: 16),
              if (bloquesDisponibles.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.grisMedio),
                    const SizedBox(width: 8),
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
                      onChanged: (v) => setState(() => _filtroBloque = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (sinDia.isNotEmpty) ...[
                _SinDiaBanner(count: sinDia.length),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Ordenar por: ', style: TextStyle(color: AppColors.grisMedio)),
                    DropdownButton<_SortField>(
                      value: _sortField,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.surfaceVariant,
                      items: _SortField.values
                          .map((f) => DropdownMenuItem(value: f, child: Text(_sortFieldLabels[f]!)))
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
                const SizedBox(height: 8),
                _PaginatedScenes(
                  scenes: sinDia,
                  canManage: canManage,
                  onSceneChanged: (_) => _reload(),
                  castByScene: data.castByScene,
                ),
                const SizedBox(height: 16),
              ],
              for (final d in days) ...[
                _DayCard(
                  day: d,
                  scenes: porDia[d.idRodaje] ?? const [],
                  allScenes: data.scenes,
                  canManage: canManage,
                  onEdit: () => _openForm(context, existing: d),
                  onDelete: () => _delete(d, porDia[d.idRodaje] ?? const []),
                  onScenesChanged: _reload,
                  castByScene: data.castByScene,
                ),
                const SizedBox(height: 12),
              ],
              if (days.isEmpty && sinDia.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Todavía no has creado días de rodaje — crea uno con "Nuevo día" para organizar estas escenas por fecha.',
                    style: TextStyle(color: AppColors.grisMedio, fontSize: 12),
                  ),
                ),
            ],
            ),
          );
        },
      ),
    );
  }

  /// Exporta el plan de rodaje completo (todos los días con sus
  /// escenas, en orden, MÁS las escenas que todavía no tienen día
  /// asignado) a PDF — decisión explícita del usuario: nada de
  /// CSV/Excel, todas las descargas de reportes van en PDF.
  Future<void> _download(_PlanData data) async {
    final days = [...data.days]..sort((a, b) {
        final da = a.diaRodaje ?? 999999;
        final db_ = b.diaRodaje ?? 999999;
        if (da != db_) return da.compareTo(db_);
        return a.version.compareTo(b.version);
      });
    final porDia = <String, List<Scene>>{};
    final sinDia = <Scene>[];
    for (final s in data.scenes) {
      if (s.idRodaje != null && s.idRodaje!.isNotEmpty) {
        (porDia[s.idRodaje!] ??= []).add(s);
      } else {
        sinDia.add(s);
      }
    }
    for (final lista in porDia.values) {
      lista.sort(_ordenStripboard);
    }
    sinDia.sort((a, b) => a.numeroDeEscena.compareTo(b.numeroDeEscena));

    String fecha(Scene s) => s.fechaDeGrabacion != null ? s.fechaDeGrabacion!.toIso8601String().split('T').first : '';
    final rows = <List<String>>[];

    for (final s in sinDia) {
      rows.add([
        'Sin asignar', '', '', '',
        s.numeroDeEscena,
        s.ciudad ?? '',
        s.modoVista ?? '',
        s.momentoDia ?? '',
        s.encabezado,
        s.locacionRodaje ?? '',
        s.pagina?.toString() ?? '',
        s.tiempoEstimado ?? '',
        s.horaInicioRodaje ?? '',
        s.notasRodaje ?? '',
        s.estado,
        s.diaDramatico?.toString() ?? '',
        fecha(s),
      ]);
    }

    for (final d in days) {
      final scenes = porDia[d.idRodaje] ?? const <Scene>[];
      if (scenes.isEmpty) {
        rows.add([
          d.diaRodaje?.toString() ?? '', d.version, d.semanaGrabacion?.toString() ?? '', d.location ?? '',
          '', '', '', '', '', '', '', '', '', '', '', '', '',
        ]);
        continue;
      }
      for (final s in scenes) {
        rows.add([
          d.diaRodaje?.toString() ?? '',
          d.version,
          d.semanaGrabacion?.toString() ?? '',
          d.location ?? '',
          s.numeroDeEscena,
          s.ciudad ?? '',
          s.modoVista ?? '',
          s.momentoDia ?? '',
          s.encabezado,
          s.locacionRodaje ?? '',
          s.pagina?.toString() ?? '',
          s.tiempoEstimado ?? '',
          s.horaInicioRodaje ?? '',
          s.notasRodaje ?? '',
          s.estado,
          s.diaDramatico?.toString() ?? '',
          fecha(s),
        ]);
      }
    }

    try {
      final session = context.read<AuthSession>();
      final guardado = await exportTablePdf(
        fileName: 'plan_de_rodaje',
        titulo: 'Plan de Rodaje',
        headers: const [
          'Día', 'Versión', 'Semana', 'Ubicación del día', 'Escena', 'SET', 'INT/EXT', 'Día/Noche',
          'Encabezado', 'Locación de rodaje', 'Página', 'Tiempo estimado', 'Hora de inicio', 'Notas',
          'Estado', 'Día dramático', 'Fecha de grabación',
        ],
        rows: rows,
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

  Future<void> _openForm(BuildContext context, {ShootingDay? existing}) async {
    final saved = await showCenteredFormSheet<bool>(
      context,
      _ShootingDayFormSheet(existing: existing),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(ShootingDay day, List<Scene> escenasAsignadas) async {
    // OJO — advertencia real, no genérica: en la base de datos,
    // `escenas.id_rodaje` tiene ON DELETE CASCADE hacia `plan_rodaje`.
    // Si este día tiene escenas asignadas, borrar el día borra TAMBIÉN
    // esas escenas (y todo lo que cuelga de ellas: desglose, fotos,
    // reparto). Por eso el mensaje cambia según si hay escenas o no —
    // no se puede minimizar esto en el texto del diálogo.
    final mensaje = escenasAsignadas.isEmpty
        ? '¿Eliminar este día de rodaje? Esta acción no se puede deshacer.'
        : '¿Eliminar este día de rodaje? Tiene ${escenasAsignadas.length} escena(s) asignada(s) — '
            'se eliminarán TAMBIÉN esas escenas y toda su información asociada (desglose, fotos, reparto). '
            'Esta acción no se puede deshacer.';

    final ok = await confirmDelete(context, title: '¿Eliminar día de rodaje?', message: mensaje);
    if (!ok || !mounted) return;

    final session = context.read<AuthSession>();
    final tracker = context.read<PlanChangeTracker>();
    try {
      await ShootingDayService(session.api).delete(day.idRodaje!);
      tracker.record(
        session,
        key: 'dia|${day.idRodaje}',
        descripcion: 'Se eliminó el día de rodaje ${day.diaRodaje != null ? 'Día ${day.diaRodaje}' : 'Versión ${day.version}'}',
        conValores: false,
      );
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _SinDiaBanner extends StatelessWidget {
  final int count;
  const _SinDiaBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? '1 escena todavía no tiene día de rodaje asignado.'
                  : '$count escenas todavía no tienen día de rodaje asignado.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatefulWidget {
  final ShootingDay day;
  final List<Scene> scenes;
  final List<Scene> allScenes;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onScenesChanged;
  final Map<String, List<Map<String, dynamic>>> castByScene;

  const _DayCard({
    required this.day,
    required this.scenes,
    required this.allScenes,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    required this.onScenesChanged,
    this.castByScene = const {},
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.day;
    final scenes = widget.scenes;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.coral,
                    child: Text(
                      d.diaRodaje?.toString() ?? '–',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Versión ${d.version}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (d.semanaGrabacion != null) ...[
                              const SizedBox(width: 8),
                              Text('· Semana ${d.semanaGrabacion}', style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (d.location != null && d.location!.isNotEmpty) d.location!,
                            if (d.horaInicio != null || d.horaFin != null) '${d.horaInicio ?? '?'} - ${d.horaFin ?? '?'}',
                          ].join('  ·  '),
                          style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ScenesCountChip(count: scenes.length),
                  const SizedBox(width: 8),
                  StatusPill(label: d.activo ? 'Activo' : 'Inactivo', color: d.activo ? AppColors.success : AppColors.grisMedio),
                  if (widget.canManage) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Editar día',
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                      tooltip: 'Eliminar día',
                      onPressed: widget.onDelete,
                    ),
                  ],
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.grisMedio),
                ],
              ),
            ),
          ),
          if (_expanded) _buildExpanded(context),
        ],
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final d = widget.day;
    final scenes = widget.scenes;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.notas != null && d.notas!.isNotEmpty) ...[
            Text(d.notas!, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
            const SizedBox(height: 12),
          ],
          if (scenes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Sin escenas asignadas todavía.', style: TextStyle(color: AppColors.grisMedio, fontSize: 13)),
            )
          else ...[
            _PaginatedScenes(
              scenes: scenes,
              canManage: widget.canManage,
              onSceneChanged: (_) => widget.onScenesChanged(),
              onReorder: (newOrder) => _persistReorder(context, newOrder),
              castByScene: widget.castByScene,
            ),
            _DayFooterBar(day: d, scenes: scenes),
          ],
          if (widget.canManage) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.movie_filter_outlined, size: 16),
                label: const Text('Gestionar escenas de este día'),
                onPressed: () => _manageScenes(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Persiste el nuevo orden manual (drag-and-drop) del stripboard,
  /// asignando `orden_rodaje` 0,1,2... según la posición nueva — solo
  /// hace PATCH a las escenas cuya posición realmente cambió.
  Future<void> _persistReorder(BuildContext context, List<Scene> newOrder) async {
    final session = context.read<AuthSession>();
    final service = SceneService(session.api);
    final tracker = context.read<PlanChangeTracker>();
    try {
      var huboCambios = false;
      for (var i = 0; i < newOrder.length; i++) {
        final s = newOrder[i];
        if (s.idEscena != null && s.ordenRodaje != i) {
          await service.updatePartial(s.idEscena!, {'orden_rodaje': i});
          huboCambios = true;
        }
      }
      if (huboCambios) {
        tracker.record(
          session,
          key: 'orden|${widget.day.idRodaje}',
          descripcion:
              'Se cambió el orden de las escenas del ${widget.day.diaRodaje != null ? 'Día ${widget.day.diaRodaje}' : 'Versión ${widget.day.version}'}',
          conValores: false,
        );
      }
      widget.onScenesChanged();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _manageScenes(BuildContext context) async {
    if (widget.day.idRodaje == null) return;
    final changed = await showCenteredFormSheet<bool>(
      context,
      _AssignScenesDialog(
        dayId: widget.day.idRodaje!,
        dayLabel: 'Versión ${widget.day.version}${widget.day.diaRodaje != null ? ' · Día ${widget.day.diaRodaje}' : ''}',
        allScenes: widget.allScenes,
      ),
    );
    if (changed == true) widget.onScenesChanged();
  }
}

/// Barra "FIN DEL DÍA N" — igual que el referente de FilmScript: cierra
/// visualmente el stripboard de cada día con el total de páginas y si
/// ya hay una hora definida para arrancar.
class _DayFooterBar extends StatelessWidget {
  final ShootingDay day;
  final List<Scene> scenes;
  const _DayFooterBar({required this.day, required this.scenes});

  @override
  Widget build(BuildContext context) {
    // "pagina" es el número de página del GUION donde inicia cada
    // escena (no una cantidad a sumar) — por eso aquí se muestra el
    // rango de páginas que cubre el día, no una suma sin sentido.
    final paginas = scenes.map((s) => s.pagina).whereType<int>().toList();
    final rangoPaginas = paginas.isEmpty
        ? null
        : (paginas.reduce((a, b) => a < b ? a : b) == paginas.reduce((a, b) => a > b ? a : b)
            ? 'Pág. ${paginas.first}'
            : 'Págs. ${paginas.reduce((a, b) => a < b ? a : b)}–${paginas.reduce((a, b) => a > b ? a : b)}');
    final horas = scenes
        .map((s) => s.horaInicioRodaje)
        .where((h) => h != null && h.isNotEmpty)
        .toList();
    final horaLabel = horas.isEmpty ? 'Hora pendiente' : 'Desde ${_formatHora(context, horas.first)}';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: AppColors.negro, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FIN DEL DÍA ${day.diaRodaje ?? '—'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4),
          ),
          Text(
            rangoPaginas == null ? horaLabel : '$horaLabel · $rangoPaginas',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Tabla tipo "stripboard" (mismo lenguaje visual que el Plan de rodaje
/// de FilmScript): encabezado de columnas + una fila por escena con una
/// franja de color a la izquierda según INT/EXT · DÍA/NOCHE.
/// Envuelve la tabla stripboard con paginación — pedido explícito del
/// usuario para que listas largas de escenas (con o sin día asignado)
/// no se rendericen todas de una vez.
class _PaginatedScenes extends StatefulWidget {
  final List<Scene> scenes;
  final bool canManage;
  final ValueChanged<Scene>? onSceneChanged;
  final ValueChanged<List<Scene>>? onReorder;
  final int pageSize;
  final Map<String, List<Map<String, dynamic>>> castByScene;

  const _PaginatedScenes({
    required this.scenes,
    required this.canManage,
    this.onSceneChanged,
    this.onReorder,
    this.pageSize = 10,
    this.castByScene = const {},
  });

  @override
  State<_PaginatedScenes> createState() => _PaginatedScenesState();
}

class _PaginatedScenesState extends State<_PaginatedScenes> {
  int _page = 0;
  late int _pageSize;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.pageSize;
  }

  int get _totalPages => (widget.scenes.length / _pageSize).ceil().clamp(1, 1 << 30);

  @override
  void didUpdateWidget(covariant _PaginatedScenes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page > _totalPages - 1) _page = (_totalPages - 1).clamp(0, 1 << 30);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.scenes.length;
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final pageScenes = start < total ? widget.scenes.sublist(start, end) : const <Scene>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StripboardTable(
          scenes: pageScenes,
          canManage: widget.canManage,
          onSceneChanged: widget.onSceneChanged,
          // El drag-and-drop solo tiene sentido reordenando dentro de
          // una sola página visible a la vez — con más de una página
          // se desactiva para no confundir (¿mueve dentro de la página
          // o entre páginas?).
          onReorder: _totalPages == 1 ? widget.onReorder : null,
          castByScene: widget.castByScene,
        ),
        if (total > 0) ...[
          const SizedBox(height: 6),
          PaginationBar(
            page: _page,
            totalPages: _totalPages,
            totalItems: total,
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
}

const _kHeaderStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.grisMedio, letterSpacing: 0.3);

// Anchos de columna del stripboard — mismas columnas que el referente
// de FilmScript que trajo el usuario (ESCENA/SET, I/E Y MOMENTO, ID DE
// REPARTO, LOCACIÓN DE RODAJE, PÁGINAS, TIEMPO EST., HORA DE INICIO,
// NOTAS). Se usa scroll horizontal para que quepa en pantallas angostas
// sin perder ninguna columna.
const double _kColHandle = 22;
const double _kColEsc = 34;
const double _kColSet = 190;
// Espacio (INT/EXT) y Momento (Día/Noche/...) son dos columnas
// separadas — antes era una sola ("I/E Y MOMENTO") pero el usuario pidió
// explícitamente que estos dos datos nunca se combinen en una sola
// casilla en ningún lugar de la app.
const double _kColEspacio = 46;
const double _kColMomento = 78;
const double _kColReparto = 90;
const double _kColLocacion = 160;
const double _kColFecha = 84;
const double _kColPaginas = 46;
const double _kColTiempo = 92;
const double _kColHora = 92;
const double _kColNotas = 30;
// Bloque de grabación: agrupación manual (1, 2, 3...) editable con tap,
// independiente del día de rodaje — pedido explícito del usuario, junto
// con el filtro por bloque (ver _filtroBloque más abajo).
const double _kColBloque = 60;
const double _kTableWidth = _kColHandle + _kColEsc + _kColSet + _kColEspacio + _kColMomento + _kColReparto + _kColLocacion + _kColFecha + _kColBloque + _kColPaginas + _kColTiempo + _kColHora + _kColNotas + 24;

/// Tabla tipo "stripboard" (mismo lenguaje visual que el Plan de rodaje
/// de FilmScript): encabezado de columnas + una fila por escena con una
/// franja de color a la izquierda según INT/EXT · DÍA/NOCHE. Cuando
/// [onReorder] no es null y hay permiso de gestión, las filas se pueden
/// reordenar arrastrando desde el ícono `::` — el nuevo orden se
/// persiste en `orden_rodaje` de cada escena.
class _StripboardTable extends StatelessWidget {
  final List<Scene> scenes;
  final bool canManage;
  final ValueChanged<Scene>? onSceneChanged;
  final ValueChanged<List<Scene>>? onReorder;
  final Map<String, List<Map<String, dynamic>>> castByScene;
  const _StripboardTable({
    required this.scenes,
    required this.canManage,
    this.onSceneChanged,
    this.onReorder,
    this.castByScene = const {},
  });

  @override
  Widget build(BuildContext context) {
    final reorderable = canManage && onReorder != null && scenes.length > 1;

    // En pantallas anchas, la tabla quedaba angosta (ancho fijo de
    // columnas) dejando medio ancho de pantalla vacío. Acá se calcula
    // cuánto sobra respecto al ancho mínimo y ese espacio extra se le
    // reparte a SET y LOCACIÓN (las columnas de texto más largo), para
    // que la tabla siempre ocupe TODO el ancho disponible. En pantallas
    // angostas (donde no sobra espacio) se mantiene el ancho mínimo con
    // scroll horizontal, como antes.
    return LayoutBuilder(builder: (context, constraints) {
      final extra = (constraints.maxWidth - _kTableWidth).clamp(0.0, double.infinity);
      final colSet = _kColSet + extra * 0.55;
      final colLocacion = _kColLocacion + extra * 0.45;
      final tableWidth = extra > 0 ? constraints.maxWidth : _kTableWidth;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppColors.surfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: _kColHandle),
                      SizedBox(width: _kColEsc, child: const Text('ESC', style: _kHeaderStyle)),
                      SizedBox(width: colSet, child: const Text('ENCABEZADO', style: _kHeaderStyle)),
                      SizedBox(width: _kColEspacio, child: const Text('ESPACIO', style: _kHeaderStyle)),
                      SizedBox(width: _kColMomento, child: const Text('MOMENTO', style: _kHeaderStyle)),
                      SizedBox(width: _kColReparto, child: const Text('ID DE REPARTO', style: _kHeaderStyle)),
                      SizedBox(width: colLocacion, child: const Text('LOCACIÓN DE RODAJE', style: _kHeaderStyle)),
                      SizedBox(width: _kColFecha, child: const Text('FECHA DE GRABACIÓN', style: _kHeaderStyle)),
                      SizedBox(width: _kColBloque, child: const Text('BLOQUE', style: _kHeaderStyle)),
                      SizedBox(width: _kColPaginas, child: const Text('PÁG. GUION', style: _kHeaderStyle)),
                      SizedBox(width: _kColTiempo, child: const Text('TIEMPO EST.', style: _kHeaderStyle)),
                      SizedBox(width: _kColHora, child: const Text('HORA DE INICIO', style: _kHeaderStyle)),
                      SizedBox(width: _kColNotas, child: const Text('NOTAS', style: _kHeaderStyle)),
                    ],
                  ),
                ),
                if (reorderable)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: scenes.length,
                    itemBuilder: (context, i) => Column(
                      key: ValueKey(scenes[i].idEscena ?? 'row-$i'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (i > 0) const Divider(height: 1),
                        _StripboardRow(
                          scene: scenes[i],
                          canManage: canManage,
                          onSceneChanged: onSceneChanged,
                          dragIndex: i,
                          colSet: colSet,
                          colLocacion: colLocacion,
                          cast: castByScene[scenes[i].idEscena] ?? const [],
                        ),
                      ],
                    ),
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final list = [...scenes];
                      final item = list.removeAt(oldIndex);
                      list.insert(newIndex, item);
                      onReorder!(list);
                    },
                  )
                else
                  for (int i = 0; i < scenes.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _StripboardRow(
                      scene: scenes[i],
                      canManage: canManage,
                      onSceneChanged: onSceneChanged,
                      colSet: colSet,
                      colLocacion: colLocacion,
                      cast: castByScene[scenes[i].idEscena] ?? const [],
                    ),
                  ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Fila del stripboard — cada campo "propio del plan de rodaje" (SET
/// se deriva de la escena, pero locación de rodaje, tiempo estimado,
/// hora de inicio y notas son datos que solo existen acá, no en el
/// editor general de Escenas) se edita con un tap directo, sin tener
/// que abrir el editor completo. Tocar el resto de la fila SÍ abre el
/// editor completo de la escena (para INT/EXT, momento, día dramático,
/// etc.) — pedido explícito del usuario: "algunos datos sí deberán ser
/// editables en caso de necesidad".
class _StripboardRow extends StatelessWidget {
  final Scene scene;
  final bool canManage;
  final ValueChanged<Scene>? onSceneChanged;
  final int? dragIndex;
  final double colSet;
  final double colLocacion;
  final List<Map<String, dynamic>> cast;
  const _StripboardRow({
    required this.scene,
    required this.canManage,
    this.onSceneChanged,
    this.dragIndex,
    this.colSet = _kColSet,
    this.colLocacion = _kColLocacion,
    this.cast = const [],
  });

  Future<void> _editScene(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SceneEditScreen(scene: scene)),
    );
    if (changed == true) {
      if (context.mounted) {
        context.read<PlanChangeTracker>().record(
              context.read<AuthSession>(),
              key: 'edicion|${scene.idEscena}',
              descripcion: 'ESC ${scene.numeroDeEscena}: se modificó la información de la escena',
              conValores: false,
            );
      }
      onSceneChanged?.call(scene);
    }
  }

  static const _kEtiquetaCampo = {
    'locacion_rodaje': 'Locación de rodaje',
    'tiempo_estimado': 'Tiempo estimado',
    'bloque_grabacion': 'Bloque de grabación',
    'notas_rodaje': 'Notas de rodaje',
    'hora_inicio_rodaje': 'Hora de inicio',
  };

  String? _valorActual(String campo) {
    switch (campo) {
      case 'locacion_rodaje':
        return scene.locacionRodaje;
      case 'tiempo_estimado':
        return scene.tiempoEstimado;
      case 'bloque_grabacion':
        return scene.bloqueGrabacion?.toString();
      case 'notas_rodaje':
        return scene.notasRodaje;
      case 'hora_inicio_rodaje':
        return _soloHM(scene.horaInicioRodaje);
    }
    return null;
  }

  static String? _soloHM(String? v) {
    if (v == null || v.isEmpty) return null;
    return v.length >= 5 ? v.substring(0, 5) : v;
  }

  Future<void> _updateField(BuildContext context, Map<String, dynamic> changes) async {
    final session = context.read<AuthSession>();
    final tracker = context.read<PlanChangeTracker>();
    try {
      await SceneService(session.api).updatePartial(scene.idEscena!, changes);
      changes.forEach((campo, nuevo) {
        final etiqueta = _kEtiquetaCampo[campo];
        if (etiqueta == null) return;
        var despues = nuevo?.toString();
        if (campo == 'hora_inicio_rodaje') despues = _soloHM(despues);
        if (despues != null && despues.trim().isEmpty) despues = null;
        tracker.record(
          session,
          key: '${scene.idEscena}|$campo',
          descripcion: 'ESC ${scene.numeroDeEscena} · $etiqueta',
          antes: _valorActual(campo),
          despues: despues,
        );
      });
      onSceneChanged?.call(scene);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editLocacion(BuildContext context) async {
    final value = await _promptText(context, title: 'Locación de rodaje', initial: scene.locacionRodaje, hint: 'Ej: Plaza de Bolívar, Bogotá');
    if (value != null && context.mounted) _updateField(context, {'locacion_rodaje': value});
  }

  Future<void> _editTiempoEstimado(BuildContext context) async {
    final value = await _promptText(context, title: 'Tiempo estimado', initial: scene.tiempoEstimado, hint: 'Ej: 45 min');
    if (value != null && context.mounted) _updateField(context, {'tiempo_estimado': value});
  }

  Future<void> _editBloqueGrabacion(BuildContext context) async {
    final value = await _promptText(
      context,
      title: 'Bloque de grabación',
      initial: scene.bloqueGrabacion?.toString(),
      hint: 'Ej: 1',
      keyboardType: TextInputType.number,
    );
    if (value == null || !context.mounted) return;
    _updateField(context, {'bloque_grabacion': value.trim().isEmpty ? null : int.tryParse(value.trim())});
  }

  Future<void> _editNotas(BuildContext context) async {
    final value = await _promptText(
      context,
      title: 'Notas de rodaje — ESC ${scene.numeroDeEscena}',
      initial: scene.notasRodaje,
      maxLines: 4,
      hint: 'Notas para esta escena dentro del día de rodaje...',
    );
    if (value != null && context.mounted) _updateField(context, {'notas_rodaje': value});
  }

  Future<void> _editHora(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: _parseHora(scene.horaInicioRodaje) ?? TimeOfDay.now());
    if (picked != null && context.mounted) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      _updateField(context, {'hora_inicio_rodaje': '$hh:$mm:00'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneLocacion = scene.locacionRodaje != null && scene.locacionRodaje!.isNotEmpty;
    final tieneTiempo = scene.tiempoEstimado != null && scene.tiempoEstimado!.isNotEmpty;
    final tieneHora = scene.horaInicioRodaje != null && scene.horaInicioRodaje!.isNotEmpty;
    final tieneNotas = scene.notasRodaje != null && scene.notasRodaje!.isNotEmpty;
    final tieneCiudad = scene.ciudad != null && scene.ciudad!.isNotEmpty;

    final handle = SizedBox(
      width: _kColHandle,
      child: canManage
          ? (dragIndex != null
              ? ReorderableDragStartListener(
                  index: dragIndex!,
                  child: const Icon(Icons.drag_indicator, size: 16, color: AppColors.grisMedio),
                )
              : const Icon(Icons.drag_indicator, size: 16, color: AppColors.grisMedio))
          : null,
    );

    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.border, width: 1))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            handle,
            SizedBox(
              width: _kColEsc,
              child: InkWell(
                onTap: canManage ? () => _editScene(context) : null,
                child: Text(scene.numeroDeEscena, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
            SizedBox(
              width: colSet,
              child: InkWell(
                onTap: canManage ? () => _editScene(context) : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    scene.encabezado,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColEspacio,
              child: InkWell(
                onTap: canManage ? () => _editScene(context) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.center,
                  child: Text(
                    (scene.modoVista ?? '?').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColMomento,
              child: InkWell(
                onTap: canManage ? () => _editScene(context) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconoMomentoData(scene.momentoDia), size: 12, color: AppColors.grisMedio),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          labelMomento(scene.momentoDia),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColReparto,
              child: _RepartoBadges(cast: cast),
            ),
            SizedBox(
              width: colLocacion,
              child: InkWell(
                onTap: canManage ? () => _editLocacion(context) : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: tieneLocacion ? AppColors.azulProfundo : AppColors.grisMedio),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tieneLocacion ? scene.locacionRodaje! : (canManage ? 'Asignar' : '—'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tieneLocacion ? null : AppColors.grisMedio),
                            ),
                            if (tieneCiudad)
                              Text(
                                scene.ciudad!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9, color: AppColors.grisMedio),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColFecha,
              child: InkWell(
                onTap: canManage ? () => _editScene(context) : null,
                child: Text(
                  scene.fechaDeGrabacion != null ? scene.fechaDeGrabacion!.toIso8601String().split('T').first : 'Pendiente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scene.fechaDeGrabacion != null ? null : AppColors.grisMedio,
                    fontStyle: scene.fechaDeGrabacion != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColBloque,
              child: InkWell(
                onTap: canManage ? () => _editBloqueGrabacion(context) : null,
                child: Text(
                  scene.bloqueGrabacion != null ? '${scene.bloqueGrabacion}' : (canManage ? 'Asignar' : '—'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scene.bloqueGrabacion != null ? null : AppColors.grisMedio,
                    fontStyle: scene.bloqueGrabacion != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColPaginas,
              child: Text(scene.pagina != null ? 'Pág. ${scene.pagina}' : '—', style: const TextStyle(fontSize: 11, color: AppColors.grisMedio)),
            ),
            SizedBox(
              width: _kColTiempo,
              child: InkWell(
                onTap: canManage ? () => _editTiempoEstimado(context) : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    tieneTiempo ? scene.tiempoEstimado! : (canManage ? 'Definir tiempo' : '—'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tieneTiempo ? null : AppColors.grisMedio),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColHora,
              child: InkWell(
                onTap: canManage ? () => _editHora(context) : null,
                child: Text(
                  _formatHora(context, scene.horaInicioRodaje),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tieneHora ? AppColors.azulProfundo : AppColors.grisMedio,
                    fontStyle: tieneHora ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _kColNotas,
              child: IconButton(
                icon: Icon(Icons.sticky_note_2_outlined, size: 16, color: tieneNotas ? AppColors.azulProfundo : AppColors.grisMedio),
                tooltip: tieneNotas ? scene.notasRodaje : 'Notas de esta escena',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: canManage
                    ? () => _editNotas(context)
                    : (tieneNotas ? () => _promptText(context, title: 'Notas', initial: scene.notasRodaje, maxLines: 4) : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badges circulares con el reparto asignado a la escena (personajes
/// vía `escenas_personajes`). Antes cada fila hacía su propio fetch
/// perezoso (SceneService.cast); ahora el reparto de TODAS las escenas
/// se precarga una sola vez en `_ShootingDaysScreenState._load()` (para
/// poder ordenar por "ID de reparto") y se pasa hacia abajo ya resuelto,
/// así que este widget es puramente de presentación.
class _RepartoBadges extends StatelessWidget {
  final List<Map<String, dynamic>> cast;
  const _RepartoBadges({this.cast = const []});

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 11, color: AppColors.grisMedio));
    }
    final visibles = cast.take(3).toList();
    Widget badge(String label) => Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
          child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
        );
    return Wrap(
      children: [
        for (final c in visibles)
          badge(() {
            final codigo = (c['codigo_personaje']?.toString() ?? '?');
            return codigo.length > 2 ? codigo.substring(0, 2) : codigo;
          }()),
        if (cast.length > 3) badge('+${cast.length - 3}'),
      ],
    );
  }
}

class _ScenesCountChip extends StatelessWidget {
  final int count;
  const _ScenesCountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_filter_outlined, size: 13, color: AppColors.grisMedio),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Diálogo centrado para asignar/quitar escenas de un día de rodaje.
/// Como una escena solo puede pertenecer a un día a la vez
/// (`Scene.idRodaje` es un solo valor, no una lista), marcar una
/// escena que ya está en OTRO día se la "roba" a ese día — se avisa
/// explícitamente en vez de ocultarlo.
class _AssignScenesDialog extends StatefulWidget {
  final String dayId;
  final String dayLabel;
  final List<Scene> allScenes;

  const _AssignScenesDialog({required this.dayId, required this.dayLabel, required this.allScenes});

  @override
  State<_AssignScenesDialog> createState() => _AssignScenesDialogState();
}

class _AssignScenesDialogState extends State<_AssignScenesDialog> {
  late Set<String> _seleccionadas;
  late Set<String> _originales;
  final _search = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _originales = widget.allScenes.where((s) => s.idRodaje == widget.dayId).map((s) => s.idEscena!).toSet();
    _seleccionadas = {..._originales};
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtradas = widget.allScenes.where((s) {
      if (q.isEmpty) return true;
      return s.numeroDeEscena.toLowerCase().contains(q) || s.encabezado.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.numeroDeEscena.compareTo(b.numeroDeEscena));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Escenas — ${widget.dayLabel}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${_seleccionadas.length} escena(s) seleccionada(s)', style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Buscar por número o encabezado...', prefixIcon: Icon(Icons.search, size: 20)),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: filtradas.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Sin resultados.', style: TextStyle(color: AppColors.grisMedio))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtradas.length,
                    itemBuilder: (context, i) {
                      final s = filtradas[i];
                      final checked = _seleccionadas.contains(s.idEscena);
                      final enOtroDia = s.idRodaje != null && s.idRodaje != widget.dayId;
                      return CheckboxListTile(
                        dense: true,
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _seleccionadas.add(s.idEscena!);
                            } else {
                              _seleccionadas.remove(s.idEscena);
                            }
                          });
                        },
                        title: Text('ESC ${s.numeroDeEscena} — ${s.encabezado}', style: const TextStyle(fontSize: 13)),
                        subtitle: enOtroDia && !checked
                            ? const Text('Ya asignada a otro día — se transferirá aquí si la marcas', style: TextStyle(fontSize: 11, color: AppColors.warning))
                            : null,
                      );
                    },
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _guardar,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final session = context.read<AuthSession>();
    final service = SceneService(session.api);

    final agregadas = _seleccionadas.difference(_originales);
    final quitadas = _originales.difference(_seleccionadas);
    final tracker = context.read<PlanChangeTracker>();

    String numero(String id) {
      for (final s in widget.allScenes) {
        if (s.idEscena == id) return s.numeroDeEscena;
      }
      return '?';
    }

    try {
      for (final id in agregadas) {
        await service.updatePartial(id, {'id_rodaje': widget.dayId});
        tracker.record(
          session,
          key: 'asignacion|$id',
          descripcion: 'ESC ${numero(id)} se asignó a ${widget.dayLabel}',
          conValores: false,
        );
      }
      for (final id in quitadas) {
        await service.updatePartial(id, {'id_rodaje': null});
        tracker.record(
          session,
          key: 'asignacion|$id',
          descripcion: 'ESC ${numero(id)} se quitó de ${widget.dayLabel}',
          conValores: false,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ShootingDayFormSheet extends StatefulWidget {
  final ShootingDay? existing;
  const _ShootingDayFormSheet({this.existing});

  @override
  State<_ShootingDayFormSheet> createState() => _ShootingDayFormSheetState();
}

class _ShootingDayFormSheetState extends State<_ShootingDayFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _version = TextEditingController(text: widget.existing?.version ?? '');
  late final _diaRodaje = TextEditingController(text: widget.existing?.diaRodaje?.toString() ?? '');
  late final _semana = TextEditingController(text: widget.existing?.semanaGrabacion?.toString() ?? '');
  late final _location = TextEditingController(text: widget.existing?.location ?? '');
  late final _horaInicio = TextEditingController(text: _soloHora(widget.existing?.horaInicio));
  late final _horaFin = TextEditingController(text: _soloHora(widget.existing?.horaFin));
  late final _notas = TextEditingController(text: widget.existing?.notas ?? '');
  late bool _activo = widget.existing?.activo ?? true;
  bool _loading = false;

  static String _soloHora(String? hhmmss) {
    if (hhmmss == null || hhmmss.isEmpty) return '';
    return hhmmss.length >= 5 ? hhmmss.substring(0, 5) : hhmmss;
  }

  bool get _isEdit => widget.existing != null;

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
            Text(_isEdit ? 'Editar Día de Rodaje' : 'Nuevo Día de Rodaje', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AppTextField(label: 'Versión', hint: 'v1', controller: _version, validator: _req)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Día de rodaje', hint: '1', controller: _diaRodaje, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AppTextField(label: 'Semana de grabación', hint: '1', controller: _semana, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Ubicación', hint: 'Finca El Paraíso', controller: _location)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AppTextField(label: 'Hora inicio', hint: 'HH:MM', controller: _horaInicio)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Hora fin', hint: 'HH:MM', controller: _horaFin)),
            ]),
            const SizedBox(height: 16),
            AppTextField(label: 'Notas', controller: _notas, maxLines: 3),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _activo,
              onChanged: (v) => setState(() => _activo = v),
              title: const Text('Día activo'),
            ),
            const SizedBox(height: 12),
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

    final horaInicio = _horaInicio.text.trim().isEmpty ? null : '${_horaInicio.text.trim()}:00';
    final horaFin = _horaFin.text.trim().isEmpty ? null : '${_horaFin.text.trim()}:00';

    final tracker = context.read<PlanChangeTracker>();
    final etiquetaDia = _diaRodaje.text.trim().isNotEmpty ? 'Día ${_diaRodaje.text.trim()}' : 'Versión ${_version.text.trim()}';

    try {
      if (_isEdit) {
        await ShootingDayService(session.api).update(widget.existing!.idRodaje!, {
          'version': _version.text.trim(),
          'dia_rodaje': int.tryParse(_diaRodaje.text.trim()),
          'semana_grabacion': int.tryParse(_semana.text.trim()),
          'location': _location.text.trim(),
          'hora_inicio': horaInicio,
          'hora_fin': horaFin,
          'notas': _notas.text.trim(),
          'activo': _activo,
        });
      } else {
        await ShootingDayService(session.api).create(ShootingDay(
          version: _version.text.trim(),
          diaRodaje: int.tryParse(_diaRodaje.text.trim()),
          semanaGrabacion: int.tryParse(_semana.text.trim()),
          location: _location.text.trim(),
          horaInicio: horaInicio,
          horaFin: horaFin,
          notas: _notas.text.trim(),
          activo: _activo,
          idProject: session.projectId,
        ));
      }
      tracker.record(
        session,
        key: 'dia|${widget.existing?.idRodaje ?? 'nuevo|${_version.text.trim()}|${_diaRodaje.text.trim()}'}',
        descripcion: _isEdit ? 'Se modificó el $etiquetaDia de rodaje' : 'Se creó el $etiquetaDia de rodaje',
        conValores: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
