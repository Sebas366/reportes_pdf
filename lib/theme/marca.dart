/// Paleta de marca compartida entre la interfaz (Flutter) y el PDF.
///
/// Los colores se guardan como enteros ARGB (`0xAARRGGBB`) y no como `Color`
/// para poder convertirlos a los dos mundos sin duplicar valores:
///
/// * UI Flutter: `Color(Marca.primario)`
/// * PDF:        `PdfColor.fromInt(Marca.primario)`
///
/// Además este archivo no importa Flutter, así que puede usarse dentro del
/// isolate que genera el PDF.
abstract final class Marca {
  /// Nombre visible de la app (portada del PDF, AppBar, metadatos).
  static const String nombreApp = 'Reportes IA PDF';

  /// Índigo principal: cabeceras, títulos y barras del gráfico.
  static const int primario = 0xFF3949AB;

  /// Variante oscura del primario para fondos de portada.
  static const int primarioOscuro = 0xFF1A237E;

  /// Tinte suave del primario (texto sobre fondo oscuro, fondos de tarjetas).
  static const int primarioSuave = 0xFFC5CAE9;

  /// Verde azulado de acento: confianza alta, detalles del logo.
  static const int acento = 0xFF00897B;

  static const int texto = 0xFF1F2937;
  static const int textoSuave = 0xFF6B7280;
  static const int fondoSuave = 0xFFF3F4F6;
  static const int borde = 0xFFE5E7EB;

  /// Colores semánticos para la severidad de los hallazgos.
  static const int exito = 0xFF2E7D32;
  static const int alerta = 0xFFEF6C00;
  static const int peligro = 0xFFC62828;
}
