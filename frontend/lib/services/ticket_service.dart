import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/completed_sale.dart';

/// D.7.1: genera un ticket PDF a partir de una venta completada.
/// Usa el precio congelado de CartItem (D.12).
class TicketService {
  static final _formatterFecha = DateFormat('dd/MM/yyyy HH:mm');
  static final _formatterCurrency =
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 2);

  /// Genera los bytes de un PDF con el ticket de la venta.
  static Future<Uint8List> generarTicket({required CompletedSale sale}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity,
            marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context context) => [
          // Encabezado
          pw.Center(
            child: pw.Text(
              'SGI-U',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF006B3D),
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'Ticket de Venta',
              style: pw.TextStyle(
                fontSize: 12,
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
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
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
            cellStyle: pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(
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
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1),
          pw.Center(
            child: pw.Text(
              'Documento generado automáticamente por SGI-U',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
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
