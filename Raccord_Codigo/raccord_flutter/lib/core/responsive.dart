import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Ancho por debajo del cual se considera "móvil" — mismo umbral que ya
/// usaba `AppScaffold` internamente (`isNarrow`) para achicar el wordmark
/// y las acciones del AppBar.
const double kMobileBreakpoint = 600;

/// true si la pantalla actual es de ancho "móvil" (< 600px). Se usa para
/// decidir qué elementos de layout (AppBar, tarjetas del dashboard, etc.)
/// deben achicarse/apilarse en pantallas angostas.
bool isMobileScreen(BuildContext context) => MediaQuery.of(context).size.width < kMobileBreakpoint;

/// true solo si esta build puede ofrecer la "vista dividida" (guion en
/// PDF + contenido lado a lado) de Escenas/Editar Escena/Desglose.
///
/// Antes esto se decidía SOLO por ancho de pantalla (`!isMobileScreen`),
/// lo que dejaba pasar tablets en horizontal (>600px de ancho) aunque
/// corrieran la app NATIVA — pedido explícito del usuario (2026-09-20):
/// "los dispositivos como tablets o celular ningun usuario debe tener
/// vista dividida con el guion, solo esta funcion estara en el la pc".
/// Como la decisión de producto ya tomada es PC = Web, Móvil/Tablet = app
/// nativa, `kIsWeb` por sí solo ya identifica "es PC" de forma confiable
/// (nunca hay un navegador corriendo en el celular/tablet de este
/// proyecto) — se combina con el ancho solo como respaldo extra, por si
/// alguna vez se abre Raccord Web en una ventana angosta.
bool canUseSplitView(BuildContext context) => kIsWeb && !isMobileScreen(context);
