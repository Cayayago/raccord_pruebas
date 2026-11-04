"""
RNF-008 / RNF-009 — pruebas de carga (solo librería estándar de Python,
no hay que instalar nada). Alternativa ligera a Apache JMeter: mismas
métricas (promedio, p95) con el mismo escenario del requisito.

PREPARACIÓN (una vez): cargar 15.000 fotos de prueba con seed_fotos.py y
aplicar sql/031_busqueda_fotos_indices.sql (ver README.md de esta carpeta).

RNF-008 — búsqueda: 20 usuarios simultáneos, 5 filtros combinados,
          p95 < 10 s y promedio < 5 s.
  python tools/carga/prueba_carga.py --mail TU_CORREO --password TU_CLAVE \\
         --project ID_PROYECTO buscar --usuarios 20 --minutos 30

RNF-009 — volumen diario: sube N fotos de 2-6 MB y mide que el tiempo de
          subida se mantenga estable (primera mitad vs segunda mitad).
  python tools/carga/prueba_carga.py --mail TU_CORREO --password TU_CLAVE \\
         --project ID_PROYECTO subir --cantidad 100 --escena ID_ESCENA

Las fotos subidas llevan la descripción "[carga-test]" para que puedas
encontrarlas y borrarlas de la Galería/Papelera.
"""
import argparse
import json
import os
import random
import statistics
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

TIPOS = ["Locación", "Propuesta", "Prueba", "En Rodaje"]
PERSONAJES = [f"P{n:03d}" for n in range(1, 41)]
PALABRAS = ["vestuario", "maquillaje", "peinado", "utilería", "set", "locación",
            "chaqueta", "sombrero", "herida", "sangre", "polvo", "lluvia"]


