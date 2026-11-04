"""
Backfill de id_project para personajes, actors, personal_produccion,
plan_rodaje y desgloses.

CONTEXTO: estas 5 tablas nunca tuvieron ninguna relación con proyectos
(ver sql/015_project_scoping.sql, que agrega la columna id_project como
nullable). Este script corre DESPUÉS de esa migración y trata de
inferir, para cada fila EXISTENTE, a qué proyecto pertenece realmente,
usando las relaciones que sí existen en la base de datos:

  - Character (personajes): vía escenas_personajes -> escenas -> guiones
    -> id_project (los personajes que ya aparecen en el reparto de
    alguna escena).
  - Actor: vía su personaje asignado (id_personaje), una vez ese
    personaje ya quedó resuelto en el paso anterior.
  - ShootingDay (plan_rodaje): vía escenas.id_rodaje -> guiones ->
    id_project (los días que ya tienen escenas asignadas).
  - BreakdownSheet (desgloses): vía escenas.id_desglose -> guiones ->
    id_project, mismo criterio.
  - CrewMember (personal_produccion): no tiene NINGUNA relación
    indirecta con proyectos en el modelo de datos actual, así que no
    hay forma de inferirlo — queda siempre en la lista de huérfanos,
    salvo que se use --single-project-fallback (ver abajo).

CASOS AMBIGUOS: si una fila (ej. un personaje) aparece en escenas de
MÁS DE UN proyecto distinto, eso ya era un cruce de datos indebido
producido por el bug original — el script NO adivina cuál de los dos
proyectos es "el correcto": la deja sin asignar y la reporta, para que
se revise a mano.

USO:
    python scripts/backfill_project_scoping.py            # solo inferir y reportar
    python scripts/backfill_project_scoping.py --apply     # inferir Y guardar en la BD
    python scripts/backfill_project_scoping.py --apply --single-project-fallback
        # además, para las filas que sigan huérfanas después de inferir
        # (incluido TODO personal_produccion), si en la base de datos
        # existe un único proyecto, se les asigna ese proyecto. Pensado
        # solo para bases de datos de desarrollo/demo con un solo
        # proyecto — NO usar si hay más de un proyecto real, porque
        # asignaría datos de un cliente a otro sin ninguna base real.

Este script es de una sola vez (no se ejecuta en cada arranque, a
diferencia de Base.metadata.create_all en main.py) — se corre a mano
tras desplegar la migración 015.
"""
import argparse
import sys
from collections import defaultdict

from app.config.database import SessionLocal
from app.models.character_model import Character
from app.models.actor_model import Actor
from app.models.crew_member_model import CrewMember
from app.models.shooting_day_model import ShootingDay
from app.models.breakdown_sheet_model import BreakdownSheet
from app.models.scene_model import Scene
from app.models.scene_character_model import SceneCharacter
from app.models.script_model import Script
from app.models.project_model import Project


def _scene_project_map(db):
    """id_escena -> id_project, resuelto vía escenas.id_guion -> guiones.id_project."""
    rows = (
        db.query(Scene.id_escena, Script.id_project)
        .join(Script, Scene.id_guion == Script.id_guion)
        .all()
    )
    return {id_escena: id_project for id_escena, id_project in rows if id_project is not None}


def _infer_characters(db, scene_project):
    """personaje -> {proyectos en los que aparece su reparto}."""
    links = db.query(SceneCharacter.id_personaje, SceneCharacter.id_escena).all()
    por_personaje = defaultdict(set)
    for id_personaje, id_escena in links:
        proyecto = scene_project.get(id_escena)
        if proyecto is not None:
            por_personaje[id_personaje].add(proyecto)
    return por_personaje


def _infer_by_scene_fk(db, model, fk_column, scene_fk_name, scene_project):
    """Genérico para ShootingDay/BreakdownSheet: agrupa escenas por el
    FK que apunta a esta fila (id_rodaje / id_desglose) y calcula el
    conjunto de proyectos involucrados."""
    scenes = db.query(Scene.id_escena, scene_fk_name).all()
    por_fila = defaultdict(set)
    for id_escena, fk_value in scenes:
        if fk_value is None:
            continue
        proyecto = scene_project.get(id_escena)
        if proyecto is not None:
            por_fila[fk_value].add(proyecto)
    return por_fila


