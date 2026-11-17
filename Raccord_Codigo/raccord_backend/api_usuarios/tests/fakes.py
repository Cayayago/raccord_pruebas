"""
Dobles de prueba mínimos para la sesión de SQLAlchemy.

Las reglas de negocio de los controladores y de app/utils solo hacen
consultas del tipo db.query(Modelo).filter(...).first() / .all() /
.scalar(). En pruebas UNITARIAS no queremos una BD real (eso es la
semana 6), así que este "fake" devuelve, por cada modelo (o columna)
consultado, el valor que el test le indique.

Limitación conocida (a propósito): el fake IGNORA los filtros. Si un
test necesita que el filtro importe, ese caso va en las pruebas de
integración contra PostgreSQL (semana 6).
"""


class FakeQuery:
    def __init__(self, result):
        self._result = result

    def filter(self, *args, **kwargs):
        return self

    def order_by(self, *args, **kwargs):
        return self

    def join(self, *args, **kwargs):
        return self

    def first(self):
        if isinstance(self._result, list):
            return self._result[0] if self._result else None
        return self._result

    def all(self):
        if self._result is None:
            return []
        return self._result if isinstance(self._result, list) else [self._result]

    def scalar(self):
        return self.first()

    def delete(self):
        return 0


class FakeSession:
    """results: dict {Modelo_o_columna: valor que devuelve la consulta}"""

    def __init__(self, results=None):
        self.results = results or {}
        self.added = []
        self.deleted = []
        self.commits = 0
        self.rollbacks = 0

    def query(self, *entities):
        valor = self.results.get(entities[0])
        if isinstance(valor, Seq):
            # Cada consulta a ese modelo devuelve el siguiente valor de la
            # secuencia (útil cuando el código busca DOS usuarios distintos).
            valor = valor.pop(0)
        return FakeQuery(valor)

    def add(self, obj):
        self.added.append(obj)

    def delete(self, obj):
        self.deleted.append(obj)

    def flush(self):
        # Simula lo que hace PostgreSQL/SQLAlchemy al insertar: asignar
        # los valores por defecto de la llave primaria (uuid4).
        import uuid
        for obj in self.added:
            for pk in ("id_foto", "id", "id_escena"):
                if hasattr(type(obj), pk) and getattr(obj, pk, None) is None:
                    setattr(obj, pk, uuid.uuid4())

    def commit(self):
        self.flush()
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1

    def refresh(self, obj):
        pass


class Seq(list):
    """Respuestas en orden para consultas repetidas al mismo modelo."""


class Obj:
    """Registro falso: Obj(id_rol=1004) se comporta como una fila con ese atributo."""

    def __init__(self, **attrs):
        self.__dict__.update(attrs)
