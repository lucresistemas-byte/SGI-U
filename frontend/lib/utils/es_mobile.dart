import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';

/// `true` cuando el ancho disponible es de móvil. Punto de corte único en
/// [AppBreakpoints.corteMovil] (900).
bool esMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < AppBreakpoints.corteMovil;
}
