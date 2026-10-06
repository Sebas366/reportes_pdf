import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:reportes_pdf_ia/data/respuestas_simuladas.dart';
import 'package:reportes_pdf_ia/models/escenario.dart';
import 'package:reportes_pdf_ia/models/reporte_ia.dart';
import 'package:reportes_pdf_ia/services/pdf/pdf_service.dart';

/// Pruebas del generador. El paquete pdf es Dart puro, así que el documento
/// completo se puede generar y validar sin emulador.
///
/// Para revisar los PDF a mano:
///   PDF_SALIDA=/tmp flutter test test/pdf_service_test.dart
void main() {
  // Necesario para que rootBundle lea las fuentes de los assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  final fecha = DateTime(2026, 10, 5, 14, 7);
  ReporteIa reportePara(Escenario escenario) =>
      ReporteIa.desdeTextoLlm(RespuestasSimuladas.para(escenario, fecha: fecha));

  bool esPdfCompleto(Uint8List bytes) {
    final inicio = String.fromCharCodes(bytes.take(5));
    final fin = String.fromCharCodes(bytes.skip(bytes.length - 8));
    return inicio == '%PDF-' && fin.contains('%%EOF');
  }

  group('PdfService', () {
    for (final escenario in Escenario.values) {
      test('genera un PDF completo para "${escenario.etiqueta}"', () async {
        final bytes = await const PdfService().generar(reportePara(escenario));

        expect(esPdfCompleto(bytes), isTrue);
        expect(bytes.length, greaterThan(20 * 1024), reason: 'incluye fuentes embebidas');

        final salida = Platform.environment['PDF_SALIDA'];
        if (salida != null) {
          File('$salida/${escenario.name}.pdf').writeAsBytesSync(bytes);
        }
      });
    }

    test('sin anexo el documento es más liviano', () async {
      final reporte = reportePara(Escenario.sentimientoClientes);
      final conAnexo = await const PdfService().generar(reporte);
      final sinAnexo = await const PdfService().generar(reporte, incluirAnexo: false);

      expect(esPdfCompleto(sinAnexo), isTrue);
      expect(sinAnexo.length, lessThan(conAnexo.length));
    });

    test('acepta otros tamaños de página (Carta)', () async {
      final bytes = await const PdfService().generar(
        reportePara(Escenario.rendimientoAcademico),
        formato: PdfPageFormat.letter,
      );
      expect(esPdfCompleto(bytes), isTrue);
    });

    test('las fuentes se cargan una sola vez (caché)', () async {
      final primera = await FuentesPdf.cargar();
      final segunda = await FuentesPdf.cargar();
      expect(identical(primera, segunda), isTrue);
    });
  });
}
