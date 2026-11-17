import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/permissions.dart';

void main() {
  group('hasPermission — matriz por rol (espejo de permissions.py)', () {
    // Regla: solo el Administrador crea proyectos; el Director elige entre existentes.
    test('solo el Administrador puede crear proyectos', () {
      expect(hasPermission(Roles.administrador, 'create_project'), isTrue);
      expect(hasPermission(Roles.director, 'create_project'), isFalse);
      expect(hasPermission(Roles.jefeDepartamento, 'create_project'), isFalse);
    });

    // Regla: el Admin ve fotos pero no las elimina (valor "distinto" del Director).
    test('el Administrador no puede eliminar fotos, el Director sí', () {
      expect(hasPermission(Roles.administrador, 'delete_photos'), isFalse);
      expect(hasPermission(Roles.director, 'delete_photos'), isTrue);
      expect(hasPermission(Roles.onset, 'delete_photos'), isTrue);
    });

    test('papelera: Admin solo lee, Director y Jefe gestionan, Onset no entra', () {
      expect(hasPermission(Roles.administrador, 'view_recycle_bin'), isTrue);
      expect(hasPermission(Roles.administrador, 'manage_recycle_bin'), isFalse);
      expect(hasPermission(Roles.director, 'manage_recycle_bin'), isTrue);
      expect(hasPermission(Roles.jefeDepartamento, 'manage_recycle_bin'), isTrue);
      expect(hasPermission(Roles.onset, 'view_recycle_bin'), isFalse);
    });

    test('publicar notificaciones: Director y Jefe, nunca el Administrador', () {
      expect(hasPermission(Roles.director, 'publish_notifications'), isTrue);
      expect(hasPermission(Roles.jefeDepartamento, 'publish_notifications'), isTrue);
      expect(hasPermission(Roles.administrador, 'publish_notifications'), isFalse);
    });

    test('el rol Usuario es solo lectura: no tiene ningún permiso de escritura', () {
      const escritura = [
        'full_management', 'create_project', 'manage_projects', 'invite_users',
        'upload_scripts', 'create_scenes', 'create_characters', 'upload_photos',
        'delete_photos', 'comment_scenes', 'manage_general_breakdown',
        'edit_department_breakdown', 'manage_recycle_bin', 'publish_notifications',
      ];
      for (final p in escritura) {
        expect(hasPermission(Roles.usuario, p), isFalse, reason: p);
      }
    });

    // Valores límite del catálogo de roles (1001..1005): se deniega por defecto.
    test('un rol fuera de 1001..1005 o nulo no tiene permisos', () {
      for (final rol in [0, 1000, 1006, -1, null]) {
        expect(hasPermission(rol, 'full_management'), isFalse, reason: '$rol');
      }
    });

    test('un permiso inexistente se deniega', () {
      expect(hasPermission(Roles.administrador, 'volar'), isFalse);
    });
  });

  group('Roles.label', () {
    test('devuelve la etiqueta de cada rol', () {
      expect(Roles.label(1001), 'Administrador');
      expect(Roles.label(1002), 'Director');
      expect(Roles.label(1003), 'Jefe de Departamento');
      expect(Roles.label(1004), 'Onset');
      expect(Roles.label(1005), 'Usuario');
    });

    test('rol desconocido o nulo se muestra como "Sin rol"', () {
      expect(Roles.label(null), 'Sin rol');
      expect(Roles.label(999), 'Sin rol');
    });
  });
}
