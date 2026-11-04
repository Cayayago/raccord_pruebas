/// Catálogo de tipos de documento — fuente única para Registro y Perfil,
/// así ambas pantallas siempre muestran las mismas opciones con el mismo
/// texto. Al backend solo se envía la abreviatura (CC, TI, NIT, CE, PA);
/// el nombre completo es solo para mostrarlo junto a la abreviatura en
/// el desplegable.
const kTiposDocumento = ['CC', 'TI', 'NIT', 'CE', 'PA'];

const _kNombresTiposDocumento = {
  'CC': 'Cédula de Ciudadanía',
  'TI': 'Tarjeta de Identidad',
  'NIT': 'Registro único tributario',
  'CE': 'Cédula de Extranjería',
  'PA': 'Pasaporte',
};

/// "CC - Cédula de Ciudadanía", etc. — para usar como texto del ítem en
/// el desplegable. El `value` que se guarda/envía sigue siendo solo la
/// abreviatura (ver `AppDropdown<String>` en registro/perfil).
String tipoDocumentoLabel(String abreviatura) {
  final nombre = _kNombresTiposDocumento[abreviatura];
  return nombre != null ? '$abreviatura - $nombre' : abreviatura;
}
