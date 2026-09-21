import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_bloc.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_event.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/main.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/repositories/auth_repository.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFinanzasApi extends Mock implements ApiService {}

class _FakePosApi implements PosApi {
  bool createSaleCalled = false;
  Map<String, dynamic>? saleData;

  @override
  Future<List<dynamic>> getProducts() async => [
        {
          'codigo': 'P1',
          'nombre': 'Café',
          'precioUnitario': 150.0,
          'stockActual': 10,
          'activo': true,
        },
        {
          'codigo': 'P2',
          'nombre': 'Agua',
          'precioUnitario': 50.0,
          'stockActual': 20,
          'activo': true,
        },
      ];

  @override
  Future<void> createSale(Map<String, dynamic> saleData) async {
    createSaleCalled = true;
    this.saleData = saleData;
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProduct(
      String codigo, Map<String, dynamic> productData) async {
    throw UnimplementedError();
  }

  @override
  Future<Product> ajustarStock(String codigo,
      {required int cantidad, required String motivo}) async {
    throw UnimplementedError();
  }
}

/// Storage en memoria para no depender de flutter_secure_storage (determinista).
class MemoryStorage implements StorageService {
  String? token;
  String? backendUrl;
  String? serviceName;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> getBackendUrl() async =>
      (backendUrl != null && backendUrl!.isNotEmpty) ? backendUrl : null;

  @override
  Future<void> saveBackendUrl(String? url) async {
    final t = url?.trim();
    if (t == null || t.isEmpty) return;
    backendUrl = t;
  }

  @override
  Future<String?> getBackendServiceName() async =>
      (serviceName != null && serviceName!.isNotEmpty) ? serviceName : null;

  @override
  Future<void> saveBackendServiceName(String? value) async {
    final t = value?.trim();
    if (t == null || t.isEmpty) {
      serviceName = null;
    } else {
      serviceName = t;
    }
  }

  @override
  Future<void> clearBackendData() async {
    backendUrl = null;
    serviceName = null;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget app({
    required MockAuthRepository authRepo,
    required StorageService storage,
    required PosApi posApi,
    required ApiService finanzasApi,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            authRepository: authRepo,
            storageService: storage,
          )..add(CheckAuthStatus()),
        ),
        BlocProvider(create: (_) => PosBloc(apiService: posApi)),
        BlocProvider(create: (_) => FinanzasBloc(apiService: finanzasApi)),
      ],
      child: MaterialApp(
        title: 'SGI-U',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFF13894E)),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'AR'), Locale('es')],
        home: const StartupDecider(),
      ),
    );
  }

  testWidgets('flujo completo: login -> catálogo -> POS -> venta -> balance',
      (WidgetTester tester) async {
    // Desktop layout (menú lateral visible) independiente del dispositivo.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepo = MockAuthRepository();
    when(() => authRepo.login('admin', 'admin123'))
        .thenAnswer((_) async => {'token': 'token-de-test'});
    when(() => authRepo.baseUrl).thenReturn('http://localhost:3000');

    final finanzasApi = MockFinanzasApi();
    when(() => finanzasApi.getBalance(any(), any())).thenAnswer((_) async => {
          'totalIngresos': 12000.0,
          'totalEgresos': 2000.0,
          'margenNeto': 10000.0,
        });

    final posApi = _FakePosApi();
    final storage = MemoryStorage();

    await tester.pumpWidget(app(
      authRepo: authRepo,
      storage: storage,
      posApi: posApi,
      finanzasApi: finanzasApi,
    ));
    await tester.pumpAndSettle();

    // Paso 1: sin token -> LoginScreen.
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Paso 2: credenciales válidas -> CatalogoScreen.
    await tester.enterText(find.widgetWithText(TextField, 'Usuario'), 'admin');
    await tester.enterText(
        find.widgetWithText(TextField, 'Contraseña'), 'admin123');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Productos'), findsWidgets);
    expect(find.text('Café'), findsOneWidget);
    verify(() => authRepo.login('admin', 'admin123')).called(1);

    // Paso 3: navegación al POS desde el menú lateral.
    await tester.tap(find.text('Punto de Venta'));
    await tester.pumpAndSettle();
    expect(find.text('CONFIRMAR COBRO'), findsOneWidget);

    // Paso 4: agregar producto (tap en la card) y sumar cantidad (+).
    await tester.tap(find.text('Café').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.text('No hay productos agregados'), findsNothing);

    // Paso 5: método de pago y confirmación de venta.
    await tester.tap(find.text('Mercado Pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR COBRO'));
    await tester.pumpAndSettle();

    expect(find.text('Éxito'), findsOneWidget);
    expect(find.text('Venta registrada correctamente'), findsOneWidget);
    expect(posApi.createSaleCalled, isTrue);

    // Paso 6: cerrar el diálogo -> carrito vacío.
    await tester.tap(find.text('Nueva venta'));
    await tester.pumpAndSettle();
    expect(find.text('No hay productos agregados'), findsOneWidget);

    // Paso 7: navegación a Balance y verificación de los KPIs.
    await tester.tap(find.text('Balance'));
    await tester.pumpAndSettle();
    expect(find.text('Total de Ingresos'), findsOneWidget);
    expect(find.text('Total de Egresos'), findsOneWidget);
    expect(find.text('Detalle de Movimientos'), findsOneWidget);
  });
}