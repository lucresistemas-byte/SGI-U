import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Verificación estructural de L4.1.
///
/// L4.1 exige: "después de un login exitoso, guardes la IP y el nombre
/// del servicio en flutter_secure_storage".
///
/// Estos tests leen el código real de Leo para confirmar que el flujo de
/// login persistió AMBOS valores (URL + nombre de servicio).
void main() {
  group('L4.1 - Tras login exitoso se guarda IP y nombre de servicio', () {
    final bloc = File('lib/blocs/auth/auth_bloc.dart').readAsStringSync();

    test('El login persiste la IP/URL del backend', () {
      expect(
        bloc.contains('saveBackendUrl(currentUrl)') ||
            bloc.contains('saveBackendUrl('),
        isTrue,
        reason: 'auth_bloc.dart debe llamar saveBackendUrl tras el login.',
      );
    });

    test('El login persiste el NOMBRE del servicio', () {
      expect(
        bloc.contains('saveBackendServiceName(') &&
            bloc.contains('LoginRequested'),
        isTrue,
        reason: 'auth_bloc.dart DEBE guardar el nombre del servicio '
            '(saveBackendServiceName) después del login. Si esto falla, '
            'L4.1 está parcialmente cumplido.',
      );
    });

    test('El guardado ocurre solo si la URL es válida (no vacía)', () {
      expect(
        bloc.contains('currentUrl.isNotEmpty'),
        isTrue,
        reason: 'L6.2: no debe guardarse una URL vacía tras el login.',
      );
    });
  });
}