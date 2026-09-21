import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(int quantity) onAdd;

  const ProductCard({super.key, required this.product, required this.onAdd});

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
                // --- Indicador de Stock y Unidad de Medida ---
                Text(
                  isAgotado
                      ? 'Agotado'
                      : 'Stock: ${product.stockActual} ${product.unidadMedida ?? 'UNIDAD'}',
                  key: const ValueKey('product_card_stock_text'),
                  style: TextStyle(
                    color: isAgotado ? Colors.red : Colors.grey[600],
                    fontWeight: isAgotado ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                if (product.unidadMedida != null && product.unidadMedida!.isNotEmpty)
                  Container(
                    key: const ValueKey('product_card_unidad_badge'),
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.unidadMedida!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade700,
                      ),
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