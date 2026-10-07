from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.gallery_photo_controller import (
    get_photos_by_scene,
    get_all_photos,
    get_papelera,
    upload_photo,
    get_photo_archivo,
    update_photo,
    delete_photo,
    restore_photo,
    delete_photo_permanent,
)
from app.models.scene_model import Scene
from app.models.gallery_photo_model import GalleryPhoto
from app.schemas.gallery_photo_schema import GalleryPhotoUpdateSchema

# 🔐 autenticación / permisos — resueltos por proyecto, ver
# app/utils/project_scope.py. GalleryPhoto/Scene no tienen columna
# id_project propia: se resuelve subiendo por id_escena -> id_guion ->
# guiones.id_project.
from app.utils.project_scope import (
    require_project_member,
    require_project_permission,
    require_record_project_permission,
    resolve_project_of_scene,
    resolve_project_via_scene_fk,
)
from app.utils.module_access import check_module_view_access

router = APIRouter()


# Ver las fotos de continuidad de una escena: cualquier miembro del
# proyecto de esa escena.
@router.get("/scenes/{id_escena}/fotos")
def photos_by_scene(
    id_escena: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Scene, pk_column="id_escena", pk_path_param="id_escena",
        resolve_project=resolve_project_of_scene, not_found_message="Escena no encontrada",
    )),
):
    return get_photos_by_scene(id_escena, db)


# Galería global de UN proyecto — antes /fotos sin filtro devolvía las
# fotos de TODOS los proyectos.
@router.get("/fotos/project/{id_project}")
def all_photos(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "galeria", current_user.get("id_rol"))
    return get_all_photos(id_project, db)


# Subir foto: permiso "upload_photos" (Administrador, Director, Jefe
# de Departamento y Onset lo tienen; Usuario no — ver
# app/utils/permissions.py) — resuelto dentro del proyecto de la
# escena a la que se sube la foto.
@router.post("/scenes/{id_escena}/fotos")
async def store_photo(
    id_escena: str,
    tipo_foto: str = Form("Set"),
    personaje_codigo: str | None = Form(None),
    descripcion: str | None = Form(None),
    notas_continuidad: str | None = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "upload_photos", model=Scene, pk_column="id_escena", pk_path_param="id_escena",
        resolve_project=resolve_project_of_scene, not_found_message="Escena no encontrada",
    )),
):
    return await upload_photo(id_escena, tipo_foto, personaje_codigo, descripcion, notas_continuidad, file, db)


# Ver/descargar el binario de la foto: cualquier miembro del proyecto
# dueño de la escena de esa foto.
@router.get("/fotos/{id_foto}/archivo")
def download_photo_file(
    id_foto: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=GalleryPhoto, pk_column="id_foto", pk_path_param="id_foto",
        resolve_project=resolve_project_via_scene_fk("id_escena"), not_found_message="Foto no encontrada",
    )),
):
    return get_photo_archivo(id_foto, db)


# Editar detalles de una foto ya subida (tipo, personaje, descripción,
# notas) — mismo permiso que subirla ("upload_photos"), resuelto contra
# el proyecto de la escena dueña de la foto. exclude_unset=True: solo
# se actualizan los campos que el visor Polaroid del frontend envió.
@router.patch("/fotos/{id_foto}")
def edit_photo(
    id_foto: str,
    data: GalleryPhotoUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "upload_photos", model=GalleryPhoto, pk_column="id_foto", pk_path_param="id_foto",
        resolve_project=resolve_project_via_scene_fk("id_escena"), not_found_message="Foto no encontrada",
    )),
):
    return update_photo(id_foto, data.dict(exclude_unset=True), db)


# Eliminar foto: permiso propio "delete_photos" (separado de
# "upload_photos" a pedido explícito). Desde 2026-09-23 esto es un
# soft-delete: manda la foto a la Papelera de Reciclaje en vez de
# borrarla para siempre — Onset, Jefe de Departamento y Director
# pueden hacerlo; el Administrador YA NO (puede ver fotos, pero no
# eliminarlas — ver app/utils/permissions.py).
@router.delete("/fotos/{id_foto}")
def destroy_photo(
    id_foto: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "delete_photos", model=GalleryPhoto, pk_column="id_foto", pk_path_param="id_foto",
        resolve_project=resolve_project_via_scene_fk("id_escena"), not_found_message="Foto no encontrada",
    )),
):
    return delete_photo(id_foto, db, current_user)


# Ver la Papelera de Reciclaje de un proyecto: permiso "view_recycle_bin"
# (Jefe de Departamento, Director y Administrador de solo lectura — el
# frontend oculta los botones de restaurar/eliminar definitivo para
# Administrador, ver "manage_recycle_bin").
@router.get("/fotos/papelera/{id_project}")
def papelera(
    id_project: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_project_permission("view_recycle_bin")),
):
    check_module_view_access(db, current_user, id_project, "galeria", current_user.get("id_rol"))
    return get_papelera(id_project, db)


# Restaurar una foto desde la Papelera: permiso "manage_recycle_bin"
# (SOLO Jefe de Departamento y Director).
@router.post("/fotos/{id_foto}/restaurar")
def restaurar_foto(
    id_foto: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "manage_recycle_bin", model=GalleryPhoto, pk_column="id_foto", pk_path_param="id_foto",
        resolve_project=resolve_project_via_scene_fk("id_escena"), not_found_message="Foto no encontrada",
    )),
):
    return restore_photo(id_foto, db)


# Eliminar DEFINITIVAMENTE una foto desde la Papelera: permiso
# "manage_recycle_bin" (SOLO Jefe de Departamento y Director) — este
# sí borra el binario en MinIO y la fila, sin vuelta atrás.
@router.delete("/fotos/{id_foto}/definitivo")
def eliminar_foto_definitivo(
    id_foto: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "manage_recycle_bin", model=GalleryPhoto, pk_column="id_foto", pk_path_param="id_foto",
        resolve_project=resolve_project_via_scene_fk("id_escena"), not_found_message="Foto no encontrada",
    )),
):
    return delete_photo_permanent(id_foto, db)
