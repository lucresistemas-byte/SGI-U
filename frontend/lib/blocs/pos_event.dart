import 'package:equatable/equatable.dart';

abstract class PosEvent extends Equatable {
  const PosEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends PosEvent {}

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

class SelectPaymentMethod extends PosEvent {
  final String method; // "EFECTIVO" o "MERCADO_PAGO"
  const SelectPaymentMethod(this.method);
  @override
  List<Object?> get props => [method];
}

class ConfirmSale extends PosEvent {}