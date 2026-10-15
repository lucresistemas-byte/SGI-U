import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/theme/app_colors.dart';
import 'package:sgi_u_frontend/theme/app_theme.dart';

void main() {
  test('AppTheme.light usa la marca y el fondo del sistema', () {
    final tema = AppTheme.light;
    expect(tema.useMaterial3, isTrue);
    expect(tema.colorScheme.primary, AppColors.marca);
    expect(tema.scaffoldBackgroundColor, AppColors.fondoApp);
    expect(AppTheme.semilla, AppColors.marca);
  });
}
