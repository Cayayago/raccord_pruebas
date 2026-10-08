def test_app_importa():
    # Arrange / Act
    from app import main
    # Assert
    assert main.app is not None
