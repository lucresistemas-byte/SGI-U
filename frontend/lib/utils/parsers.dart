/// Convierte un valor dinámico proveniente del backend (num, String o null)
/// en double de forma segura, aceptando coma como separador decimal.
double parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }
  return 0.0;
}

/// Convierte un valor dinámico proveniente del backend en String de forma
/// segura, devolviendo [fallback] cuando el valor es null.
String parseString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}
