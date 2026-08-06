import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sgi_u_frontend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('La app arranca y muestra el login cuando no hay token',
      (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
