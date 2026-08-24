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

  // L4.2: Initialize backend URL from storage and attempt reconnection
  await _initializeBackendUrl();

  runApp(const MyApp());
}

/// Initializes the backend URL from storage and performs reconnection logic.
/// This ensures the app uses a valid backend URL before proceeding.
Future<void> _initializeBackendUrl() async {
  final storageService = StorageService();
  final reconnectionService =
      ReconnectionService(storageService: storageService);
  final apiService = ApiService();

  // Read saved URL and service name
  final savedUrl = await storageService.getBackendUrl();
  final savedServiceName = await storageService.getBackendServiceName();

  // Attempt reconnection (checks if URL is reachable, or discovers via mDNS)
  final urlToUse =
      await reconnectionService.attemptReconnection(savedUrl, savedServiceName);

  // Update ApiService with the determined URL
  if (urlToUse != null && urlToUse.isNotEmpty) {
    apiService.updateBaseUrl(urlToUse);
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
