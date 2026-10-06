/// Utilidades de formato en español (Colombia) sin depender de `intl`.
///
/// Se usan tanto en la UI como en el PDF, por eso no importan Flutter.
abstract final class Formato {
  static const List<String> _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// `2026-10-05 14:07` → `5 oct 2026, 14:07`
  static String fechaHora(DateTime fecha) =>
      '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}, '
      '${_dosDigitos(fecha.hour)}:${_dosDigitos(fecha.minute)}';

  /// Número con coma decimal y punto de miles: `1250.5` → `1.250,5`.
  static String numero(num valor, {int decimales = 1}) {
    final texto = valor.toStringAsFixed(decimales);
    final partes = texto.split('.');
    final entero = partes[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return partes.length == 1 || decimales == 0 ? entero : '$entero,${partes[1]}';
  }

  /// Número con su unidad: `78, '%'` → `78 %` · `4.1, '/5'` → `4,1/5`.
  ///
  /// Si no se indica [decimales], usa 0 para enteros y 1 para el resto.
  static String conUnidad(num valor, String unidad, {int? decimales}) {
    final texto = numero(valor, decimales: decimales ?? (valor % 1 == 0 ? 0 : 1));
    if (unidad.isEmpty) return texto;
    return unidad.startsWith('/') ? '$texto$unidad' : '$texto $unidad';
  }

  /// Proporción 0..1 → porcentaje entero: `0.92` → `92 %`.
  static String porcentaje(double proporcion) => '${(proporcion * 100).round()} %';

  /// Variación con signo explícito: `4.2` → `+4,2`, `-1` → `-1`.
  static String variacion(double valor) =>
      '${valor >= 0 ? '+' : '-'}${numero(valor.abs(), decimales: valor % 1 == 0 ? 0 : 1)}';

  static String _dosDigitos(int n) => n.toString().padLeft(2, '0');
}
