import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/models/cart_item.dart';
import 'package:sgi_u_frontend/navigation/app_shell.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/side_menu.dart';

class _MockPosApi extends Mock implements PosApi {}

/// Sección falsa que cuenta cuántas veces se crea (initState), para verificar
/// que se reconstruye (y recargaría sus datos) cada vez que se muestra.
class _SeccionFalsa extends StatefulWidget {
  const _SeccionFalsa(this.seccion, this.creaciones);
  final Seccion seccion;
  final Map<Seccion, int> creaciones;

  @override
  State<_SeccionFalsa> createState() => _SeccionFalsaState();
}

class _SeccionFalsaState extends State<_SeccionFalsa> {
  @override
  void initState() {
    super.initState();
    widget.creaciones.update(widget.seccion, (n) => n + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => Text('SECCION ${widget.seccion.name}');
}

void main() {
  late Map<Seccion, int> creaciones;
  late _MockPosApi api;
  late PosBloc posBloc;

  setUp(() {
    creaciones = {};
    api = _MockPosApi();
    when(() => api.getProducts()).thenAnswer((_) async => [
          {
            'codigo': 'P1',
            'nombre': 'Café',
            'precioUnitario': 150.0,
            'stockActual': 10,
            'activo': true,
          }
        ]);
  });

  void tamanio(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> montar(
    WidgetTester tester, {
    Seccion inicial = Seccion.catalogo,
    Widget Function(Seccion)? construir,
  }) async {
    // El bloc se crea dentro del test (zona fake async) para que sus
    // llamadas asíncronas avancen con pump.
    posBloc = PosBloc(apiService: api);
    addTearDown(posBloc.close);
    await tester.pumpWidget(BlocProvider<PosBloc>.value(
      value: posBloc,
      child: MaterialApp(
        home: AppShell(
          seccionInicial: inicial,
          construirSeccion: construir ?? (s) => _SeccionFalsa(s, creaciones),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('desktop (>= 900 px)', () {
    testWidgets(
        'cambiar de sección muestra la sección correcta sin recrear el menú',
        (tester) async {
      tamanio(tester, const Size(1400, 900));
      await montar(tester);
      expect(find.text('SECCION catalogo'), findsOneWidget);
      final menuAntes = tester.state(find.byType(SideMenu));

      for (final seccion in [Seccion.pedidos, Seccion.balance, Seccion.pos]) {
        await tester.tap(find.text(seccion.etiqueta));
        await tester.pump();

        expect(find.text('SECCION ${seccion.name}'), findsOneWidget);
        expect(find.textContaining('SECCION '), findsOneWidget);
        expect(tester.state(find.byType(SideMenu)), same(menuAntes));
        expect(tester.widget<SideMenu>(find.byType(SideMenu)).seccionActual,
            seccion);
      }
      // Sin transición: el contenido cambió en un solo frame (pump sin
      // tiempo) y no se apiló ninguna ruta.
      expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
          isFalse);
    });

    testWidgets('el menú conserva su estado colapsado al cambiar de sección',
        (tester) async {
      tamanio(tester, const Size(1400, 900));
      await montar(tester);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SideMenu)).width, 80);

      await tester.tap(find.byIcon(Seccion.recetas.icono));
      await tester.pumpAndSettle();

      expect(find.text('SECCION recetas'), findsOneWidget);
      expect(tester.getSize(find.byType(SideMenu)).width, 80);
    });

    testWidgets('cada sección se reconstruye al volver a mostrarse',
        (tester) async {
      tamanio(tester, const Size(1400, 900));
      await montar(tester);

      await tester.tap(find.text(Seccion.insumos.etiqueta));
      await tester.pump();
      await tester.tap(find.text(Seccion.catalogo.etiqueta));
      await tester.pump();

      expect(creaciones[Seccion.catalogo], 2);
      expect(creaciones[Seccion.insumos], 1);
    });

    testWidgets('el carrito del POS se conserva al ir a otra sección y volver',
        (tester) async {
      tamanio(tester, const Size(1400, 900));
      // POS real; el resto, falsas (sin red).
      await montar(tester,
          inicial: Seccion.pos,
          construir: (s) =>
              s == Seccion.pos ? s.construir() : _SeccionFalsa(s, creaciones));
      expect(posBloc.state.products, isNotEmpty);
      posBloc.add(const AddToCart('P1', 3));
      await tester.pumpAndSettle();
      expect(posBloc.state.cart['P1']?.cantidad, 3);

      await tester.tap(find.text(Seccion.movimientos.etiqueta));
      await tester.pumpAndSettle();
      expect(find.text('SECCION movimientos'), findsOneWidget);

      await tester.tap(find.text(Seccion.pos.etiqueta));
      await tester.pumpAndSettle();

      final CartItem? item = posBloc.state.cart['P1'];
      expect(item?.cantidad, 3);
      // El carrito se ve en el POS reconstruido.
      expect(find.text('Café'), findsWidgets);
    });
  });

  group('móvil (< 900 px)', () {
    testWidgets(
        'elegir una sección en el drawer lo cierra y cambia el contenido',
        (tester) async {
      tamanio(tester, const Size(600, 1000));
      await montar(tester);
      expect(find.text(Seccion.catalogo.titulo), findsOneWidget);

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text(Seccion.pedidos.etiqueta));
      await tester.pumpAndSettle();

      expect(tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
          isFalse);
      expect(find.text('SECCION pedidos'), findsOneWidget);
      expect(find.text(Seccion.pedidos.titulo), findsOneWidget);
    });
  });
}
