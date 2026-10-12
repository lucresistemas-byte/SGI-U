import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/screens/pos_screen.dart';

class _MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

/// Etapa 1: el POS muestra solo lo vendible (activo, de tipo vendible y que
/// no sea preparación base). Productos sigue viendo todo.
void main() {
  final tarta = Product(codigo: 'ELA-1', nombre: 'Tarta de coco', precioUnitario: 10800, stockActual: 4,
      tipo: 'ELABORADO', categoria: 'Tortas');
  final ganache = Product(codigo: 'ELA-2', nombre: 'Ganache', precioUnitario: 4700, stockActual: 0,
      tipo: 'ELABORADO', vendible: false, categoria: 'Preparaciones');
  final coca = Product(codigo: 'REV-1', nombre: 'Coca-Cola', precioUnitario: 1500, stockActual: 24,
      categoria: 'Bebidas');
  final agua = Product(codigo: 'REV-2', nombre: 'Agua', precioUnitario: 900, stockActual: 24,
      activo: false, categoria: 'Bebidas');

  group('Product', () {
    test('parsea tipo y vendible, y calcula si se vende en el POS', () {
      final p = Product.fromJson({
        'codigo': 'ELA-2', 'nombre': 'Ganache', 'precioUnitario': 4700, 'stockActual': 0,
        'tipo': 'ELABORADO', 'vendible': false,
      });

      expect(p.tipo, 'ELABORADO');
      expect(p.esPreparacionBase, isTrue);
      expect(p.esVendibleEnPos, isFalse);
      expect(tarta.esVendibleEnPos, isTrue);
      expect(coca.esVendibleEnPos, isTrue);
      expect(agua.esVendibleEnPos, isFalse);
    });

    test('sin tipo en el JSON se asume reventa vendible', () {
      final p = Product.fromJson({'codigo': 'X', 'nombre': 'X', 'precioUnitario': 1, 'stockActual': 1});
      expect(p.tipo, 'REVENTA');
      expect(p.esVendibleEnPos, isTrue);
    });
  });

  testWidgets('el POS no muestra preparaciones base ni inactivos, ni sus categorías', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final bloc = _MockPosBloc();
    final estado = PosState.initial().copyWith(products: [tarta, ganache, coca, agua]);
    whenListen(bloc, const Stream<PosState>.empty(), initialState: estado);

    await tester.pumpWidget(MaterialApp(
        home: BlocProvider<PosBloc>.value(value: bloc, child: const PosScreen())));
    await tester.pump();

    expect(find.text('Tarta de coco'), findsWidgets);
    expect(find.text('Coca-Cola'), findsWidgets);
    expect(find.text('Ganache'), findsNothing);
    expect(find.text('Agua'), findsNothing);
    expect(find.text('Preparaciones'), findsNothing);
    expect(find.text('Tortas'), findsWidgets);
  });
}
