# Catálogos del módulo de Notificaciones — se validan como texto libre
# en los Form(...) de la ruta de creación (multipart no permite un
# Literal de Pydantic ahí directo, mismo criterio que TIPOS_FOTO en
# gallery_photo_schema.py), quedan acá documentados como referencia
# para el frontend y para la validación manual del controller.
ALCANCES = ["general", "especifica"]
ORIGENES = ["manual", "plan_rodaje"]