def _request(method, url, token=None, body=None, headers=None, timeout=60):
    h = {"Accept": "application/json"}
    if token:
        h["Authorization"] = f"Bearer {token}"
    if headers:
        h.update(headers)
    req = urllib.request.Request(url, data=body, method=method, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as e:
        return e.code, {}
    except Exception:
        return 0, {}


def login(api, mail, password):
    body = json.dumps({"mail": mail, "contrasena": password}).encode()
    status, data = _request("POST", f"{api}/users/login", body=body,
                            headers={"Content-Type": "application/json"})
    token = (data.get("data") or {}).get("access_token")
    if not token:
        raise SystemExit(f"No se pudo iniciar sesión (HTTP {status}): {data.get('message')}")
    return token


def percentil(valores, p):
    if not valores:
        return 0.0
    v = sorted(valores)
    k = max(0, min(len(v) - 1, int(round(p / 100 * len(v) + 0.5)) - 1))
    return v[k]


def resumen(nombre, tiempos, errores, limite_p95=None, limite_prom=None):
    print(f"\n===== {nombre} =====")
    print(f"Peticiones correctas: {len(tiempos)} | errores: {errores}")
    if not tiempos:
        print("Sin datos.")
        return False
    prom = statistics.mean(tiempos)
    p95 = percentil(tiempos, 95)
    print(f"Promedio: {prom:.3f} s | mediana: {percentil(tiempos, 50):.3f} s | "
          f"p95: {p95:.3f} s | p99: {percentil(tiempos, 99):.3f} s | máx: {max(tiempos):.3f} s")
    ok = errores == 0
    if limite_p95 is not None:
        ok = ok and p95 < limite_p95
        print(f"p95 < {limite_p95} s ........ {'CUMPLE' if p95 < limite_p95 else 'NO CUMPLE'}")
    if limite_prom is not None:
        ok = ok and prom < limite_prom
        print(f"promedio < {limite_prom} s .... {'CUMPLE' if prom < limite_prom else 'NO CUMPLE'}")
    print(f"errores = 0 .............. {'CUMPLE' if errores == 0 else 'NO CUMPLE'}")
    return ok


# ---------------------------------------------------------------- búsqueda
def buscar(args, token):
    tiempos, errores = [], [0]
    lock = threading.Lock()
    fin = time.time() + args.minutos * 60

    def usuario():
        while time.time() < fin:
            hoy = time.time()
            desde = time.strftime("%Y-%m-%d", time.gmtime(hoy - 90 * 86400))
            hasta = time.strftime("%Y-%m-%d", time.gmtime(hoy))
            params = {
                "q": random.choice(PALABRAS),                 # filtro 1
                "tipo_foto": random.choice(TIPOS),             # filtro 2
                "personaje_codigo": random.choice(PERSONAJES), # filtro 3
                "desde": desde,                                # filtro 4
                "hasta": hasta,                                # filtro 5
                "page": random.randint(1, 3),
                "page_size": 50,
            }
            url = f"{args.api}/fotos/project/{args.project}/buscar?{urllib.parse.urlencode(params)}"
            t0 = time.perf_counter()
            status, _ = _request("GET", url, token=token, timeout=60)
            dt = time.perf_counter() - t0
            with lock:
                if status == 200:
                    tiempos.append(dt)
                else:
                    errores[0] += 1
            time.sleep(random.uniform(0.3, 1.0))  # "tiempo de lectura" del usuario

    print(f"Buscando con {args.usuarios} usuarios simultáneos durante {args.minutos} min...")
    hilos = [threading.Thread(target=usuario, daemon=True) for _ in range(args.usuarios)]
    for h in hilos:
        h.start()
    for h in hilos:
        h.join()
    ok = resumen("RNF-008 Búsqueda de fotografías", tiempos, errores[0], limite_p95=10, limite_prom=5)
    raise SystemExit(0 if ok else 1)


# ------------------------------------------------------------------ subida
def _multipart(campos, nombre_archivo, contenido, tipo):
    limite = uuid.uuid4().hex
    partes = []
    for k, v in campos.items():
        partes.append(f'--{limite}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
    partes.append(
        (f'--{limite}\r\nContent-Disposition: form-data; name="file"; filename="{nombre_archivo}"\r\n'
         f'Content-Type: {tipo}\r\n\r\n').encode() + contenido + b"\r\n")
    partes.append(f"--{limite}--\r\n".encode())
    return b"".join(partes), f"multipart/form-data; boundary={limite}"


def subir(args, token):
    tiempos, errores, ids = [], 0, []
    print(f"Subiendo {args.cantidad} fotos de 2-6 MB a la escena {args.escena}...")
    for i in range(args.cantidad):
        contenido = os.urandom(random.randint(2, 6) * 1024 * 1024)
        body, ctype = _multipart(
            {"tipo_foto": random.choice(TIPOS), "descripcion": "[carga-test]"},
            f"carga_{i:04d}.jpg", contenido, "image/jpeg")
        t0 = time.perf_counter()
        status, data = _request("POST", f"{args.api}/scenes/{args.escena}/fotos", token=token,
                                body=body, headers={"Content-Type": ctype}, timeout=120)
        dt = time.perf_counter() - t0
        if status == 200 and (data or {}).get("success", True):
            tiempos.append(dt)
            id_foto = (data.get("data") or {}).get("id_foto")
            if id_foto:
                ids.append(id_foto)
        else:
            errores += 1
        if (i + 1) % 10 == 0:
            print(f"  {i + 1}/{args.cantidad}")

    ok = resumen("RNF-009 Subida de fotografías", tiempos, errores)
    if len(tiempos) >= 10:
        mitad = len(tiempos) // 2
        a, b = statistics.mean(tiempos[:mitad]), statistics.mean(tiempos[mitad:])
        estable = b <= a * 1.5
        print(f"Tiempo medio 1ª mitad: {a:.3f} s | 2ª mitad: {b:.3f} s "
              f"-> {'ESTABLE' if estable else 'SE DEGRADA'}")
        ok = ok and estable

    # Búsqueda tras la acumulación (la otra mitad de RNF-009).
    t0 = time.perf_counter()
    status, _ = _request("GET", f"{args.api}/fotos/project/{args.project}/buscar?page_size=50", token=token)
    print(f"Búsqueda tras la carga: HTTP {status} en {time.perf_counter() - t0:.3f} s")
    raise SystemExit(0 if ok else 1)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--api", default="http://127.0.0.1:8000")
    p.add_argument("--mail", required=True)
    p.add_argument("--password", required=True)
    p.add_argument("--project", required=True, help="id del proyecto")
    sub = p.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("buscar")
    b.add_argument("--usuarios", type=int, default=20)
    b.add_argument("--minutos", type=float, default=30)

    s = sub.add_parser("subir")
    s.add_argument("--cantidad", type=int, default=100)
    s.add_argument("--escena", required=True, help="id de una escena del proyecto")

    args = p.parse_args()
    token = login(args.api, args.mail, args.password)
    (buscar if args.cmd == "buscar" else subir)(args, token)


if __name__ == "__main__":
    main()
