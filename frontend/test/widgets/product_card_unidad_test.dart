import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/widgets/product_card.dart';

void main() {
  testWidgets('ProductCard muestra la unidad de medida en el indicador de stock y como badge',
      (WidgetTester tester) async {
    final product = Product(
      codigo: 'Q-01',
      nombre: 'Queso Barra',
      precioUnitario: 3200.0,
      stockActual: 15,
      unidadMedida: 'KILO',
    );

    int addedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProductCard(
              product: product,
              onAdd: (qty) => addedCount += qty,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifica que el nombre del producto se muestre
    expect(find.text('Queso Barra'), findsOneWidget);

    // Verifica que el texto de stock incluya la unidad
    expect(find.text('Stock: 15 KILO'), findsOneWidget);

    // Verifica que el badge de unidad esté presente con KILO
    expect(find.byKey(const ValueKey('product_card_unidad_badge')), findsOneWidget);
    expect(find.text('KILO'), findsWidgets);

    // Verifica interacción: tap en la tarjeta llama a onAdd(1)
    await tester.tap(find.byType(ProductCard));
    expect(addedCount, 1);
  });

  testWidgets('ProductCard muestra Agotado cuando el stock es 0',
      (WidgetTester tester) async {
    final product = Product(
      codigo: 'Q-02',
      nombre: 'Queso Cremoso',
      precioUnitario: 2800.0,
      stockActual: 0,
      unidadMedida: 'KILO',
    );

    int addedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProductCard(
              product: product,
              onAdd: (qty) => addedCount += qty,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agotado'), findsOneWidget);

    // Al estar agotado, tap no incrementa
    await tester.tap(find.byType(ProductCard));
    expect(addedCount, 0);
  });
}
