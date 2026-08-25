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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L4.2 / C.3.4: inicializa la URL del backend (storage + reconexión mDNS)
  await initializeBackendUrl();

  runApp(const MyApp());
}

/// Inicializa la URL base del backend antes de arrancar la app.
/// - Lee la URL guardada y el nombre de servicio mDNS desde storage.
/// - Intenta reconexión: reusa la URL si responde; si no, descubre vía mDNS.
/// - Aplica la URL resultante a ApiService mediante setBaseUrl (C.3.4).
/// Los servicios son inyectables para poder mockearlos en tests.
Future<void> initializeBackendUrl({
  StorageService? storageService,
  ReconnectionService? reconnectionService,
  ApiService? apiService,
}) async {
  final storage = storageService ?? StorageService();
  final reconnection =
      reconnectionService ?? ReconnectionService(storageService: storage);
  final api = apiService ?? ApiService();

  // Read saved URL and service name
  final savedUrl = await storage.getBackendUrl();
  final savedServiceName = await storage.getBackendServiceName();

  // Attempt reconnection (checks if URL is reachable, or discovers via mDNS)
  final urlToUse =
      await reconnection.attemptReconnection(savedUrl, savedServiceName);

  // Update ApiService with the determined URL
  if (urlToUse != null && urlToUse.isNotEmpty) {
    api.setBaseUrl(urlToUse);
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
