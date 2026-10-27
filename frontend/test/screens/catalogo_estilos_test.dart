import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/screens/catalogo_estilos_screen.dart';
import 'package:sgi_u_frontend/theme/app_theme.dart';

void main() {
  testWidgets('el catálogo de estilos renderiza sus secciones', (t) async {
    t.view.physicalSize = const Size(1400, 2200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const CatalogoEstilosScreen(),
    ));
    expect(find.text('Catálogo de estilos'), findsWidgets);
    expect(find.text('Colores'), findsOneWidget);
    expect(find.text('Tipografía'), findsOneWidget);
  });
}
