import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../utils/parsers.dart';

class PdfService {
  static Future<void> generarYDescargarBalance({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double totalIngresos,
    required double totalEgresos,
    required double margenNeto,
    required List<dynamic> movimientos,
  }) async {
    final pdf = pw.Document();
    final _formatterFecha = DateFormat('dd/MM/yyyy');
    final _formatterCurrency =
        NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    final _formatterFechaHora = DateFormat('dd/MM/yyyy HH:mm');

    // Construir contenido del PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // Encabezado
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SGI-U',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF006B3D),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Reporte de Balance',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),
              // Período
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Período',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        '${_formatterFecha.format(fechaInicio)} - ${_formatterFecha.format(fechaFin)}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Fecha de generación',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        _formatterFechaHora.format(DateTime.now()),
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              // KPIs
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKpiCard('Total Ingresos', totalIngresos,
                      PdfColor.fromInt(0xFF008A3D)),
                  _buildKpiCard('Total Egresos', totalEgresos,
                      PdfColor.fromInt(0xFFFF2E2E)),
                  _buildKpiCard(
                    'Margen Neto',
                    margenNeto,
                    margenNeto >= 0
                        ? PdfColor.fromInt(0xFF008A3D)
                        : PdfColor.fromInt(0xFFFF2E2E),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              // Tabla de movimientos
              pw.Text(
                'Detalle de Movimientos',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF6F6F6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(fontSize: 9),
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey200),
                ),
                headers: [
                  'Fecha/Hora',
                  'Tipo',
                  'Monto',
                  'Método de Pago',
                  'Categoría',
                  'Descripción',
                ],
                data: movimientos.map((mov) {
                  String tipoRaw = parseString(mov['tipo']);
                  String tipoDisplay =
                      tipoRaw.toLowerCase() == 'ingreso' ? 'Ingreso' : 'Egreso';
                  String metodoRaw = parseString(mov['metodoPago']);
                  String metodoDisplay = _parseMetodoPago(metodoRaw);
                  double monto = parseDouble(mov['monto']);
                  String fechaHora =
                      _formatFechaHora(parseString(mov['fechaHora']));
                  String categoria =
                      parseString(mov['categoria'], 'Sin categoría');
                  String descripcion = parseString(mov['descripcion']);

                  return [
                    fechaHora,
                    tipoDisplay,
                    _formatterCurrency.format(monto),
                    metodoDisplay,
                    categoria,
                    descripcion,
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
              pw.Text(
                'Documento generado automáticamente por SGI-U',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );

    // Descargar PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'Balance_${_formatterFecha.format(fechaInicio)}_a_${_formatterFecha.format(fechaFin)}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String titulo, double valor, PdfColor color) {
    final _formatterCurrency =
        NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _formatterCurrency.format(valor),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _parseMetodoPago(String raw) {
    switch (raw) {
      case '1':
        return 'Efectivo';
      case '2':
        return 'Mercado Pago';
      case '3':
        return 'Tarjeta';
      default:
        return raw;
    }
  }

  static String _formatFechaHora(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
    } catch (e) {
      return isoString;
    }
  }
}
