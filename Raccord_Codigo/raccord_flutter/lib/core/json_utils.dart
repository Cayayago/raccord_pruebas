/// Helpers para leer JSON de forma tolerante. La API está en evolución
/// activa y no todos los endpoints documentan un response_model
/// explícito, así que los parsers de los modelos son defensivos:
/// prueban varias llaves posibles y nunca truenan por un campo nulo.
dynamic pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

String? asString(dynamic v) => v?.toString();

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool? asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}

List<Map<String, dynamic>> asListOfMap(dynamic data) {
  if (data is List) {
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
}
