import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/models/categoria.dart';
import 'package:sgi_u_frontend/models/configuracion_negocio.dart';
import 'package:sgi_u_frontend/screens/settings_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Corrección 3: Configuración muestra los tipos de producto (solo lectura) y
/// administra las categorías (crear, renombrar, desactivar/reactivar).
void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    when(() => api.getMetodosPago(incluirInactivos: true)).thenAnswer((_) async => const []);
    when(() => api.getConfiguracion()).thenAnswer((_) async => const ConfiguracionNegocio(nombre: 'Demo'));
    when(() => api.getCategorias(incluirInactivas: true)).thenAnswer((_) async => const [
          Categoria(id: 1, nombre: 'Tortas'),
          Categoria(id: 2, nombre: 'Viejas', activo: false),
        ]);
    when(() => api.crearCategoria(any())).thenAnswer((_) async => const Categoria(id: 3, nombre: 'Regalería'));
    when(() => api.actualizarCategoria(any(), any())).thenAnswer((_) async => const Categoria(id: 1, nombre: 'Tortas y tartas'));
    when(() => api.cambiarEstadoCategoria(any(), activo: any(named: 'activo')))
        .thenAnswer((_) async => const Categoria(id: 1, nombre: 'Tortas', activo: false));
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(apiService: api)));
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los 6 tipos de producto, sin acciones', (tester) async {
    await montar(tester);

    for (final codigo in ['ELABORADO', 'REVENTA', 'MATERIA_PRIMA', 'INSUMO', 'REVENTA_MATERIA_PRIMA', 'PAQUETE']) {
      expect(find.byKey(Key('tipo_info_$codigo')), findsOneWidget, reason: codigo);
    }
    expect(find.descendant(of: find.byKey(const Key('config_tipos_producto')), matching: find.byType(IconButton)),
        findsNothing);
  });

  testWidgets('lista categorías activas e inactivas', (tester) async {
    await montar(tester);

    expect(find.text('Tortas'), findsOneWidget);
    expect(find.text('Viejas'), findsOneWidget);
    expect(find.text('Inactiva'), findsOneWidget);
  });

  testWidgets('crear, renombrar y desactivar categorías', (tester) async {
    await montar(tester);

    await tocar(tester, find.byKey(const Key('categoria_nueva_btn')));
    await tester.enterText(find.byKey(const Key('categoria_nombre_input')), 'Regalería');
    await tocar(tester, find.text('Guardar').last);
    verify(() => api.crearCategoria('Regalería')).called(1);

    await tocar(tester, find.byKey(const Key('categoria_renombrar_1')));
    await tester.enterText(find.byKey(const Key('categoria_nombre_input')), 'Tortas y tartas');
    await tocar(tester, find.text('Guardar').last);
    verify(() => api.actualizarCategoria(1, 'Tortas y tartas')).called(1);

    await tocar(tester, find.byKey(const Key('categoria_estado_1')));
    verify(() => api.cambiarEstadoCategoria(1, activo: false)).called(1);
    await tocar(tester, find.byKey(const Key('categoria_estado_2')));
    verify(() => api.cambiarEstadoCategoria(2, activo: true)).called(1);
  });
}
