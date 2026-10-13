import 'package:equatable/equatable.dart';

abstract class PosEvent extends Equatable {
  const PosEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends PosEvent {
  const LoadProducts();
}

class AddToCart extends PosEvent {
  final String productCode;
  final int quantity;
  const AddToCart(this.productCode, this.quantity);
  @override
  List<Object?> get props => [productCode, quantity];
}

class UpdateCartItemQuantity extends PosEvent {
  final String productCode;
  final int newQuantity;
  const UpdateCartItemQuantity(this.productCode, this.newQuantity);
  @override
  List<Object?> get props => [productCode, newQuantity];
}

class RemoveFromCart extends PosEvent {
  final String productCode;
  const RemoveFromCart(this.productCode);
  @override
  List<Object?> get props => [productCode];
}

/// Agrega una línea de pago (si el método ya está, suma el monto). Solo el
/// efectivo puede superar lo que falta (vuelto).
class AgregarPago extends PosEvent {
  final int metodoPagoId;
  final double monto;
  const AgregarPago(this.metodoPagoId, this.monto);
  @override
  List<Object?> get props => [metodoPagoId, monto];
}

/// Camino rápido: paga todo lo que falta con un método (un toque).
class PagarRestante extends PosEvent {
  final int metodoPagoId;
  const PagarRestante(this.metodoPagoId);
  @override
  List<Object?> get props => [metodoPagoId];
}

class QuitarPago extends PosEvent {
  final int indice;
  const QuitarPago(this.indice);
  @override
  List<Object?> get props => [indice];
}

class ConfirmSale extends PosEvent {
  const ConfirmSale();
}

// Nuevos eventos para limpiar mensajes
class ClearError extends PosEvent {
  const ClearError();
}

class ClearSuccess extends PosEvent {
  const ClearSuccess();
}

class ClearSelection extends PosEvent {
  const ClearSelection();
}

// --- NUEVOS EVENTOS PARA EL CATÁLOGO (FT-5 y FT-6) ---

class CreateProduct extends PosEvent {
  final Map<String, dynamic> productData;
  const CreateProduct(this.productData);
  @override
  List<Object?> get props => [productData];
}

class UpdateProduct extends PosEvent {
  final String codigo;
  final Map<String, dynamic> productData;

  /// Delta de stock (positivo suma, negativo resta). Null si no se ajusta.
  final int? stockAjuste;
  final String? stockMotivo;
  const UpdateProduct(
    this.codigo,
    this.productData, {
    this.stockAjuste,
    this.stockMotivo,
  });
  @override
  List<Object?> get props => [codigo, productData, stockAjuste, stockMotivo];
}

// --- EVENTOS DE FILTRADO Y BÚSQUEDA (Tareas 2.4 y 2.5) ---

class FilterByCategoryEvent extends PosEvent {
  final String? category;
  const FilterByCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class SearchProductsEvent extends PosEvent {
  final String query;
  const SearchProductsEvent(this.query);
  @override
  List<Object?> get props => [query];
}