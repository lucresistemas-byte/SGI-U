import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/pos_bloc.dart';
import 'blocs/pos_event.dart';
import 'blocs/finanzas/finanzas_bloc.dart';
import 'blocs/insumos/insumos_bloc.dart';
import 'blocs/recetas/recetas_bloc.dart';
import 'blocs/pedidos/pedidos_bloc.dart';
import 'navigation/app_shell.dart';
import 'navigation/seccion.dart';
import 'navigation/transiciones.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Pantalla que se muestra al iniciar sesión. Para cambiar la sección de
/// inicio de la app alcanza con modificar esta línea.
const Widget pantallaPrincipalPorDefecto =
    AppShell(seccionInicial: Seccion.catalogo);

class MyApp extends StatelessWidget {
  /// [authRepository], [posApi] y [pantallaPrincipal] son inyectables para
  /// los tests.
  const MyApp({
    super.key,
    this.authRepository,
    this.posApi,
    this.pantallaPrincipal = pantallaPrincipalPorDefecto,
  });

  final AuthRepository? authRepository;
  final PosApi? posApi;
  final Widget pantallaPrincipal;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authRepository: authRepository ?? AuthRepository())
            ..add(CheckAuthStatus()),
        ),
        BlocProvider(create: (context) => PosBloc(apiService: posApi)),
        BlocProvider(create: (context) => FinanzasBloc()),
        BlocProvider(create: (context) => InsumosBloc()),
        BlocProvider(create: (context) => RecetasBloc()),
        BlocProvider(create: (context) => PedidosBloc()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
        // Fin de sesión (logout o sesión vencida): StartupDecider vuelve a ser
        // la única ruta y muestra el login. El listener vive por encima del
        // Navigator, así que ninguna navegación lo elimina. Al autenticarse no
        // se navega: StartupDecider cambia solo según AuthState.
        builder: (context, child) => BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous is Authenticated && current is Unauthenticated,
          listener: (context, state) {
            // Logout explícito: el próximo usuario no hereda el carrito. Si la
            // sesión venció se conserva, para que quien reingrese retome la venta.
            if (state is Unauthenticated && !state.sesionVencida) {
              context.read<PosBloc>().add(const ClearSelection());
            }
            // Sin animación: el login aparece en el mismo frame.
            navigatorKey.currentState?.pushAndRemoveUntil(
              rutaInstantanea(
                (_) => StartupDecider(pantallaPrincipal: pantallaPrincipal),
              ),
              (route) => false,
            );
          },
          child: child!,
        ),
        home: StartupDecider(pantallaPrincipal: pantallaPrincipal),
      ),
    );
  }
}

class StartupDecider extends StatelessWidget {
  const StartupDecider({
    super.key,
    this.pantallaPrincipal = pantallaPrincipalPorDefecto,
  });

  final Widget pantallaPrincipal;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return pantallaPrincipal;
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
