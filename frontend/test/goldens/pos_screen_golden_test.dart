import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/cart_item.dart';
import 'package:sgi_u_frontend/models/linea_pago.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/screens/pos_screen.dart';
import 'package:sgi_u_frontend/theme/app_theme.dart';

class _MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

void main() {
  const sizeDesktop = Size(1366, 768);
  const sizeMobile = Size(800, 600);

  final sampleProducts = [
    Product(
      codigo: 'TORTA-01',
      nombre: 'Torta Selva Negra',
      precioUnitario: 4500.0,
      stockActual: 8,
      activo: true,
      categoria: 'Tortas',
    ),
    Product(
      codigo: 'PAN-01',
      nombre: 'Medialunas de Manteca',
      precioUnitario: 800.0,
      stockActual: 30,
      activo: true,
      categoria: 'Panadería',
    ),
    Product(
      codigo: 'CAFE-01',
      nombre: 'Café Espresso Doble',
      precioUnitario: 1200.0,
      stockActual: 50,
      activo: true,
      categoria: 'Cafetería',
    ),
  ];

  const sampleMetodos = [
    MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 1),
    MetodoPago(id: 2, nombre: 'Transferencia', orden: 2),
    MetodoPago(id: 3, nombre: 'Mercado Pago', orden: 3),
  ];

  const sampleCart = {
    'TORTA-01': CartItem(
      codigo: 'TORTA-01',
      nombre: 'Torta Selva Negra',
      precioUnitario: 4500.0,
      cantidad: 1,
    ),
    'PAN-01': CartItem(
      codigo: 'PAN-01',
      nombre: 'Medialunas de Manteca',
      precioUnitario: 800.0,
      cantidad: 2,
    ),
  };

  final samplePagos = [
    LineaPago(metodo: sampleMetodos[0], monto: 3000.0),
  ];

  late _MockPosBloc mockPosBloc;

  setUp(() {
    mockPosBloc = _MockPosBloc();
  });

  tearDown(() {
    mockPosBloc.close();
  });

  Widget buildPosApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: BlocProvider<PosBloc>.value(
        value: mockPosBloc,
        child: const PosScreen(),
      ),
    );
  }

  group('Golden Tests - PosScreen', () {
    testWidgets('PosScreen - Desktop (1366x768)', (tester) async {
      tester.view.physicalSize = sizeDesktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = PosState.initial().copyWith(
        products: sampleProducts,
        metodosPago: sampleMetodos,
        cart: sampleCart,
        pagos: samplePagos,
        isLoading: false,
      );

      whenListen(
        mockPosBloc,
        Stream.fromIterable([state]),
        initialState: state,
      );

      await tester.pumpWidget(buildPosApp());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('snapshots/pos_screen_desktop.png'),
      );
    });

    testWidgets('PosScreen - Tablet/Mobile (800x600)', (tester) async {
      tester.view.physicalSize = sizeMobile;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = PosState.initial().copyWith(
        products: sampleProducts,
        metodosPago: sampleMetodos,
        cart: sampleCart,
        pagos: samplePagos,
        isLoading: false,
      );

      whenListen(
        mockPosBloc,
        Stream.fromIterable([state]),
        initialState: state,
      );

      await tester.pumpWidget(buildPosApp());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('snapshots/pos_screen_mobile.png'),
      );
    });
  });
}
