import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/widgets/cargando_diferido.dart';

void main() {
  Future<void> montar(WidgetTester tester) => tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CargandoDiferido())));

  testWidgets('no muestra el spinner antes de 300 ms', (tester) async {
    await montar(tester);
    await tester.pump(const Duration(milliseconds: 299));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('muestra el spinner centrado después de 300 ms', (tester) async {
    await montar(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Center)),
        findsWidgets);
  });

  testWidgets('si la carga termina antes, el spinner nunca aparece',
      (tester) async {
    await montar(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('datos'))));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('datos'), findsOneWidget);
  });
}
