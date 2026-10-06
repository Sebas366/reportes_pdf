import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/reporte_ia.dart';
import '../../theme/marca.dart';
import 'pdf_componentes.dart';

/// Genera el PDF de un [ReporteIa] y devuelve sus bytes.
///
/// No sabe nada de pantallas, archivos ni de compartir: recibe datos y
/// devuelve `Uint8List`. Por eso se puede reutilizar tal cual en otro
/// proyecto (ver README, sección "Reutilizar el generador").
class PdfService {
  const PdfService();

  /// Construye el documento en un isolate secundario.
  ///
  /// Maquetar y comprimir un PDF de varias páginas es trabajo de CPU que puede
  /// tardar cientos de milisegundos; en el isolate principal congelaría la UI
  /// (el indicador de carga dejaría de girar).
  ///
  /// [formato] llega desde `PdfPreview` cuando el usuario cambia A4/Carta.
  Future<Uint8List> generar(
    ReporteIa reporte, {
    PdfPageFormat formato = PdfPageFormat.a4,
    bool incluirAnexo = true,
  }) async {
    // rootBundle solo está disponible en el isolate principal: leemos los
    // bytes de las fuentes aquí y los enviamos al otro isolate.
    final fuentes = await FuentesPdf.cargar();
    return Isolate.run(
      () => construirDocumento(
        reporte,
        fuentes: fuentes,
        formato: formato,
        incluirAnexo: incluirAnexo,
      ),
    );
  }

  /// Arma el documento completo. Es estático para que la clausura que va al
  /// isolate no capture objetos que no se puedan enviar entre isolates.
  static Future<Uint8List> construirDocumento(
    ReporteIa reporte, {
    required FuentesPdf fuentes,
    PdfPageFormat formato = PdfPageFormat.a4,
    bool incluirAnexo = true,
  }) {
    // 1. Tema: fuentes TTF embebidas => tildes, ñ y ¿¡ se ven en cualquier
    //    visor. Las 14 fuentes estándar del PDF (Helvetica...) no son Unicode.
    final tema = pw.ThemeData.withFont(
      base: fuentes.regularFont,
      bold: fuentes.negritaFont,
      italic: fuentes.cursivaFont,
    );

    // 2. Documento con metadatos (visibles en "Propiedades" del visor).
    final documento = pw.Document(
      title: reporte.titulo,
      author: Marca.nombreApp,
      subject: reporte.subtitulo,
      keywords: 'IA, reporte, ${reporte.modelo}',
      creator: 'Flutter + paquete pdf',
      producer: 'reportes_pdf_ia',
    );

    final c = ComponentesPdf(reporte, fuenteMono: fuentes.monoFont);
    final anexo = reporte.anexo;

    // 3. MultiPage: reparte el contenido en tantas páginas como haga falta.
    //    Encabezado y pie se repiten en cada hoja; las tablas se parten solas
    //    y repiten su fila de títulos.
    documento.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: formato,
          margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 28),
          theme: tema,
        ),
        header: c.encabezado,
        footer: c.piePagina,
        build: (context) => [
          c.portada(),
          c.tituloSeccion('Resumen ejecutivo'),
          c.resumen(),
          c.tituloSeccion('Indicadores clave'),
          c.indicadores(),
          c.tituloSeccion(reporte.grafico.titulo),
          c.grafico(),
          c.tituloSeccion('Hallazgos'),
          c.tablaHallazgos(),
          c.tituloSeccion('Recomendaciones'),
          ...c.recomendaciones(),
          c.trazabilidad(),
          if (incluirAnexo && anexo != null) ...[
            pw.NewPage(),
            c.tituloSeccion(anexo.titulo),
            c.tablaAnexo(anexo),
          ],
        ],
      ),
    );

    // 4. Serializa a bytes (%PDF-1.x ... %%EOF).
    return documento.save();
  }
}

/// Bytes de las fuentes TTF que se embeben en el PDF.
///
/// Se guardan como [Uint8List] (y no como `pw.Font`) porque los bytes sí se
/// pueden enviar a otro isolate.
class FuentesPdf {
  const FuentesPdf({
    required this.regular,
    required this.negrita,
    required this.cursiva,
    required this.mono,
  });

  final Uint8List regular;
  final Uint8List negrita;
  final Uint8List cursiva;
  final Uint8List mono;

  static FuentesPdf? _cache;

  /// Lee las fuentes de los assets una sola vez y las deja en memoria.
  static Future<FuentesPdf> cargar() async => _cache ??= FuentesPdf(
    regular: await _leer('NotoSans-Regular.ttf'),
    negrita: await _leer('NotoSans-Bold.ttf'),
    cursiva: await _leer('NotoSans-Italic.ttf'),
    mono: await _leer('NotoSansMono-Regular.ttf'),
  );

  static Future<Uint8List> _leer(String archivo) async {
    final datos = await rootBundle.load('assets/fonts/$archivo');
    return datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes);
  }

  pw.Font get regularFont => pw.Font.ttf(ByteData.sublistView(regular));
  pw.Font get negritaFont => pw.Font.ttf(ByteData.sublistView(negrita));
  pw.Font get cursivaFont => pw.Font.ttf(ByteData.sublistView(cursiva));
  pw.Font get monoFont => pw.Font.ttf(ByteData.sublistView(mono));
}
