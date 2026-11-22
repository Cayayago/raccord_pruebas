// Capa Front — Conversión JSON <-> modelos (lib/models).
import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/models/gallery_photo.dart';
import 'package:raccord/models/module_access.dart';
import 'package:raccord/models/project.dart';
import 'package:raccord/models/scene.dart';
import 'package:raccord/models/user.dart';

// Valores del ENUM "momentodia" en PostgreSQL (sql/000_schema_completo.sql).
const momentoDiaEnBd = {'dia', 'noche', 'amanecer', 'atardecer', 'amanecer/dia', 'dia/noche'};

void main() {
  group('Scene', () {
    test('fromJson lee los campos y convierte tipos', () {
      // Arrange
      final json = {
        'id_escena': 'esc-1',
        'numero_de_escena': '12',
        'encabezado': 'INT. CASA - DÍA',
        'modo_vista': 'int',
        'momento_dia': 'dia',
        'pagina': '4', // llega como texto: igual se convierte
        'fecha_de_grabacion': '2026-11-20',
        'cast': [
          {'id_personaje': 'p1'},
          'basura',
        ],
      };

      // Act
      final escena = Scene.fromJson(json);

      // Assert
      expect(escena.numeroDeEscena, '12');
      expect(escena.pagina, 4);
      expect(escena.fechaDeGrabacion, DateTime(2026, 11, 20));
      expect(escena.estado, 'Pendiente'); // valor por defecto
      expect(escena.cast, [
        {'id_personaje': 'p1'},
      ]);
      expect(escena.modoYMomento, 'INT · dia');
    });

    test('fromJson no se rompe con un JSON vacío', () {
      final escena = Scene.fromJson({});

      expect(escena.numeroDeEscena, '');
      expect(escena.cast, isNull);
      expect(escena.modoYMomento, '');
    });

    test('toCreateJson omite campos vacíos y envía la fecha sin hora', () {
      final escena = Scene(
        numeroDeEscena: '1',
        encabezado: 'EXT. CALLE - NOCHE',
        descripcion: '',
        fechaDeGrabacion: DateTime(2026, 3, 5, 18, 30),
      );

      final json = escena.toCreateJson();

      expect(json.containsKey('descripcion'), isFalse);
      expect(json['fecha_de_grabacion'], '2026-03-05');
      expect(json['estado'], 'Pendiente');
    });

    test('labelMomento e iconoMomento toleran valores desconocidos', () {
      expect(labelMomento('noche'), 'Noche');
      expect(labelMomento(null), '?');
      expect(labelMomento('dia/noche'), 'dia/noche');
      expect(iconoMomento('dia'), '☀️');
      expect(iconoMomento(null), '');
    });

    test(
      'todo momento del día que ofrece la app existe en la base de datos',
      () {
        expect(kMomentosDia.toSet().difference(momentoDiaEnBd), isEmpty);
      },
      // HALLAZGO (semana 2): la app ofrece "anochecer", pero el ENUM momentodia
      // de PostgreSQL no lo tiene: guardar una escena con ese valor da un 500.
      // Quitar el "skip" cuando se corrija el catálogo.
      skip: 'HALLAZGO: "anochecer" no existe en el ENUM momentodia de la BD',
    );
  });

  group('GalleryPhoto', () {
    test('collageCountFor saca el número de fotos del modo de subida', () {
      expect(collageCountFor('Individual'), isNull);
      expect(collageCountFor('Collage 2'), 2);
      expect(collageCountFor('Collage 4'), 4);
    });

    test('fromJson usa "Propuesta" si no viene tipo de foto', () {
      final foto = GalleryPhoto.fromJson({'id_foto': 'f-1', 'id_escena': 'e-1'});

      expect(foto.tipoFoto, 'Propuesta');
      expect(foto.eliminada, isFalse);
    });
  });

  group('Project', () {
    test('resumen une formato, género y director sin separadores sobrantes', () {
      final p = Project(idProject: 'p', projectName: 'Raccord', formatoDeProduccion: 'Serie', genero: 'Drama', idClient: 'c', director: 'Ana');

      expect(p.resumen, 'Serie · Drama · Dir. Ana');
    });

    test('resumen omite el director vacío', () {
      final p = Project(idProject: 'p', projectName: 'R', formatoDeProduccion: 'Serie', genero: '', idClient: 'c', director: '');

      expect(p.resumen, 'Serie');
    });

    test('withIdRol conserva los datos y cambia solo el rol', () {
      final p = Project.fromJson({'id_project': 'p1', 'project_name': 'Raccord', 'formato_de_produccion': 'Serie', 'genero': 'Drama', 'id_client': 'c1'});

      final conRol = p.withIdRol(1004);

      expect(conRol.idRol, 1004);
      expect(conRol.projectName, 'Raccord');
      expect(p.idRol, isNull); // el original no cambia
    });
  });

  group('Usuarios', () {
    test('SessionUser ida y vuelta por JSON conserva los datos', () {
      final json = {'id_user': 'u1', 'nombre': 'Ana', 'apellido': 'Ruiz', 'mail': 'ana@b.co', 'id_rol': 1004, 'id_client': 'c1', 'id_departamento': null};

      final user = SessionUser.fromJson(json);

      expect(user.toJson(), json);
      expect(user.nombreCompleto, 'Ana Ruiz');
    });

    test('nombreCompleto no deja espacios si falta el apellido', () {
      expect(AppUser.fromJson({'nombre': 'Ana'}).nombreCompleto, 'Ana');
    });
  });

  group('ModuleAccess', () {
    test('fromJson usa "sin_acceso" por defecto (lo más restrictivo)', () {
      final acceso = ModuleAccessModel.fromJson({'modulo': 'galeria'});

      expect(acceso.nivelEfectivo, 'sin_acceso');
      expect(acceso.esExcepcion, isFalse);
    });

    test('los niveles están ordenados de menor a mayor', () {
      final orden = ['sin_acceso', 'ver', 'comentar', 'editar', 'administrar'];

      for (var i = 1; i < orden.length; i++) {
        expect(ModuloAccesos.nivelRango[orden[i]]! > ModuloAccesos.nivelRango[orden[i - 1]]!, isTrue);
      }
    });

    test('las etiquetas tienen respaldo para valores desconocidos', () {
      expect(ModuloAccesos.labelModulo('galeria'), 'Galería');
      expect(ModuloAccesos.labelModulo('otro'), 'otro');
      expect(ModuloAccesos.labelNivel('ver'), 'Ver');
    });
  });
}
