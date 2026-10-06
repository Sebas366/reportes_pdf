import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

import 'archivos_service.dart';

/// Abre el menú Compartir nativo con un PDF.
///
/// Flujo: bytes del PDF → archivo temporal → `SharePlus.instance.share()`
/// → MethodChannel `dev.fluttercommunity.plus/share` →
/// Android: `Intent.ACTION_SEND` + `Intent.createChooser` (URI content://)
/// iOS: `UIActivityViewController`.
///
/// Nota de versiones: desde share_plus 11, `Share.shareXFiles()` está
/// deprecado; la API actual es `SharePlus.instance.share(ShareParams(...))`.
class ShareService {
  ShareService({this.archivos = const ArchivosService(), SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  /// Dónde se escribe el archivo temporal que se va a compartir.
  final ArchivosService archivos;
  final SharePlus _sharePlus;

  /// Comparte [bytes] como un PDF llamado [nombreArchivo].
  ///
  /// * [asunto]: se usa como asunto si el usuario elige un correo.
  /// * [texto]: mensaje que acompaña al archivo (WhatsApp, Telegram...).
  /// * [origen]: rectángulo del botón pulsado; en iPad el menú aparece como
  ///   un popover anclado a ese botón.
  ///
  /// Devuelve [ShareResult]: `success`, `dismissed` o `unavailable`.
  Future<ShareResult> compartirPdf({
    required Uint8List bytes,
    required String nombreArchivo,
    String? asunto,
    String? texto,
    Rect? origen,
  }) async {
    // 1. Los otros procesos no pueden leer memoria de nuestra app: el PDF
    //    debe existir como archivo para que el sistema lo entregue.
    final archivo = await archivos.guardarTemporal(bytes, nombreArchivo);

    // 2. El tipo MIME explícito evita que Android lo trate como "*/*" y
    //    filtra el menú a apps que realmente abren PDF.
    final params = ShareParams(
      files: [XFile(archivo.path, mimeType: 'application/pdf')],
      title: 'Compartir reporte', // Título del selector en Android.
      subject: asunto,
      text: texto,
      sharePositionOrigin: origen,
    );

    // 3. Abre la hoja nativa y espera a que el usuario elija o cancele.
    return _sharePlus.share(params);
  }
}
