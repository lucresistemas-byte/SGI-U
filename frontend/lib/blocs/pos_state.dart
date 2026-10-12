import 'package:equatable/equatable.dart';
import '../models/cart_item.dart';
import '../models/completed_sale.dart';
import '../models/product.dart';

const Object _unset = Object();

class PosState extends Equatable {
  final List<Product> products;
  final Map<String, CartItem> cart;
  final String? selectedPaymentMethod;
  final bool isProcessing;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final CompletedSale? completedSale;
  final String? selectedCategory;
  final String searchQuery;

  const PosState({
    required this.products,
    required this.cart,
    this.selectedPaymentMethod,
    this.isProcessing = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.completedSale,
    this.selectedCategory,
    this.searchQuery = '',
  });

  factory PosState.initial() {
    return const PosState(
      products: [],
      cart: {},
      selectedPaymentMethod: null,
      isProcessing: false,
      isLoading: false,
      errorMessage: null,
      successMessage: null,
      completedSale: null,
      selectedCategory: null,
      searchQuery: '',
    );
  }

  PosState copyWith({
    List<Product>? products,
    Map<String, CartItem>? cart,
    String? selectedPaymentMethod,
    bool? isProcessing,
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
    Object? completedSale = _unset,
    Object? selectedCategory = _unset,
    String? searchQuery,
  }) {
    return PosState(
      products: products ?? this.products,
      cart: cart ?? this.cart,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
      completedSale: identical(completedSale, _unset)
          ? this.completedSale
          : completedSale as CompletedSale?,
      selectedCategory: identical(selectedCategory, _unset)
          ? this.selectedCategory
          : selectedCategory as String?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Lista de productos filtrada por categoría y término de búsqueda combinados
  List<Product> get filteredProducts {
    return products.where((p) {
      final matchesCategory = selectedCategory == null ||
          selectedCategory!.isEmpty ||
          selectedCategory == 'Todas' ||
          (p.categoria != null &&
              p.categoria!.toLowerCase() == selectedCategory!.toLowerCase());
      final matchesSearch = searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.codigo.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Lo que el POS puede vender (activo, de tipo vendible, no preparación base).
  /// Productos usa la lista completa; el POS, solo esta.
  List<Product> get vendibles => products.where((p) => p.esVendibleEnPos).toList();

  /// [filteredProducts] limitado a lo vendible (grilla del POS).
  List<Product> get filteredVendibles =>
      filteredProducts.where((p) => p.esVendibleEnPos).toList();

  /// Categorías de los productos vendibles (chips del POS).
  List<String> get availableCategoriesVendibles {
    final categories = <String>{
      for (final p in vendibles)
        if (p.categoria != null && p.categoria!.trim().isNotEmpty) p.categoria!.trim(),
    };
    return categories.toList()..sort();
  }

  /// Lista ordenada de categorías únicas disponibles entre los productos cargados
  List<String> get availableCategories {
    final Set<String> categories = {};
    for (final p in products) {
      if (p.categoria != null && p.categoria!.trim().isNotEmpty) {
        categories.add(p.categoria!.trim());
      }
    }
    return categories.toList()..sort();
  }

  /// D.12: total usando precio congelado de CartItem.
  double get totalAmount {
    double total = 0.0;
    for (var item in cart.values) {
      total += item.precioUnitario * item.cantidad;
    }
    return total;
  }

  @override
  List<Object?> get props => [
        products,
        cart,
        selectedPaymentMethod,
        isProcessing,
        isLoading,
        errorMessage,
        successMessage,
        completedSale,
        selectedCategory,
        searchQuery,
      ];
}
