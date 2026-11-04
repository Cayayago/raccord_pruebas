from datetime import datetime

from sqlalchemy.orm import Session

from app.models.revoked_token_model import RevokedToken


# ==========================================
# REVOCAR UN TOKEN (LOGOUT)
# ==========================================
# jti / exp vienen del propio payload del JWT que se está cerrando
# (ver login_controller.logout_user). Si por algún motivo el token no
# trajera jti (ej. token viejo emitido antes de este cambio, todavía
# no expirado), no hay nada que revocar puntualmente — seguirá
# funcionando hasta su "exp" natural, igual que antes de este cambio.
def revoke_token(db: Session, jti: str, exp_timestamp: int):
    if not jti or not exp_timestamp:
        return

    # Logout duplicado (doble click, dos pestañas cerrando sesión con
    # el mismo token) no debe romper nada.
    ya_revocado = db.query(RevokedToken).filter(RevokedToken.jti == jti).first()
    if ya_revocado:
        return

    db.add(RevokedToken(
        jti=jti,
        fecha_expira=datetime.utcfromtimestamp(exp_timestamp),
    ))
    db.commit()

    _limpiar_expirados(db)


# ==========================================
# ¿ESTE TOKEN FUE REVOCADO? (CHEQUEO EN CADA REQUEST)
# ==========================================
def is_token_revoked(db: Session, jti: str) -> bool:
    if not jti:
        return False
    return db.query(RevokedToken).filter(RevokedToken.jti == jti).first() is not None


# ==========================================
# AUTOLIMPIEZA
# ==========================================
# Se aprovecha cada logout para borrar filas cuya "fecha_expira" ya
# pasó: esos jti ya no servirían de todas formas (el propio jwt.decode
# los rechazaría por "exp" vencido), así que no hace falta seguir
# consultándolos ni ocupando espacio. Mantiene la tabla siempre chica
# sin necesitar un job/cron aparte.
def _limpiar_expirados(db: Session):
    db.query(RevokedToken).filter(RevokedToken.fecha_expira < datetime.utcnow()).delete()
    db.commit()
