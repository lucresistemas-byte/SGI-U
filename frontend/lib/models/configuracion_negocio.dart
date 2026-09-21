import 'dart:convert';
import 'dart:typed_data';

class ConfiguracionNegocio {
  final String nombre;
  final String? codigoCliente;
  final Uint8List? logo;
  final String? direccion;
  final String? telefono;
  final String? descripcion;

  const ConfiguracionNegocio({
    this.nombre = 'SGI-U',
    this.codigoCliente,
    this.logo,
    this.direccion,
    this.telefono,
    this.descripcion,
  });

  factory ConfiguracionNegocio.fromJson(Map<String, dynamic> json) {
    Uint8List? parsedLogo;
    final logoRaw = json['logo'];
    if (logoRaw is String && logoRaw.isNotEmpty) {
      try {
        parsedLogo = base64Decode(logoRaw);
      } catch (_) {
        parsedLogo = null;
      }
    } else if (logoRaw is List) {
      parsedLogo = Uint8List.fromList(List<int>.from(logoRaw));
    }

    return ConfiguracionNegocio(
      nombre: json['nombre']?.toString() ?? 'SGI-U',
      codigoCliente: json['codigoCliente']?.toString() ?? json['codigo_cliente']?.toString(),
      logo: parsedLogo,
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      descripcion: json['descripcion']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeNullLogo = false}) {
    final map = <String, dynamic>{
      'nombre': nombre,
    };
    if (codigoCliente != null) map['codigoCliente'] = codigoCliente;
    if (direccion != null) map['direccion'] = direccion;
    if (telefono != null) map['telefono'] = telefono;
    if (descripcion != null) map['descripcion'] = descripcion;
    if (logo != null) {
      map['logo'] = base64Encode(logo!);
    } else if (includeNullLogo) {
      map['logo'] = null;
    }
    return map;
  }

  ConfiguracionNegocio copyWith({
    String? nombre,
    String? codigoCliente,
    Uint8List? logo,
    String? direccion,
    String? telefono,
    String? descripcion,
    bool clearLogo = false,
  }) {
    return ConfiguracionNegocio(
      nombre: nombre ?? this.nombre,
      codigoCliente: codigoCliente ?? this.codigoCliente,
      logo: clearLogo ? null : (logo ?? this.logo),
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}
