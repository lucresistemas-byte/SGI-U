import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/product.dart';

void main() {
  group('PosBloc - Filtros por Categoría y Búsqueda (Tareas 2.4 y 2.5)', () {
    late PosBloc posBloc;

    final pBebida1 = Product(
      codigo: 'BEB-001',
      nombre: 'Coca Cola 250ml',
      precioUnitario: 1500.0,
      stockActual: 10,
      categoria: 'Bebidas',
    );

    final pBebida2 = Product(
      codigo: 'BEB-002',
      nombre: 'Agua Mineral 500ml',
      precioUnitario: 1000.0,
      stockActual: 15,
      categoria: 'Bebidas',
    );

    final pComida = Product(
      codigo: 'COM-001',
      nombre: 'Hamburguesa Completa',
      precioUnitario: 5000.0,
      stockActual: 5,
      categoria: 'Comidas',
    );

    final pSinCategoria = Product(
      codigo: 'GEN-001',
      nombre: 'Bolsa Ecológica',
      precioUnitario: 200.0,
      stockActual: 50,
      categoria: null,
    );

    final allProducts = [pBebida1, pBebida2, pComida, pSinCategoria];

    setUp(() {
      posBloc = PosBloc();
    });

    tearDown(() {
      posBloc.close();
    });

    test('availableCategories extrae categorías únicas sin duplicados ni nulos', () {
      final state = PosState.initial().copyWith(products: allProducts);
      expect(state.availableCategories, equals(['Bebidas', 'Comidas']));
    });

    blocTest<PosBloc, PosState>(
      'Al emitir FilterByCategoryEvent con "Bebidas", filteredProducts filtra solo bebidas',
      build: () => posBloc,
      seed: () => PosState.initial().copyWith(products: allProducts),
      act: (bloc) => bloc.add(const FilterByCategoryEvent('Bebidas')),
      expect: () => [
        isA<PosState>()
            .having((s) => s.selectedCategory, 'selectedCategory', 'Bebidas')
            .having((s) => s.filteredProducts, 'filteredProducts', [pBebida1, pBebida2]),
      ],
    );

    blocTest<PosBloc, PosState>(
      'Al emitir FilterByCategoryEvent con "Todas" o null, restablece la lista completa',
      build: () => posBloc,
      seed: () => PosState.initial().copyWith(
        products: allProducts,
        selectedCategory: 'Bebidas',
      ),
      act: (bloc) => bloc.add(const FilterByCategoryEvent('Todas')),
      expect: () => [
        isA<PosState>()
            .having((s) => s.selectedCategory, 'selectedCategory', isNull)
            .having((s) => s.filteredProducts.length, 'filteredProducts.length', 4),
      ],
    );

    blocTest<PosBloc, PosState>(
      'Al combinar filtro de categoría y SearchProductsEvent, devuelve la intersección',
      build: () => posBloc,
      seed: () => PosState.initial().copyWith(
        products: allProducts,
        selectedCategory: 'Bebidas',
      ),
      act: (bloc) => bloc.add(const SearchProductsEvent('Coca')),
      expect: () => [
        isA<PosState>()
            .having((s) => s.selectedCategory, 'selectedCategory', 'Bebidas')
            .having((s) => s.searchQuery, 'searchQuery', 'Coca')
            .having((s) => s.filteredProducts, 'filteredProducts', [pBebida1]),
      ],
    );
  });
}
