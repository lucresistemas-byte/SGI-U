import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // NUEVO: Importamos la herramienta Bloc
import 'blocs/pos_bloc.dart'; // NUEVO: Importamos tu Cerebro
import 'screens/catalogo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ENVOLVEMOS la app con el BlocProvider para que el cerebro esté disponible en todas partes
    return BlocProvider(
      create: (context) => PosBloc(), // Inicializamos el BLoC aquí
      child: MaterialApp(
        title: 'SGI-U',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF13894E)),
        ),
        home: const CatalogoScreen(),
      ),
    );
  }
}