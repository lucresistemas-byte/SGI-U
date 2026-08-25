import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/pos_bloc.dart';
import 'blocs/finanzas/finanzas_bloc.dart';
import 'screens/catalogo_screen.dart';
import 'screens/login_screen.dart';
import 'repositories/auth_repository.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/reconnection_service.dart';
import 'services/server_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L4.2 / C.3.4: inicializa la URL del backend (storage + reconexión mDNS)
  await initializeBackendUrl();

  runApp(const MyApp());
}

/// Inicializa la URL base del backend antes de arrancar la app (C.3.4/C.3.9).
/// - ServerStore cachea la última URL resuelta con timestamp y TTL de 24h.
/// - El candidato a reusar es la caché si está fresca; si no, la URL legacy
///   guardada en StorageService.
/// - Siempre se hace ping previo al candidato: si responde se usa directo;
///   si no, ReconnectionService descubre el backend vía mDNS.
/// - La URL resultante se aplica con setBaseUrl y refresca el TTL de la caché.
/// Los servicios son inyectables para poder mockearlos en tests.
Future<void> initializeBackendUrl({
  StorageService? storageService,
  ReconnectionService? reconnectionService,
  ApiService? apiService,
  ServerStore? serverStore,
}) async {
  final storage = storageService ?? StorageService();
  final reconnection =
      reconnectionService ?? ReconnectionService(storageService: storage);
  final api = apiService ?? ApiService();
  final store = serverStore ?? ServerStore();

  // C.3.9: el TTL decide contra quién se hace el ping, no lo evita.
  final cached = await store.read();
  final candidateUrl =
      (cached != null && store.isFresh(cached)) ? cached.url : null;
  final savedUrl =
      candidateUrl ?? await storage.getBackendUrl();
  final savedServiceName = await storage.getBackendServiceName();

  // Attempt reconnection (checks if URL is reachable, or discovers via mDNS)
  final urlToUse =
      await reconnection.attemptReconnection(savedUrl, savedServiceName);

  // Apply the resolved URL and refresh the cache timestamp
  if (urlToUse != null && urlToUse.isNotEmpty) {
    api.setBaseUrl(urlToUse);
    await store.save(urlToUse);
  }
  // If no URL is available, ApiService will use its default (localhost:3000)
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(authRepository: AuthRepository())
            ..add(CheckAuthStatus()),
        ),
        BlocProvider(create: (context) => PosBloc()),
        BlocProvider(create: (context) => FinanzasBloc()), // ← AGREGADO
      ],
      child: MaterialApp(
        title: 'SGI-U',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF13894E)),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'AR'),
          Locale('es'),
          Locale('en'),
        ],
        home: const StartupDecider(),
      ),
    );
  }
}

class StartupDecider extends StatelessWidget {
  const StartupDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return const CatalogoScreen();
        }
        if (authState is AuthInitial) {
          // Spinner solo durante el chequeo inicial del token guardado
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Unauthenticated, AuthLoading y AuthError muestran el formulario:
        // el botón de login maneja su propio spinner y los errores se
        // notifican mediante SnackBar dentro de LoginScreen.
        return const LoginScreen();
      },
    );
  }
}
