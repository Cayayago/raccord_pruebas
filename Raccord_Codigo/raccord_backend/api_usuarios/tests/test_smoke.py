import pytest


# Importar app.main ejecuta Base.metadata.create_all() y se conecta a
# PostgreSQL: en el CI (sin BD) este test fallaba. Es una prueba de
# integración, no unitaria — misma solución que propone la receta de CI
# del bootcamp para el "contextLoads" de Spring Boot.
@pytest.mark.skip(reason="Requiere BD: se habilita en la semana 6 (integración con Docker)")
def test_app_importa():
    # Arrange / Act
    from app import main
    # Assert
    assert main.app is not None
