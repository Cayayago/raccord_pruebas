import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/tour_kit.dart';

/// Llaves de los widgets que ilumina el recorrido de "Gestión de Proyectos".
/// Las crea la pantalla y las adjunta [ProjectsAdminPanel].
class ProjectsTourKeys {
  final lista = GlobalKey(debugLabel: 'tour_lista');
  final crear = GlobalKey(debugLabel: 'tour_crear');
  final buscador = GlobalKey(debugLabel: 'tour_buscador');
  final tarjetas = GlobalKey(debugLabel: 'tour_tarjetas');
  final estado = GlobalKey(debugLabel: 'tour_estado');
  final directores = GlobalKey(debugLabel: 'tour_directores');
  final genero = GlobalKey(debugLabel: 'tour_genero');
  final formato = GlobalKey(debugLabel: 'tour_formato');
  final causal = GlobalKey(debugLabel: 'tour_causal');
  final usuarios = GlobalKey(debugLabel: 'tour_usuarios');
}

/// Lanza el recorrido de Proyectos (ver [showTour] para `mandatory`).
TutorialCoachMark showProjectsTour(
  BuildContext context,
  ProjectsTourKeys k, {
  required bool mandatory,
  VoidCallback? onEnd,
}) {
  return showTour(
    context,
    [
      TourStep('lista', k.lista, ContentAlign.right, 'Tus proyectos',
          'Aquí aparecen todos los proyectos que tienes o realizas. Al hacer clic en uno, entras a toda su información y puedes comenzar a realizarlo y gestionarlo: guion, escenas, desglose y plan de rodaje.'),
      TourStep('crear', k.crear, ContentAlign.right, 'Crear proyectos',
          'En la parte inferior puedes crear un proyecto nuevo cuando lo necesites.'),
      TourStep('buscador', k.buscador, ContentAlign.bottom, 'Búsqueda',
          'Escribe aquí para buscar un proyecto por su nombre.'),
      TourStep('tarjetas', k.tarjetas, ContentAlign.bottom, 'Resumen',
          'Cuántos proyectos tienes en total, cuántos están en rodaje, suspendidos o finalizados, y cuántos usuarios participan en tus proyectos.'),
      TourStep('estado', k.estado, ContentAlign.left, 'Gráficos interactivos',
          'Cada barra es un filtro: toca una y todo el panel se limita a esos proyectos. Vuelve a tocarla para quitar el filtro.'),
      TourStep('directores', k.directores, ContentAlign.right, 'Filtra por director',
          'Selecciona un director de la tabla y solo verás la información de sus proyectos.'),
      TourStep('genero', k.genero, ContentAlign.top, 'Combina filtros',
          'Si además eliges un género, el panel muestra solo los proyectos de ese director y de ese tipo de género.'),
      TourStep('formato', k.formato, ContentAlign.top, 'Formato del proyecto',
          'Aquí ves cuántos proyectos son películas, series, cortometrajes, etc. Toca una barra para filtrar por formato.'),
      TourStep('causal', k.causal, ContentAlign.top, 'Causal de suspensión',
          'Si tienes proyectos suspendidos, aquí ves el motivo de cada suspensión. Toca una barra para ver solo esos proyectos.'),
      TourStep('usuarios', k.usuarios, ContentAlign.top, 'Usuarios por proyecto',
          'Muestra cuántas personas participan en cada proyecto, para que sepas de un vistazo el tamaño de cada equipo.'),
    ],
    mandatory: mandatory,
    onEnd: onEnd,
  );
}
