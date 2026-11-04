"""
RNF-008 / RNF-009 — carga datos de prueba: N fotos (por defecto 15.000)
dentro de un proyecto que YA tenga al menos una escena.

Las filas son solo metadatos (no suben archivos a MinIO): sirven para
medir la búsqueda. Todas llevan archivo_key que empieza por "seed/", así
que se pueden borrar sin tocar tus fotos reales.

Se ejecuta DENTRO del contenedor del backend (ya tiene la conexión a la BD):

  # ver los proyectos disponibles
  docker compose exec -T backend python - listar < tools/carga/seed_fotos.py

  # insertar 15.000 fotos de prueba en un proyecto
  docker compose exec -T backend python - <ID_PROYECTO> 15000 < tools/carga/seed_fotos.py

  # borrar SOLO las fotos de prueba
  docker compose exec -T backend python - limpiar < tools/carga/seed_fotos.py

(En PowerShell, "< archivo" no existe: usa
 Get-Content tools/carga/seed_fotos.py | docker compose exec -T backend python - listar )
"""
import random
import sys
import uuid
from datetime import datetime, timedelta

from sqlalchemy import text

from app.config.database import SessionLocal

TIPOS = ["Locación", "Propuesta", "Prueba", "En Rodaje"]
PERSONAJES = [f"P{n:03d}" for n in range(1, 41)]
PALABRAS = ["vestuario", "maquillaje", "peinado", "utilería", "set", "locación",
            "chaqueta", "sombrero", "herida", "sangre", "polvo", "lluvia",
            "noche", "amanecer", "cocina", "bosque", "calle", "oficina"]


def main():
    args = sys.argv[1:] or ["listar"]
    db = SessionLocal()
    try:
        if args[0] == "listar":
            rows = db.execute(text(
                "SELECT p.id_project, p.project_name, "
                "(SELECT count(*) FROM guiones g JOIN escenas e ON e.id_guion = g.id_guion "
                " WHERE g.id_project = p.id_project) AS escenas "
                "FROM projects p ORDER BY p.project_name"
            )).fetchall()
            for r in rows:
                print(f"{r[0]}  {r[1]}  (escenas: {r[2]})")
            return

        if args[0] == "limpiar":
            res = db.execute(text("DELETE FROM fotos_continuidad WHERE archivo_key LIKE 'seed/%'"))
            db.commit()
            print(f"Fotos de prueba borradas: {res.rowcount}")
            return

        id_project = args[0]
        total = int(args[1]) if len(args) > 1 else 15000

        escenas = [r[0] for r in db.execute(text(
            "SELECT e.id_escena FROM escenas e JOIN guiones g ON g.id_guion = e.id_guion "
            "WHERE g.id_project = :p"), {"p": id_project}).fetchall()]
        if not escenas:
            print("Ese proyecto no tiene escenas. Crea o segmenta un guion primero.")
            return

        ahora = datetime.utcnow()
        lote = []
        for i in range(total):
            palabras = " ".join(random.sample(PALABRAS, 3))
            lote.append({
                "id": str(uuid.uuid4()),
                "esc": random.choice(escenas),
                "tipo": random.choice(TIPOS),
                "pers": random.choice(PERSONAJES),
                "desc": f"Foto de prueba {i}: {palabras}",
                "nombre": f"seed_{i:06d}.jpg",
                "key": f"seed/{uuid.uuid4()}.jpg",
                "tam": random.randint(2_000_000, 6_000_000),
                "fecha": ahora - timedelta(minutes=random.randint(0, 60 * 24 * 90)),
            })
            if len(lote) == 1000 or i == total - 1:
                db.execute(text(
                    "INSERT INTO fotos_continuidad (id_foto, id_escena, tipo_foto, personaje_codigo, "
                    "descripcion, archivo_nombre, archivo_key, archivo_tipo, archivo_tamano, fecha_subida, eliminada) "
                    "VALUES (:id, :esc, :tipo, :pers, :desc, :nombre, :key, 'image/jpeg', :tam, :fecha, false)"
                ), lote)
                db.commit()
                print(f"  insertadas {i + 1}/{total}")
                lote = []
        db.execute(text("ANALYZE fotos_continuidad"))
        db.commit()
        print("Listo. Para borrarlas: python - limpiar")
    finally:
        db.close()


main()
