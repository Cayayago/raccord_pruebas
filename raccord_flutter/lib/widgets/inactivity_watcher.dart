import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/navigation_keys.dart';
import '../core/plan_change_tracker.dart';
import '../core/session.dart';
import '../core/theme_controller.dart';

// ==========================================
// CIERRE DE SESIÓN POR INACTIVIDAD
// ==========================================
// kInactivityTimeout: tiempo total sin actividad antes de cerrar la
// sesión automáticamente.
// kInactivityWarning: cuánto antes del cierre se muestra el aviso
// (o sea, el aviso aparece a los kInactivityTimeout - kInactivityWarning
// minutos de inactividad, y da esta ventana para reaccionar).
const kInactivityTimeout = Duration(minutes: 15);
const kInactivityWarning = Duration(seconds: 60);

/// Envuelve TODA la app (ver MaterialApp.builder en main.dart) para
/// detectar actividad del usuario sin importar en qué pantalla esté:
/// el Listener queda por encima del Navigator, así que también
/// recibe los eventos de punteros que ocurren sobre diálogos/overlays.
///
/// Solo corre el temporizador mientras hay sesión activa
/// (AuthSession.isAuthenticated) — en la pantalla de login no tiene
/// sentido y no hace nada.
class InactivityWatcher extends StatefulWidget {
  final Widget child;
  const InactivityWatcher({super.key, required this.child});

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _logoutTimer;
  bool _wasAuthenticated = false;
  bool _dialogOpen = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    _registerActivity();
    return false; // solo observa, nunca "consume" la tecla
  }

  void _registerActivity() {
    if (!_wasAuthenticated || _loggingOut) return;

    if (_dialogOpen) {
      final nav = rootNavigatorKey.currentState;
      if (nav != null && nav.canPop()) nav.pop();
      _dialogOpen = false;
    }

    _restartTimers();
  }

  void _restartTimers() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    if (!_wasAuthenticated) return;

    final warningDelay = kInactivityTimeout - kInactivityWarning;
    _warningTimer = Timer(warningDelay, _showWarningDialog);
    _logoutTimer = Timer(kInactivityTimeout, _forceLogout);
  }

  void _stopTimers() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _warningTimer = null;
    _logoutTimer = null;
  }

  void _showWarningDialog() {
    if (_dialogOpen || !_wasAuthenticated || _loggingOut) return;
    final ctx = rootNavigatorKey.currentState?.overlay?.context;
    if (ctx == null) return;

    _dialogOpen = true;

    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) => _InactivityWarningDialog(
        duration: kInactivityWarning,
        onContinue: () {
          Navigator.of(dialogContext).pop();
          _dialogOpen = false;
          _restartTimers();
        },
      ),
    ).then((_) => _dialogOpen = false);
  }

  Future<void> _forceLogout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    _stopTimers();

    if (_dialogOpen) {
      final nav = rootNavigatorKey.currentState;
      if (nav != null && nav.canPop()) nav.pop();
      _dialogOpen = false;
    }

    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      // Cambios pendientes del Plan de Rodaje: se notifican solos ANTES de
      // cerrar la sesión (el token aún debe ser válido).
      try {
        await context.read<PlanChangeTracker>().flush(context.read<AuthSession>());
      } catch (_) {}
      if (!context.mounted) return;
      await context.read<AuthSession>().logout();
      // Mismo criterio que el "Salir" manual del menú (ver
      // widgets/app_scaffold.dart): el login siempre debe quedar en
      // modo oscuro, sin importar el tema que tenía elegido la persona
      // mientras estaba dentro.
      context.read<ThemeController>().resetToDark();
    }

    await rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );

    final messengerContext = rootNavigatorKey.currentContext;
    if (messengerContext != null) {
      ScaffoldMessenger.maybeOf(messengerContext)?.showSnackBar(
        const SnackBar(content: Text('Tu sesión se cerró por inactividad.')),
      );
    }

    _loggingOut = false;
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = context.watch<AuthSession>().isAuthenticated;

    if (isAuth != _wasAuthenticated) {
      _wasAuthenticated = isAuth;
      if (isAuth) {
        _restartTimers();
      } else {
        _stopTimers();
        _dialogOpen = false;
      }
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registerActivity(),
      onPointerMove: (_) => _registerActivity(),
      onPointerSignal: (_) => _registerActivity(),
      onPointerHover: (_) => _registerActivity(),
      child: widget.child,
    );
  }
}

class _InactivityWarningDialog extends StatefulWidget {
  final Duration duration;
  final VoidCallback onContinue;

  const _InactivityWarningDialog({
    required this.duration,
    required this.onContinue,
  });

  @override
  State<_InactivityWarningDialog> createState() => _InactivityWarningDialogState();
}

class _InactivityWarningDialogState extends State<_InactivityWarningDialog> {
  late int _remaining = widget.duration.inSeconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _ticker?.cancel();
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.timer_outlined, size: 32),
      title: const Text('¿Sigues ahí?'),
      content: Text(
        'Por tu seguridad, vamos a cerrar tu sesión por inactividad '
        'en $_remaining segundos.',
      ),
      actions: [
        FilledButton(
          onPressed: widget.onContinue,
          child: const Text('Seguir conectado'),
        ),
      ],
    );
  }
}
