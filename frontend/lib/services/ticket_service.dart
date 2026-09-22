import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/completed_sale.dart';
import '../models/configuracion_negocio.dart';
import 'api_service.dart';

/// D.7.1: genera un ticket PDF a partir de una venta completada.
/// Usa el precio congelado de CartItem (D.12).
class TicketService {
  static final _formatterFecha = DateFormat('dd/MM/yyyy HH:mm');
  static final _formatterCurrency =
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 2);

  /// Genera los bytes de un PDF con el ticket de la venta.
  static Future<Uint8List> generarTicket({
    required CompletedSale sale,
    String? nombreNegocio,
    Uint8List? logoBytes,
    ConfiguracionNegocio? configuracion,
  }) async {
    final pdf = pw.Document();

    final String nombre = nombreNegocio ??
        configuracion?.nombre ??
        ApiService.configuracionActual?.nombre ??
        'SGI-U';
    final Uint8List? logo = logoBytes ??
        configuracion?.logo ??
        ApiService.configuracionActual?.logo;
    final String? direccion =
        configuracion?.direccion ?? ApiService.configuracionActual?.direccion;
    final String? telefono =
        configuracion?.telefono ?? ApiService.configuracionActual?.telefono;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, 297 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context context) => [
          // Logo (si existe)
          if (logo != null && logo.isNotEmpty) ...[
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(logo),
                width: 30 * PdfPageFormat.mm,
                height: 18 * PdfPageFormat.mm,
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(height: 3),
          ],
          // Encabezado
          pw.Center(
            child: pw.Text(
              nombre,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF006B3D),
              ),
            ),
          ),
          if (direccion != null && direccion.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Center(
              child: pw.Text(
                direccion,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ],
          if (telefono != null && telefono.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Center(
              child: pw.Text(
                'Tel: $telefono',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ],
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'Ticket de Venta',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 4),

          // Fecha
          pw.Text(
            _formatterFecha.format(sale.timestamp),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),

          // Línea de venta
          pw.Text(
            'Detalle de productos',
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),

          // Tabla de productos (precio congelado de CartItem)
          pw.TableHelper.fromTextArray(
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF0F0F0),
            ),
            headers: ['Prod.', 'Cant.', 'P.U.', 'Subt.'],
            data: sale.items.map((item) {
              return [
                item.nombre.length > 18
                    ? '${item.nombre.substring(0, 15)}...'
                    : item.nombre,
                item.cantidad.toString(),
                _formatterCurrency.format(item.precioUnitario),
                _formatterCurrency.format(item.subtotal),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 8),

          // Total
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                _formatterCurrency.format(sale.totalAmount),
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Método de pago
          pw.Text(
            'Método de pago',
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _formatMetodoPago(sale.paymentMethod),
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1),
          pw.Center(
            child: pw.Text(
              'Documento generado automáticamente por SGI-U',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _formatMetodoPago(String raw) {
    switch (raw) {
      case 'EFECTIVO':
        return 'Efectivo';
      case 'MERCADO_PAGO':
        return 'Mercado Pago';
      default:
        return raw;
    }
  }
}
