-- Pedido explícito del usuario (2026-09-03): poder crear un actor solo
-- con nombre/apellido y subir sus 2 fotos de inmediato, completando el
-- resto de la ficha técnica (medidas, físico, nacionalidad, fecha de
-- nacimiento) después. Antes estas columnas eran NOT NULL, así que
-- había que llenar la ficha entera antes de poder guardar el actor y
-- obtener el id_actor que necesitan las fotos.
ALTER TABLE actors
    ALTER COLUMN genero DROP NOT NULL,
    ALTER COLUMN fecha_de_nacimiento DROP NOT NULL,
    ALTER COLUMN talla_zapatos DROP NOT NULL,
    ALTER COLUMN ancho_espalda DROP NOT NULL,
    ALTER COLUMN pecho DROP NOT NULL,
    ALTER COLUMN cintura DROP NOT NULL,
    ALTER COLUMN cadera DROP NOT NULL,
    ALTER COLUMN largo_manga DROP NOT NULL,
    ALTER COLUMN largo_pierna DROP NOT NULL,
    ALTER COLUMN color_cabello DROP NOT NULL,
    ALTER COLUMN textura_cabello DROP NOT NULL,
    ALTER COLUMN tipo_piel DROP NOT NULL,
    ALTER COLUMN color_ojos DROP NOT NULL,
    ALTER COLUMN nacionalidad DROP NOT NULL,
    ALTER COLUMN doble_riesgo DROP NOT NULL;
