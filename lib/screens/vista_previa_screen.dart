import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/reporte_ia.dart';
import '../services/archivos_service.dart';
import '../services/pdf/pdf_service.dart';
import '../services/share_service.dart';

/// Vista previa con el widget `PdfPreview` del paquete printing.
///
/// PdfPreview llama a `build(formato)`, recibe los bytes y rasteriza cada
/// página con el motor nativo (PdfRenderer en Android, CGPDFDocument de
/// Core Graphics en iOS).
/// Barra inferior:
///   * Imprimir: diálogo del sistema, que incluye "Guardar como PDF".
///   * Guardar: copia en los documentos de la app.
///   * Compartir: el mismo ShareService de la pantalla principal.
///   * Formato: A4 / Carta (vuelve a llamar a `build` con el nuevo tamaño).
class VistaPreviaScreen extends StatelessWidget {
  const VistaPreviaScreen({
    super.key,
    required this.reporte,
    required this.incluirAnexo,
    required this.pdfService,
    required this.archivosService,
    required this.shareService,
  });

  final ReporteIa reporte;
  final bool incluirAnexo;
  final PdfService pdfService;
  final ArchivosService archivosService;
  final ShareService shareService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa del PDF')),
      body: PdfPreview(
        build: (formato) =>
            pdfService.generar(reporte, formato: formato, incluirAnexo: incluirAnexo),
        pdfFileName: reporte.nombreArchivo,
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const {'A4': PdfPageFormat.a4, 'Carta': PdfPageFormat.letter},
        canChangeOrientation: false,
        canDebug: false,
        // Compartimos con nuestro ShareService (acción propia) en vez del
        // botón integrado, para tener un solo punto de control.
        allowSharing: false,
        allowPrinting: true,
        actions: [
          PdfPreviewAction(icon: const Icon(Icons.save_alt), onPressed: _guardar),
          PdfPreviewAction(icon: const Icon(Icons.share), onPressed: _compartir),
        ],
        onPrinted: (context) => _mensaje(context, 'Documento enviado a impresión.'),
        onPrintError: (context, error) => _mensaje(context, 'Error al imprimir: $error'),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudo generar el PDF:\n$error', textAlign: TextAlign.center),
          ),
        ),
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Guarda el PDF (con el formato elegido en la vista previa) en la carpeta
  /// de documentos de la app. En iOS se ve en la app Archivos.
  Future<void> _guardar(BuildContext context, LayoutCallback build, PdfPageFormat formato) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final bytes = await build(formato);
      final archivo = await archivosService.guardarEnDocumentos(bytes, reporte.nombreArchivo);
      mensajero.showSnackBar(SnackBar(content: Text('PDF guardado en:\n${archivo.path}')));
    } on FileSystemException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text('No se pudo guardar: ${e.message}')));
    }
  }

  Future<void> _compartir(BuildContext context, LayoutCallback build, PdfPageFormat formato) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final bytes = await build(formato);
      await shareService.compartirPdf(
        bytes: bytes,
        nombreArchivo: reporte.nombreArchivo,
        asunto: reporte.titulo,
      );
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text('No se pudo compartir: $e')));
    }
  }

  void _mensaje(BuildContext context, String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}
