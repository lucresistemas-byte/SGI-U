import 'package:flutter/material.dart';
import '../models/unidad_medida.dart';
import '../utils/numeros.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(int quantity) onAdd;

  const ProductCard({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    // Evaluamos si el producto está agotado
    final bool isAgotado = product.stockActual <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.espacioChico),
      // Si está agotado, le ponemos un fondo un poquito más gris
      color: isAgotado ? AppColors.fondoAlternativo : AppColors.fondoSuperficie,
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
                const SizedBox(height: AppSpacing.espacioChico),
                Text(
                  product.nombre,
                  textAlign: TextAlign.center,
                  style: AppTypography.textoChico
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.espacioMinimo),
                Text(
                  formatPesos(product.precioUnitario),
                  style: AppTypography.textoChico,
                ),
                const SizedBox(height: AppSpacing.espacioMinimo),
                // --- Indicador de Stock y Unidad de Medida ---
                Text(
                  isAgotado
                      ? 'Agotado'
                      : 'Stock: ${textoStock(product.stockActual, product.unidadStock)}',
                  key: const ValueKey('product_card_stock_text'),
                  style: AppTypography.etiqueta.copyWith(
                    color: isAgotado
                        ? AppColors.error
                        : AppColors.textoTerciario,
                    fontWeight:
                        isAgotado ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (product.unidadStock.isNotEmpty)
                  Container(
                    key: const ValueKey('product_card_unidad_badge'),
                    margin: const EdgeInsets.only(top: AppSpacing.espacioMinimo),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.espacioChico,
                      vertical: AppSpacing.espacioMinimo,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.bordeSuave,
                      borderRadius: AppRadii.bordeMinimo,
                    ),
                    child: Text(
                      UnidadMedida.deCodigo(product.unidadStock)?.nombre ??
                          product.unidadStock,
                      style: AppTypography.pie.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.menuTexto,
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
