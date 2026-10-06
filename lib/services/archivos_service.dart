import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Escribe los bytes del PDF en disco usando las rutas de `path_provider`.
///
/// | Destino      | Directorio                         | Uso                       |
/// |--------------|------------------------------------|---------------------------|
/// | Temporal     | `getTemporaryDirectory()`          | Archivo para compartir.   |
/// |              | (Android: `cache/`)                | El SO puede borrarlo.     |
/// | Documentos   | `getApplicationDocumentsDirectory`| Copia persistente privada |
/// |              | (Android: `app_flutter/`)          | (iOS: visible en Archivos)|
///
/// Ninguno de los dos necesita permisos de almacenamiento.
class ArchivosService {
  const ArchivosService({
    this.directorioTemporal = getTemporaryDirectory,
    this.directorioDocumentos = getApplicationDocumentsDirectory,
  });

  /// Inyectables para poder probar el servicio sin plataforma real.
  final Future<Directory> Function() directorioTemporal;
  final Future<Directory> Function() directorioDocumentos;

  /// Subcarpeta propia dentro de la caché.
  ///
  /// Ojo: NO usar `cache/share_plus`. share_plus copia ahí los archivos que
  /// comparte y lanza una excepción si el original ya está en esa carpeta.
  static const _carpetaTemporal = 'reportes_compartidos';
  static const _carpetaDocumentos = 'reportes';

  /// Guarda el PDF en la caché de la app y devuelve el archivo creado.
  Future<File> guardarTemporal(Uint8List bytes, String nombreArchivo) async {
    final base = await directorioTemporal();
    return _escribir(Directory('${base.path}/$_carpetaTemporal'), nombreArchivo, bytes);
  }

  /// Guarda una copia persistente en los documentos privados de la app.
  Future<File> guardarEnDocumentos(Uint8List bytes, String nombreArchivo) async {
    final base = await directorioDocumentos();
    return _escribir(Directory('${base.path}/$_carpetaDocumentos'), nombreArchivo, bytes);
  }

  /// Borra los PDF temporales con más de [antiguedad]. Conviene llamarlo al
  /// iniciar la app para que la caché no crezca sin control.
  Future<int> limpiarTemporales({Duration antiguedad = const Duration(days: 1)}) async {
    final carpeta = Directory('${(await directorioTemporal()).path}/$_carpetaTemporal');
    if (!await carpeta.exists()) return 0;

    final limite = DateTime.now().subtract(antiguedad);
    var borrados = 0;
    await for (final entidad in carpeta.list()) {
      if (entidad is File && (await entidad.lastModified()).isBefore(limite)) {
        await entidad.delete();
        borrados++;
      }
    }
    return borrados;
  }

  /// Quita caracteres no válidos en nombres de archivo y asegura `.pdf`.
  static String nombreSeguro(String nombre) {
    final limpio = nombre.trim().replaceAll(RegExp(r'[^\w\-.]+'), '_');
    final base = limpio.isEmpty ? 'reporte' : limpio;
    return base.toLowerCase().endsWith('.pdf') ? base : '$base.pdf';
  }

  Future<File> _escribir(Directory carpeta, String nombre, Uint8List bytes) async {
    await carpeta.create(recursive: true);
    final archivo = File('${carpeta.path}/${nombreSeguro(nombre)}');
    // flush: true asegura que el archivo esté completo en disco antes de
    // entregarlo a otra app (evita PDFs "corruptos" o vacíos al compartir).
    return archivo.writeAsBytes(bytes, flush: true);
  }
}