def run(apply: bool, single_project_fallback: bool):
    db = SessionLocal()
    reporte = {
        "personajes_inferidos": 0,
        "personajes_ambiguos": [],
        "personajes_huerfanos": 0,
        "actors_inferidos": 0,
        "actors_huerfanos": 0,
        "plan_rodaje_inferidos": 0,
        "plan_rodaje_ambiguos": [],
        "plan_rodaje_huerfanos": 0,
        "desgloses_inferidos": 0,
        "desgloses_ambiguos": [],
        "desgloses_huerfanos": 0,
        "crew_huerfanos": 0,
    }

    try:
        scene_project = _scene_project_map(db)

        # ---------- PERSONAJES ----------
        por_personaje = _infer_characters(db, scene_project)
        personajes = db.query(Character).filter(Character.id_project.is_(None)).all()
        for personaje in personajes:
            proyectos = por_personaje.get(personaje.id_personaje, set())
            if len(proyectos) == 1:
                proyecto_unico = next(iter(proyectos))
                if apply:
                    personaje.id_project = proyecto_unico
                reporte["personajes_inferidos"] += 1
            elif len(proyectos) > 1:
                reporte["personajes_ambiguos"].append(str(personaje.id_personaje))
            else:
                reporte["personajes_huerfanos"] += 1

        if apply:
            db.flush()  # para que los actores ya vean el id_project recién asignado

        # ---------- ACTORS ----------
        actors = db.query(Actor).filter(Actor.id_project.is_(None)).all()
        for actor in actors:
            proyecto = None
            if actor.id_personaje is not None:
                personaje = db.query(Character).filter(Character.id_personaje == actor.id_personaje).first()
                if personaje is not None:
                    proyecto = personaje.id_project
            if proyecto is not None:
                if apply:
                    actor.id_project = proyecto
                reporte["actors_inferidos"] += 1
            else:
                reporte["actors_huerfanos"] += 1

        # ---------- PLAN DE RODAJE ----------
        por_dia = _infer_by_scene_fk(db, ShootingDay, "id_rodaje", Scene.id_rodaje, scene_project)
        dias = db.query(ShootingDay).filter(ShootingDay.id_project.is_(None)).all()
        for dia in dias:
            proyectos = por_dia.get(dia.id_rodaje, set())
            if len(proyectos) == 1:
                if apply:
                    dia.id_project = next(iter(proyectos))
                reporte["plan_rodaje_inferidos"] += 1
            elif len(proyectos) > 1:
                reporte["plan_rodaje_ambiguos"].append(str(dia.id_rodaje))
            else:
                reporte["plan_rodaje_huerfanos"] += 1

        # ---------- DESGLOSES (hojas) ----------
        por_hoja = _infer_by_scene_fk(db, BreakdownSheet, "id_desglose", Scene.id_desglose, scene_project)
        hojas = db.query(BreakdownSheet).filter(BreakdownSheet.id_project.is_(None)).all()
        for hoja in hojas:
            proyectos = por_hoja.get(hoja.id_desglose, set())
            if len(proyectos) == 1:
                if apply:
                    hoja.id_project = next(iter(proyectos))
                reporte["desgloses_inferidos"] += 1
            elif len(proyectos) > 1:
                reporte["desgloses_ambiguos"].append(str(hoja.id_desglose))
            else:
                reporte["desgloses_huerfanos"] += 1

        # ---------- CREW (sin relación indirecta posible) ----------
        crew_huerfanos = db.query(CrewMember).filter(CrewMember.id_project.is_(None)).all()
        reporte["crew_huerfanos"] = len(crew_huerfanos)

        # ---------- FALLBACK: un solo proyecto en toda la BD ----------
        if single_project_fallback:
            total_proyectos = db.query(Project.id_project).count()
            if total_proyectos == 1:
                unico = db.query(Project.id_project).scalar()
                pendientes = (
                    db.query(Character).filter(Character.id_project.is_(None)).all()
                    + db.query(Actor).filter(Actor.id_project.is_(None)).all()
                    + db.query(CrewMember).filter(CrewMember.id_project.is_(None)).all()
                    + db.query(ShootingDay).filter(ShootingDay.id_project.is_(None)).all()
                    + db.query(BreakdownSheet).filter(BreakdownSheet.id_project.is_(None)).all()
                )
                for fila in pendientes:
                    if apply:
                        fila.id_project = unico
                reporte["fallback_asignados_a_unico_proyecto"] = len(pendientes)
            else:
                reporte["fallback_asignados_a_unico_proyecto"] = (
                    f"omitido: hay {total_proyectos} proyectos, no 1"
                )

        if apply:
            db.commit()
        else:
            db.rollback()

    finally:
        db.close()

    return reporte


def _print_reporte(reporte: dict, apply: bool):
    print("=" * 60)
    print("BACKFILL id_project" + (" (APLICADO)" if apply else " (SOLO SIMULACIÓN — usa --apply para guardar)"))
    print("=" * 60)
    for clave, valor in reporte.items():
        if isinstance(valor, list):
            if valor:
                print(f"{clave}: {len(valor)} -> {valor}")
            else:
                print(f"{clave}: 0")
        else:
            print(f"{clave}: {valor}")

    huerfanos_totales = (
        reporte.get("personajes_huerfanos", 0)
        + reporte.get("actors_huerfanos", 0)
        + reporte.get("plan_rodaje_huerfanos", 0)
        + reporte.get("desgloses_huerfanos", 0)
        + reporte.get("crew_huerfanos", 0)
    )
    if huerfanos_totales > 0:
        print()
        print(
            f"ATENCIÓN: {huerfanos_totales} fila(s) quedaron sin proyecto asignado "
            "(no se pudo inferir con seguridad). Mientras no se les asigne "
            "id_project a mano en la base de datos, NO aparecerán en ningún "
            "listado de la app (todas las consultas ahora filtran por "
            "proyecto) — no se pierden, quedan invisibles hasta asignarlas."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="Guardar los cambios en la base de datos (sin esto, solo simula y reporta).")
    parser.add_argument("--single-project-fallback", action="store_true", help="Si solo existe un proyecto en la BD, asignárselo a todo lo que siga huérfano después de inferir.")
    args = parser.parse_args()

    reporte = run(apply=args.apply, single_project_fallback=args.single_project_fallback)
    _print_reporte(reporte, apply=args.apply)

    if not args.apply:
        print()
        print("Nada se guardó todavía. Vuelve a correr con --apply cuando el reporte se vea bien.")
        sys.exit(0)
