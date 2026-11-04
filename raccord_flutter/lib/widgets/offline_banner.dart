import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Envuelve TODA la app (ver MaterialApp.builder en main.dart, al lado
/// de InactivityWatcher) para avisar en tiempo real cuando el
/// dispositivo se queda sin Wi-Fi/datos móviles — sin importar en qué
/// pantalla esté la persona (login, selección de proyecto, dashboard,
/// cualquiera).
///
/// IMPORTANTE — esto es un AVISO, no un modo offline real: Raccord no
/// guarda nada en cola ni bloquea la interacción por sí solo. Cada
/// pantalla sigue haciendo sus peticiones normales y mostrando su
/// propio error si fallan (ver ApiException/ErrorView), exactamente
/// como antes. Este banner solo le explica a la persona POR QUÉ algo
/// puede estar fallando, en vez de dejarla adivinar frente a un error
/// genérico.
///
/// Tampoco garantiza que haya Internet de verdad: connectivity_plus
/// detecta el ESTADO DEL RADIO (Wi-Fi/datos encendidos o no), no si
/// esa red tiene salida real (ej. Wi-Fi de hotel con portal cautivo
/// reportaría "conectado" igual). Cubre el caso más común (modo avión,
/// Wi-Fi/datos apagados) sin pretender ser un chequeo perfecto.
class OfflineBannerWidget extends StatefulWidget {
  final Widget child;
  const OfflineBannerWidget({super.key, required this.child});

  @override
  State<OfflineBannerWidget> createState() => _OfflineBannerWidgetState();
}

class _OfflineBannerWidgetState extends State<OfflineBannerWidget> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    // Estado inicial: onConnectivityChanged solo dispara ante un
    // CAMBIO de red, no al suscribirse — sin este chequeo, alguien que
    // abre la app ya sin conexión no vería el banner hasta el próximo
    // cambio (ej. hasta que la red vuelva y se vaya de nuevo).
    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      setState(() => _isOffline = _sinConexion(results));
    });

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _isOffline = _sinConexion(results));
    });
  }

  bool _sinConexion(List<ConnectivityResult> results) {
    return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          // SafeArea propio (bottom: false): este banner vive POR
          // ENCIMA del Navigator (ver main.dart), así que no hereda el
          // SafeArea que ya aplica cada Scaffold — sin esto, en un
          // celular con notch el texto quedaría debajo de la cámara/
          // reloj del sistema.
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              color: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Sin conexión a Internet. Algunas acciones pueden no funcionar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
