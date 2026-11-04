import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../models/scene.dart';
import '../../services/character_service.dart';
import '../../services/scene_service.dart';
import '../../services/script_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/simple_bar_chart.dart';

class _ModuleDef {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String modulo;
  const _ModuleDef(this.title, this.icon, this.color, this.route, this.modulo);
}

const _modules = [
  _ModuleDef('Guión', Icons.description_outlined, AppColors.azulProfundo, '/guiones', 'guion'),
  _ModuleDef('Escenas', Icons.movie_filter_outlined, AppColors.moradoTech, '/escenas', 'escenas'),
  _ModuleDef('Desglose', Icons.checklist_outlined, AppColors.grisMedio, '/desglose', 'desglose'),
  _ModuleDef('Plan de Rodaje', Icons.event_note_outlined, AppColors.coral, '/plan-rodaje', 'plan_rodaje'),
];

/// Shell del proyecto (mockups 7, 7.1, 7.2): header, menú lateral con
/// los 8 módulos y tarjetas de acceso rápido.
class ProjectDashboardScreen extends StatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  // GlobalObjectKey en vez de un GlobalKey<> a secas: su igualdad se basa
  // en el VALOR (projectId), igual que la ValueKey que se usaba antes acá
  // (ver comentario grande más abajo, junto a _ProjectCharts) — así se
  // conserva ese fix (recrea el State si cambia de proyecto) y ADEMÁS
  // permite llegar al State desde afuera (currentState) para poder
  // disparar su recarga con el gesto de "deslizar hacia abajo".
  GlobalObjectKey<_ProjectChartsState>? _chartsKey;

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh): las
  // tarjetas de módulos de arriba son estáticas (no piden datos), así
  // que solo hace falta recargar el panel de gráficos/resumen.
  Future<void> _onPullRefresh() async {
    await _chartsKey?.currentState?._load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    _chartsKey = GlobalObjectKey<_ProjectChartsState>(session.projectId ?? 'sin-proyecto');

    return AppScaffold(
      // El Dashboard ES la pantalla del proyecto, así que su título
      // sigue siendo el nombre del proyecto (a diferencia del resto de
      // pantallas, que pasan su propio nombre — "Guiones", "Escenas",
      // etc. — y a ESE se le antepone el proyecto). Ver _titleWithProject
      // en app_scaffold.dart: detecta que title == projectName acá y no
      // lo duplica ("Nubes - Nubes"), lo deja tal cual.
      title: session.projectName ?? 'Proyecto',
      // Ya estamos en el Dashboard: no tiene sentido mostrar el ícono de
      // casa que lleva ahí mismo.
      showHome: false,
      // El ícono de notificaciones vive SOLO acá — pedido explícito del
      // usuario, para no quitarle espacio al logo/título en el resto de
      // pantallas.
      showNotifications: true,
      // Flecha para volver a "Gestión de Proyectos": la persona puede
      // trabajar en varios proyectos sin tener que salir de la plataforma
      // (cerrar sesión) para cambiar de uno a otro.
      showBack: true,
      onBack: () async {
        await session.clearProject();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/proyectos', (r) => false);
        }
      },
      // El menú de módulos es un panel lateral tipo "hamburguesa" que se
      // abre desde el borde derecho (ver botón de menú en la barra
      // superior), en vez de una lista que empujaba las tarjetas hacia
      // abajo. `AppScaffold` ya lo arma por defecto (showModuleMenu:
      // true), igual que en todas las demás pantallas del proyecto.
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: MobileRefresh(
          onRefresh: _onPullRefresh,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              // Ancho máximo generoso (pedido explícito del usuario: "que
              // ocupe mayor pantalla, separada unos cms de los márgenes")
              // — antes 1100 dejaba huecos enormes en pantallas anchas de
              // escritorio; 1600 aprovecha mucho más el ancho real y solo
              // dejará márgenes visibles en monitores muy grandes.
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    // En PC (>900px) se ven las 4 tarjetas en una sola
                    // fila. Por debajo de eso, antes caía a 1 sola
                    // columna (cada tarjeta ocupando TODO el ancho de la
                    // pantalla) — en celular eso las hacía verse enormes.
                    // Ahora se usan 2 columnas (grilla 2x2) en cualquier
                    // pantalla móvil/tablet, y solo se baja a 1 columna en
                    // celulares realmente angostos (<340px), donde ni 2
                    // columnas entrarían con un tamaño usable.
                    final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 340 ? 2 : 1);
                    final spacing = constraints.maxWidth <= 560 ? 12.0 : 20.0;
                    final cardWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
                    // GridView.count con un childAspectRatio fijo se
                    // desbordaba "BOTTOM OVERFLOWED BY X PIXELS" en
                    // anchos intermedios (ej. tablet en horizontal con 4
                    // columnas): el contenido de ModuleCard mide un alto
                    // ligeramente distinto según el ancho real de cada
                    // tarjeta, y una sola proporción fija no acertaba en
                    // todos los tamaños de pantalla a la vez. Con `Wrap`
                    // cada tarjeta mide su ALTO real según su contenido
                    // (solo se fija el ancho vía SizedBox) — no hay
                    // proporción que adivinar, así que no puede desbordar.
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _modules
                          .where((m) => session.canSeeModule(m.modulo))
                          .map((m) => SizedBox(
                                width: cardWidth,
                                child: ModuleCard(
                                  icon: m.icon,
                                  color: m.color,
                                  title: m.title,
                                  onTap: () => Navigator.of(context).pushNamed(m.route),
                                ),
                              ))
                          .toList(),
                    );
                  }),
                  const SizedBox(height: 24),
                  // key con projectId (no const): al refrescar el
                  // navegador estando YA en /dashboard, esta pantalla se
                  // construye antes de que AuthSession.bootstrap() termine
                  // de leer SharedPreferences (session.projectId todavía
                  // null), así que _ProjectCharts._load() no encuentra
                  // proyecto y se queda con el spinner pegado para
                  // siempre. Este widget SÍ escucha a AuthSession
                  // (context.watch arriba) y se reconstruye en cuanto
                  // bootstrap() resuelve, pero al ser un StatefulWidget
                  // con la MISMA key de antes, Flutter reutiliza el State
                  // existente y jamás vuelve a llamar initState()/_load().
                  // Cambiar la key según projectId fuerza a Flutter a
                  // descartar ese State viejo y crear uno nuevo (con
                  // initState nuevo) apenas hay proyecto disponible.
                  // (Ahora es un GlobalObjectKey — ver _chartsKey arriba —
                  // en vez de una ValueKey simple, para además poder
                  // disparar su recarga desde el pull-to-refresh de esta
                  // pantalla, pero el efecto de "recrear si cambia el
                  // proyecto" es el mismo.)
                  _ProjectCharts(key: _chartsKey),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Panel de gráficos "muy sencillo pero dinámico" (pedido explícito
/// del usuario) con el resumen completo del proyecto: guiones,
/// escenas, días dramáticos, fechas de grabación y personajes en una
/// misma fila de tarjetas, y debajo los gráficos de barras (estado,
/// espacio, momento, horario de grabación y ciudad). Reemplaza al
/// antiguo panel oscuro de "Guiones/Escenas/Días de rodaje" — se pidió
/// explícitamente fusionar esos conteos acá y quitar "días de rodaje"
/// (el conteo manual de Plan de Rodaje, no el calculado por fecha).
/// Todo se calcula en el cliente a partir de datos que ya trae el
/// backend — no hace falta ningún endpoint nuevo. Colores suaves
/// (opacidad reducida sobre la paleta de marca) en vez de los tonos
/// planos y saturados que ya usa el resto de la app, también pedido
/// explícito del usuario.
class _ProjectCharts extends StatefulWidget {
  const _ProjectCharts({super.key});

  @override
  State<_ProjectCharts> createState() => _ProjectChartsState();
}

class _ProjectChartsState extends State<_ProjectCharts> {
  List<Scene>? _scenes;
  int? _guiones;
  int? _personajes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<AuthSession>();
    final projectId = session.projectId;
    if (projectId == null) {
      // No se queda pegado en el spinner si por algún motivo todavía no
      // hay proyecto activo (ver comentario en project_dashboard_screen
      // sobre la key: normalmente este caso se resuelve solo apenas
      // AuthSession.bootstrap() termina y este widget se recrea).
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final scripts = await ScriptService(session.api).byProject(projectId);
      final scenes = <Scene>[];
      for (final s in scripts) {
        if (s.idGuion != null) {
          scenes.addAll(await SceneService(session.api).byScript(s.idGuion!));
        }
      }
      final personajes = await CharacterService(session.api).all(projectId);

      if (!mounted) return;
      setState(() {
        _scenes = scenes;
        _guiones = scripts.length;
        _personajes = personajes.length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator());
    }

    // Ya no se corta todo el panel si aún no hay escenas: Guiones,
    // Escenas y Personajes deben verse igual (antes vivían en una barra
    // aparte que siempre se mostraba) — solo los gráficos de barras
    // quedan con su mensaje vacío propio cuando no hay datos.
    final scenes = _scenes ?? [];
    final porEstado = _contarPorEstado(scenes);
    final porEspacio = _contarPorEspacio(scenes);
    final porMomento = _contarPorMomento(scenes);
    final porCiudad = _contarPorCiudad(scenes);
    final diasDramaticos = scenes.map((s) => s.diaDramatico).whereType<int>().toSet().length;
    final diasRodaje = _diasDeRodaje(scenes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Resumen del proyecto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth > 900
              ? 5
              : (constraints.maxWidth > 680 ? 3 : (constraints.maxWidth > 420 ? 2 : 1));
          const spacing = 14.0;
          final cardWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
          // Mismo motivo que la grilla de módulos de arriba: un
          // childAspectRatio fijo (2.6) se quedaba corto por 1-2px justo
          // en el punto donde entran 5 columnas en una tablet — con
          // `Wrap` cada tarjeta mide su alto real (fijo, ~72px, no
          // depende del ancho) y nunca se desborda.
          final stats = [
            StatCard(label: 'Guiones', value: '${_guiones ?? 0}', icon: Icons.description_outlined, color: AppColors.azulProfundo),
            StatCard(label: 'Escenas', value: '${scenes.length}', icon: Icons.movie_filter_outlined, color: AppColors.moradoTech),
            StatCard(label: 'Días Dramáticos', value: '$diasDramaticos', icon: Icons.auto_stories_outlined, color: AppColors.coral),
            StatCard(label: 'Fechas de Grabación', value: '${diasRodaje.total}', icon: Icons.calendar_month_outlined, color: AppColors.azulProfundo),
            StatCard(label: 'Personajes', value: '${_personajes ?? 0}', icon: Icons.people_alt_outlined, color: AppColors.moradoTech),
          ];
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [for (final s in stats) SizedBox(width: cardWidth, child: s)],
          );
        }),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final twoCols = constraints.maxWidth > 700;
          final cards = <Widget>[
            BarChartCard(
              title: 'Escenas por Estado',
              icon: Icons.bar_chart_outlined,
              entries: [
                BarChartEntry(label: 'Finalizada', value: porEstado['Finalizada'] ?? 0, color: AppColors.success.withOpacity(0.75)),
                BarChartEntry(label: 'En proceso', value: porEstado['En proceso'] ?? 0, color: AppColors.warning.withOpacity(0.75)),
                BarChartEntry(label: 'Pendiente', value: porEstado['Pendiente'] ?? 0, color: AppColors.azulProfundo.withOpacity(0.6)),
                BarChartEntry(label: 'Eliminada', value: porEstado['Eliminada'] ?? 0, color: AppColors.grisMedio.withOpacity(0.6)),
              ],
            ),
            BarChartCard(
              title: 'Escenas por Momento',
              icon: Icons.nightlight_outlined,
              // Antes llevaba el emoji de `iconoMomento` delante del
              // texto — Flutter Web no tiene ese glifo en ninguna fuente
              // empaquetada y tira la advertencia "Could not find a set
              // of Noto fonts..." en consola. La tarjeta ya trae su
              // propio ícono (nightlight_outlined) arriba, así que se
              // quita sin perder información.
              entries: kMomentosDia
                  .map((m) => BarChartEntry(
                        label: labelMomento(m),
                        value: porMomento[m] ?? 0,
                        color: AppColors.moradoTech.withOpacity(0.6),
                      ))
                  .toList(),
            ),
            BarChartCard(
              title: 'Escenas por Espacio',
              icon: Icons.home_work_outlined,
              entries: porEspacio.entries.map((e) => BarChartEntry(label: e.key, value: e.value, color: AppColors.azulProfundo.withOpacity(0.6))).toList(),
            ),
            BarChartCard(
              title: 'Horario de Grabación',
              icon: Icons.event_note_outlined,
              emptyMessage: 'Asigna fecha y momento a las escenas para ver este dato.',
              entries: [
                BarChartEntry(label: '☀️ Día', value: diasRodaje.dia, color: AppColors.warning.withOpacity(0.7)),
                BarChartEntry(label: '🌙 Noche', value: diasRodaje.noche, color: AppColors.azulProfundo.withOpacity(0.7)),
              ],
            ),
            if (porCiudad.isNotEmpty)
              BarChartCard(
                title: 'Escenas por Ciudad',
                icon: Icons.location_city_outlined,
                entries: porCiudad.entries.take(6).map((e) => BarChartEntry(label: e.key, value: e.value, color: AppColors.coral.withOpacity(0.6))).toList(),
              ),
          ];

          if (!twoCols) {
            return Column(children: [for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 14), child: c)]);
          }

          // Dos columnas: reparte las tarjetas en pares (izquierda/derecha).
          // Si queda una tarjeta impar sola al final (ej. "Escenas por
          // Ciudad" cuando las demás ya se emparejaron), ocupa todo el
          // ancho de la fila en vez de dejar un hueco vacío al lado —
          // pedido explícito del usuario.
          final rows = <Widget>[];
          for (var i = 0; i < cards.length; i += 2) {
            final esImparAlFinal = i + 1 >= cards.length;
            rows.add(Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: esImparAlFinal
                  ? cards[i]
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[i]),
                        const SizedBox(width: 14),
                        Expanded(child: cards[i + 1]),
                      ],
                    ),
            ));
          }
          return Column(children: rows);
        }),
      ],
    );
  }

  Map<String, int> _contarPorEstado(List<Scene> scenes) {
    final counts = <String, int>{};
    for (final s in scenes) {
      counts[s.estado] = (counts[s.estado] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _contarPorMomento(List<Scene> scenes) {
    final counts = <String, int>{};
    for (final s in scenes) {
      if (s.momentoDia == null) continue;
      counts[s.momentoDia!] = (counts[s.momentoDia!] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _contarPorEspacio(List<Scene> scenes) {
    final counts = <String, int>{};
    for (final s in scenes) {
      final label = (s.modoVista == null || s.modoVista!.isEmpty) ? 'Sin definir' : s.modoVista!.toUpperCase();
      counts[label] = (counts[label] ?? 0) + 1;
    }
    // Orden estable y legible: INT, EXT, combinaciones y por último "Sin definir".
    final orden = ['INT', 'EXT', 'INT/EXT', 'EXT/INT', 'Sin definir'];
    final ordenado = <String, int>{};
    for (final k in orden) {
      if (counts.containsKey(k)) ordenado[k] = counts[k]!;
    }
    for (final k in counts.keys) {
      if (!ordenado.containsKey(k)) ordenado[k] = counts[k]!;
    }
    return ordenado;
  }

  Map<String, int> _contarPorCiudad(List<Scene> scenes) {
    final counts = <String, int>{};
    for (final s in scenes) {
      final ciudad = s.ciudad?.trim();
      if (ciudad == null || ciudad.isEmpty) continue;
      counts[ciudad] = (counts[ciudad] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  /// Cuenta los días de rodaje distintos (por fecha_de_grabacion) y, de
  /// esos, cuántos son mayormente de noche vs de día — pedido explícito
  /// del usuario. Un día se clasifica como "Noche" solo si más escenas
  /// de ese día son 'noche' que del resto de momentos combinados;
  /// amanecer/atardecer/anochecer (transiciones) cuentan hacia "Día"
  /// para esta métrica binaria en particular (el detalle completo por
  /// momento ya se ve en "Escenas por Momento").
  ({int total, int dia, int noche}) _diasDeRodaje(List<Scene> scenes) {
    final porFecha = <DateTime, List<Scene>>{};
    for (final s in scenes) {
      final f = s.fechaDeGrabacion;
      if (f == null) continue;
      final key = DateTime(f.year, f.month, f.day);
      porFecha.putIfAbsent(key, () => []).add(s);
    }

    var dia = 0, noche = 0;
    for (final escenasDelDia in porFecha.values) {
      final noches = escenasDelDia.where((s) => s.momentoDia == 'noche').length;
      final resto = escenasDelDia.length - noches;
      if (noches > resto) {
        noche++;
      } else {
        dia++;
      }
    }

    return (total: porFecha.length, dia: dia, noche: noche);
  }
}
