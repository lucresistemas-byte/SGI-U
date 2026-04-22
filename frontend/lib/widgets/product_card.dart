import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(int quantity) onAdd;

  const ProductCard({Key? key, required this.product, required this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => onAdd(1),
        child: SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory, size: 40),
              const SizedBox(height: 8),
              Text(product.nombre, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('\$${product.precioUnitario.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }
}