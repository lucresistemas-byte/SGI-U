import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/models/configuracion_negocio.dart';
import 'package:sgi_u_frontend/screens/settings_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService mockApiService;

  setUpAll(() {
    registerFallbackValue(const ConfiguracionNegocio());
  });

  setUp(() {
    mockApiService = MockApiService();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: SettingsScreen(apiService: mockApiService),
    );
  }

  group('SettingsScreen Widget Tests (Tarea 6.3)', () {
    testWidgets('Carga y muestra la configuración actual en los campos del formulario',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const configInicial = ConfiguracionNegocio(
        nombre: 'Almacén Don Carlos',
        codigoCliente: 'CLI-999',
        direccion: 'Calle San Martín 500',
        telefono: '11-5555-6666',
        descripcion: 'Venta de comestibles y bebidas',
      );

      when(() => mockApiService.getConfiguracion())
          .thenAnswer((_) async => configInicial);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verificar que los campos contienen los valores
      expect(find.text('Personalización del Negocio'), findsOneWidget);
      expect(find.text('Almacén Don Carlos'), findsOneWidget);
      expect(find.text('CLI-999'), findsOneWidget);
      expect(find.text('Calle San Martín 500'), findsOneWidget);
      expect(find.text('11-5555-6666'), findsOneWidget);
      expect(find.text('Venta de comestibles y bebidas'), findsOneWidget);
    });

    testWidgets('Modificar el nombre y guardar llama a saveConfiguracion y muestra SnackBar',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const configInicial = ConfiguracionNegocio(
        nombre: 'Negocio Original',
        codigoCliente: 'ORIG-1',
      );

      when(() => mockApiService.getConfiguracion())
          .thenAnswer((_) async => configInicial);
      when(() => mockApiService.saveConfiguracion(any()))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as ConfiguracionNegocio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Modificar el campo de nombre
      final nombreField = find.byKey(const Key('settings_nombre_field'));
      await tester.enterText(nombreField, 'Negocio Renombrado');
      await tester.pump();

      // Presionar botón guardar
      final guardarBtn = find.byKey(const Key('settings_guardar_btn'));
      await tester.tap(guardarBtn);
      await tester.pumpAndSettle();

      // Verificar llamada a saveConfiguracion
      final captured = verify(() => mockApiService.saveConfiguracion(captureAny())).captured;
      expect(captured.length, equals(1));
      final savedConfig = captured.first as ConfiguracionNegocio;
      expect(savedConfig.nombre, equals('Negocio Renombrado'));

      // Verificar SnackBar de éxito
      expect(find.text('Configuración guardada correctamente'), findsOneWidget);
    });

    testWidgets('Valida que el nombre no quede vacío al intentar guardar',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const configInicial = ConfiguracionNegocio(
        nombre: 'Negocio Existente',
      );

      when(() => mockApiService.getConfiguracion())
          .thenAnswer((_) async => configInicial);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Vaciar el campo nombre
      final nombreField = find.byKey(const Key('settings_nombre_field'));
      await tester.enterText(nombreField, '');
      await tester.pump();

      // Presionar guardar
      final guardarBtn = find.byKey(const Key('settings_guardar_btn'));
      await tester.tap(guardarBtn);
      await tester.pumpAndSettle();

      // Verificar mensaje de validación
      expect(find.text('El nombre del negocio es obligatorio'), findsOneWidget);
      verifyNever(() => mockApiService.saveConfiguracion(any()));
    });
  });
}
