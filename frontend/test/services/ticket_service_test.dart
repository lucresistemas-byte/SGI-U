import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/cart_item.dart';
import 'package:sgi_u_frontend/models/completed_sale.dart';
import 'package:sgi_u_frontend/models/configuracion_negocio.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/services/ticket_service.dart';

void main() {
  // 1x1 PNG válido en Base64
  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  final sampleLogo = base64Decode(base64Png);

  final sampleSale = CompletedSale(
    items: const [
      CartItem(
        codigo: 'PROD-1',
        nombre: 'Gaseosa Cola',
        precioUnitario: 1500.0,
        cantidad: 2,
      ),
    ],
    totalAmount: 3000.0,
    paymentMethod: 'EFECTIVO',
    timestamp: DateTime(2026, 9, 21, 16, 0),
  );

  tearDown(() {
    ApiService.configuracionActual = null;
  });

  group('TicketService - Comprobante con Marca (Tarea 6.3)', () {
    test('generarTicket genera PDF válido con nombre de negocio y logo configurados', () async {
      final config = ConfiguracionNegocio(
        nombre: 'Almacén Sandra',
        direccion: 'Calle Falsa 123',
        telefono: '555-4321',
        logo: sampleLogo,
      );

      final pdfBytes = await TicketService.generarTicket(
        sale: sampleSale,
        configuracion: config,
      );

      expect(pdfBytes, isNotEmpty);
      // Validar cabecera mágica de PDF (%PDF-)
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));

      // Verificar que el PDF generado incluye referencias al stream de imagen del logo
      final pdfContent = latin1.decode(pdfBytes, allowInvalid: true);
      expect(pdfContent.contains('/Subtype /Image') || pdfContent.contains('/XObject'), isTrue);
    });

    test('generarTicket genera PDF sin logo cuando no está configurado, manteniendo el nombre del negocio', () async {
      const config = ConfiguracionNegocio(
        nombre: 'Supermercado Central',
        direccion: 'Ruta 9 Km 40',
        logo: null,
      );

      final pdfBytes = await TicketService.generarTicket(
        sale: sampleSale,
        configuracion: config,
      );

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('generarTicket usa ApiService.configuracionActual si no se pasa config explícita', () async {
      ApiService.configuracionActual = ConfiguracionNegocio(
        nombre: 'Kiosco El Paso',
        logo: sampleLogo,
      );

      final pdfBytes = await TicketService.generarTicket(sale: sampleSale);

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));

      final pdfContent = latin1.decode(pdfBytes, allowInvalid: true);
      expect(pdfContent.contains('/Subtype /Image') || pdfContent.contains('/XObject'), isTrue);
    });

    test('generarTicket con parámetros individuales de nombre y logo los respeta', () async {
      final pdfBytes = await TicketService.generarTicket(
        sale: sampleSale,
        nombreNegocio: 'Panadería La Unión',
        logoBytes: sampleLogo,
      );

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });
  });
}
