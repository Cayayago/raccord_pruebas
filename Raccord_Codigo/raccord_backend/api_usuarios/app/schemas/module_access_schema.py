from pydantic import BaseModel, field_validator

from app.utils.module_access import NIVEL_RANGO


# ==========================================
# ACCESOS PERSONALIZADOS POR MÓDULO
# ==========================================
# Body de PUT /projects/{id_project}/users/{id_user}/module-access/{modulo}
# — ver contexto completo en app/utils/module_access.py.
class ModuleAccessSetSchema(BaseModel):
    nivel: str

    @field_validator("nivel")
    @classmethod
    def nivel_valido(cls, v: str) -> str:
        if v not in NIVEL_RANGO:
            opciones = ", ".join(NIVEL_RANGO.keys())
            raise ValueError(f"Nivel inválido. Debe ser uno de: {opciones}")
        return v
