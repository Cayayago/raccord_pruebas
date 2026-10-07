import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';
import 'api_exception.dart';
import 'session.dart';

class _PlanChange {
  final String descripcion;
  final String? antes;
  final String? despues;
  final bool tieneValores;

  const _PlanChange({
    required this.descripcion,
    this.antes,
    this.despues,
    required this.tieneValores,
  });

  String get linea {
    if (!tieneValores) return '• $descripcion';
    return '• $descripcion: «${antes ?? '—'}» → «${despues ?? '—'}»';
  }
}

/// Acumula los cambios hechos en el Plan de Rodaje (fecha, locación,
/// hora, orden, escenas asignadas, etc.) para ofrecer, al salir del
/// módulo, publicar UNA notificación general que los resuma ("Notificar
/// estos cambios al equipo"). Si la sesión se cierra por inactividad con
/// cambios pendientes, se envían solos (ver InactivityWatcher).
///
/// Solo registra si la persona puede publicar notificaciones
/// (Jefe de Departamento / Director).
class PlanChangeTracker extends ChangeNotifier {
  final Map<String, _PlanChange> _changes = {};
  String? _projectId;
  bool _sending = false;

  bool get hasPending => _changes.isNotEmpty;
  int get count => _changes.length;

  /// Registra un cambio. Si la misma [key] ya existía se conserva el valor
  /// "antes" original y se actualiza el "después"; si al final ambos
  /// coinciden, el cambio se descarta (se deshizo).
  void record(
    AuthSession session, {
    required String key,
    required String descripcion,
    String? antes,
    String? despues,
    bool conValores = true,
  }) {
    if (!session.can('publish_notifications')) return;
    final pid = session.projectId;
    if (pid == null) return;

    if (_projectId != null && _projectId != pid) _changes.clear();
    _projectId = pid;

    final previo = _changes[key];
    final antesFinal = previo != null ? previo.antes : antes;

    if (conValores && (antesFinal ?? '') == (despues ?? '')) {
      _changes.remove(key);
    } else {
      _changes[key] = _PlanChange(
        descripcion: descripcion,
        antes: antesFinal,
        despues: despues,
        tieneValores: conValores,
      );
    }
    notifyListeners();
  }

  void clear() {
    if (_changes.isEmpty) return;
    _changes.clear();
    notifyListeners();
  }

  String buildText() {
    final lineas = _changes.values.map((c) => c.linea).join('\n');
    return 'Cambios en el Plan de Rodaje:\n$lineas';
  }

  /// Publica la notificación general con los cambios acumulados. Devuelve
  /// true si se envió (o no había nada). No lanza: los errores devuelven
  /// false y los cambios se conservan.
  Future<bool> flush(AuthSession session) async {
    if (_changes.isEmpty) return true;
    if (_sending) return false;
    final pid = _projectId ?? session.projectId;
    if (pid == null) return false;

    _sending = true;
    try {
      await NotificationService(session.api).crear(
        pid,
        tipoAlcance: kAlcanceGeneral,
        texto: buildText(),
        origen: kOrigenPlanRodaje,
      );
      _changes.clear();
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    } finally {
      _sending = false;
    }
  }

  /// Si hay cambios pendientes muestra el diálogo centrado. Devuelve true
  /// si la persona puede continuar con su navegación (notificó o eligió
  /// no notificar) y false si debe quedarse (seguir editando o falló el
  /// envío).
  static Future<bool> confirmLeave(BuildContext context) async {
    final tracker = context.read<PlanChangeTracker>();
    if (!tracker.hasPending) return true;

    final session = context.read<AuthSession>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.campaign_outlined, size: 32),
        title: const Text('Notificar estos cambios al equipo'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(child: Text(tracker.buildText())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop('seguir'), child: const Text('Seguir editando')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('no'), child: const Text('No notificar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('si'), child: const Text('Notificar')),
        ],
      ),
    );

    switch (choice) {
      case 'si':
        final ok = await tracker.flush(session);
        if (!ok) {
          messenger?.showSnackBar(const SnackBar(content: Text('No se pudo enviar la notificación. Intenta de nuevo.')));
        } else {
          messenger?.showSnackBar(const SnackBar(content: Text('Cambios notificados al equipo.')));
        }
        return ok;
      case 'no':
        tracker.clear();
        return true;
      default:
        return false;
    }
  }
}
