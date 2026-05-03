import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(int quantity) onAdd;

  const ProductCard({Key? key, required this.product, required this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Evaluamos si el producto está agotado
    final bool isAgotado = product.stockActual <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      // Si está agotado, le ponemos un fondo un poquito más gris
      color: isAgotado ? Colors.grey[200] : Colors.white,
      child: InkWell(
        // Magia aquí: si pasamos 'null' al onTap, Flutter automáticamente desactiva el botón y el clic
        onTap: isAgotado ? null : () => onAdd(1),
        child: Opacity(
          // Si está agotado, bajamos la transparencia al 60%
          opacity: isAgotado ? 0.6 : 1.0,
          child: SizedBox(
            width: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory, size: 40),
                const SizedBox(height: 8),
                Text(
                  product.nombre, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text('\$${product.precioUnitario.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                // --- NUEVO: Indicador de Stock ---
                Text(
                  isAgotado ? 'Agotado' : 'Stock: ${product.stockActual}',
                  style: TextStyle(
                    color: isAgotado ? Colors.red : Colors.grey[600],
                    fontWeight: isAgotado ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}