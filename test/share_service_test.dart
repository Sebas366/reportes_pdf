import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_pdf_ia/services/archivos_service.dart';
import 'package:reportes_pdf_ia/services/share_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// Plataforma falsa: en vez de abrir el menú nativo, guarda lo que recibió.
class _PlataformaFalsa extends SharePlatform {
  _PlataformaFalsa(this.respuesta);

  final ShareResult respuesta;
  ShareParams? recibido;

  @override
  Future<ShareResult> share(ShareParams params) async {
    recibido = params;
    return respuesta;
  }
}

void main() {
  late Directory carpeta;
  late ArchivosService archivos;
  final pdf = Uint8List.fromList('%PDF-1.4 prueba %%EOF'.codeUnits);

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('reportes_pdf_ia_test');
    archivos = ArchivosService(
      directorioTemporal: () async => carpeta,
      directorioDocumentos: () async => carpeta,
    );
  });

  tearDown(() => carpeta.delete(recursive: true));

  group('ShareService', () {
    test('escribe el PDF temporal y lo comparte como application/pdf', () async {
      final plataforma = _PlataformaFalsa(
        const ShareResult('com.google.android.gm', ShareResultStatus.success),
      );
      final servicio = ShareService(archivos: archivos, sharePlus: SharePlus.custom(plataforma));

      final resultado = await servicio.compartirPdf(
        bytes: pdf,
        nombreArchivo: 'reporte demo.pdf',
        asunto: 'Reporte IA',
        texto: 'Adjunto el reporte',
      );

      expect(resultado.status, ShareResultStatus.success);
      final params = plataforma.recibido!;
      final archivo = params.files!.single;
      expect(archivo.mimeType, 'application/pdf');
      expect(archivo.path, endsWith('reportes_compartidos/reporte_demo.pdf'));
      expect(await File(archivo.path).readAsBytes(), pdf);
      expect(params.subject, 'Reporte IA');
      expect(params.text, 'Adjunto el reporte');
    });

    test('propaga cuando el usuario cierra el menú', () async {
      final plataforma = _PlataformaFalsa(const ShareResult('', ShareResultStatus.dismissed));
      final servicio = ShareService(archivos: archivos, sharePlus: SharePlus.custom(plataforma));

      final resultado = await servicio.compartirPdf(bytes: pdf, nombreArchivo: 'x.pdf');
      expect(resultado.status, ShareResultStatus.dismissed);
    });
  });

  group('ArchivosService', () {
    test('nombreSeguro limpia caracteres y agrega .pdf', () {
      expect(ArchivosService.nombreSeguro('Reporte final: v2'), 'Reporte_final_v2.pdf');
      expect(ArchivosService.nombreSeguro('ok.pdf'), 'ok.pdf');
      expect(ArchivosService.nombreSeguro('   '), 'reporte.pdf');
    });

    test('guardarEnDocumentos crea la subcarpeta reportes', () async {
      final archivo = await archivos.guardarEnDocumentos(pdf, 'a.pdf');
      expect(archivo.path, endsWith('reportes/a.pdf'));
      expect(archivo.existsSync(), isTrue);
    });

    test('limpiarTemporales borra solo los archivos viejos', () async {
      final viejo = await archivos.guardarTemporal(pdf, 'viejo.pdf');
      final nuevo = await archivos.guardarTemporal(pdf, 'nuevo.pdf');
      viejo.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 3)));

      final borrados = await archivos.limpiarTemporales();

      expect(borrados, 1);
      expect(viejo.existsSync(), isFalse);
      expect(nuevo.existsSync(), isTrue);
    });
  });
}
