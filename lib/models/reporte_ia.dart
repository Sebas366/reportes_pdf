import 'dart:convert';
import 'dart:math' as math;

import '../utils/formato.dart';

/// Reporte estructurado que devuelve el modelo de IA.
///
/// Es el "contrato" entre el LLM y el generador de PDF: el modelo responde
/// un JSON con esta forma, [ReporteIa.desdeTextoLlm] lo valida y lo convierte
/// en objetos Dart, y `PdfService` solo dibuja lo que hay aquí.
///
/// Es Dart puro (sin Flutter) para poder enviarlo a otro isolate.
class ReporteIa {
  /// Identificador único; se usa en el nombre del archivo y en el QR.
  final String id;
  final String titulo;
  final String subtitulo;

  /// Nombre del modelo que generó el contenido (trazabilidad).
  final String modelo;

  /// Prompt exacto enviado al modelo (trazabilidad / auditoría).
  final String prompt;
  final DateTime generadoEn;

  /// Confianza global declarada por el modelo, normalizada a 0..1.
  final double confianza;

  /// Resumen ejecutivo en lenguaje natural.
  final String resumen;
  final List<Metrica> metricas;
  final GraficoReporte grafico;
  final List<Hallazgo> hallazgos;
  final List<String> recomendaciones;

  /// Tabla larga opcional; en el PDF ocupa varias páginas.
  final TablaAnexo? anexo;

  const ReporteIa({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.modelo,
    required this.prompt,
    required this.generadoEn,
    required this.confianza,
    required this.resumen,
    required this.metricas,
    required this.grafico,
    required this.hallazgos,
    required this.recomendaciones,
    this.anexo,
  });

  /// Convierte el texto crudo del LLM en un [ReporteIa] validado.
  ///
  /// Lanza [FormatException] con un mensaje claro si la respuesta no sirve.
  /// Nunca hay que confiar ciegamente en la salida de un modelo.
  static ReporteIa desdeTextoLlm(String texto) {
    // Aunque se les pida "solo JSON", los LLM suelen envolverlo en ```json.
    final limpio = texto
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');

    final Object? datos;
    try {
      datos = jsonDecode(limpio);
    } on FormatException catch (e) {
      throw FormatException('La IA no devolvió JSON válido: ${e.message}');
    }
    if (datos is! Map<String, dynamic>) {
      throw const FormatException('Se esperaba un objeto JSON en la raíz.');
    }
    return ReporteIa.fromJson(datos);
  }

  factory ReporteIa.fromJson(Map<String, dynamic> json) {
    final anexo = json['anexo'];
    return ReporteIa(
      id: _texto(json, 'id'),
      titulo: _texto(json, 'titulo'),
      subtitulo: json['subtitulo']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? 'desconocido',
      prompt: json['prompt']?.toString() ?? '',
      generadoEn: DateTime.tryParse(json['generado_en']?.toString() ?? '') ?? DateTime.now(),
      confianza: _proporcion(json['confianza']),
      resumen: _texto(json, 'resumen'),
      metricas: _objetos(json, 'metricas').map(Metrica.fromJson).toList(),
      grafico: GraficoReporte.fromJson(json['grafico'] as Map<String, dynamic>? ?? const {}),
      hallazgos: _objetos(json, 'hallazgos').map(Hallazgo.fromJson).toList(),
      recomendaciones: (json['recomendaciones'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      anexo: anexo is Map<String, dynamic> ? TablaAnexo.fromJson(anexo) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'subtitulo': subtitulo,
    'modelo': modelo,
    'prompt': prompt,
    'generado_en': generadoEn.toIso8601String(),
    'confianza': confianza,
    'resumen': resumen,
    'metricas': metricas.map((m) => m.toJson()).toList(),
    'grafico': grafico.toJson(),
    'hallazgos': hallazgos.map((h) => h.toJson()).toList(),
    'recomendaciones': recomendaciones,
    if (anexo != null) 'anexo': anexo!.toJson(),
  };

  /// Nombre de archivo seguro para el sistema: `reporte_rpt-20261005-sen.pdf`.
  String get nombreArchivo =>
      'reporte_${id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_')}.pdf';
}

/// Indicador clave (KPI) con su variación frente al periodo anterior.
class Metrica {
  final String etiqueta;
  final double valor;

  /// Unidad mostrada junto al valor: `%`, `min`, `/5`, `h`...
  final String unidad;

  /// Cambio frente al periodo anterior (puede ser nulo).
  final double? variacion;

  /// `true` cuando bajar es bueno (p. ej. tiempo de espera, riesgos).
  final bool menorEsMejor;

  const Metrica({
    required this.etiqueta,
    required this.valor,
    this.unidad = '',
    this.variacion,
    this.menorEsMejor = false,
  });

  factory Metrica.fromJson(Map<String, dynamic> json) => Metrica(
    etiqueta: _texto(json, 'etiqueta'),
    valor: _numero(json, 'valor'),
    unidad: json['unidad']?.toString() ?? '',
    variacion: (json['variacion'] as num?)?.toDouble(),
    menorEsMejor: json['menor_es_mejor'] == true,
  );

  Map<String, dynamic> toJson() => {
    'etiqueta': etiqueta,
    'valor': valor,
    'unidad': unidad,
    'variacion': variacion,
    'menor_es_mejor': menorEsMejor,
  };

  /// `78 %`, `6,8 min`, `4,1/5`.
  String get valorFormateado => Formato.conUnidad(valor, unidad);

  /// `true` si mejoró, `false` si empeoró, `null` si no hay variación.
  bool? get esMejora {
    final v = variacion;
    if (v == null || v == 0) return null;
    return (v > 0) != menorEsMejor;
  }
}

/// Serie de datos para el gráfico de barras.
class GraficoReporte {
  final String titulo;
  final String unidad;
  final List<PuntoGrafico> puntos;

  const GraficoReporte({required this.titulo, required this.puntos, this.unidad = ''});

  factory GraficoReporte.fromJson(Map<String, dynamic> json) => GraficoReporte(
    titulo: json['titulo']?.toString() ?? 'Distribución',
    unidad: json['unidad']?.toString() ?? '',
    puntos: _objetos(json, 'puntos').map(PuntoGrafico.fromJson).toList(),
  );

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'unidad': unidad,
    'puntos': puntos.map((p) => p.toJson()).toList(),
  };

  /// Valor máximo de la serie (mínimo 1 para evitar divisiones por cero).
  double get maximo => puntos.fold<double>(1, (m, p) => p.valor > m ? p.valor : m);

  /// Valor "redondo" para el tope del eje: 4,5 → 5 · 14 → 20 · 81 → 100.
  double get techo {
    final m = maximo;
    if (m <= 5) return 5;
    if (m <= 10) return 10;
    final magnitud = math.pow(10, (math.log(m) / math.ln10).floor()).toDouble();
    for (final factor in const [1, 2, 2.5, 5, 10]) {
      if (factor * magnitud >= m) return factor * magnitud;
    }
    return 10 * magnitud;
  }

  /// Decimales comunes a toda la serie (4 → `4,0` si otra barra es `4,5`).
  int get decimales => puntos.any((p) => p.valor % 1 != 0) ? 1 : 0;
}

class PuntoGrafico {
  final String etiqueta;
  final double valor;

  const PuntoGrafico({required this.etiqueta, required this.valor});

  factory PuntoGrafico.fromJson(Map<String, dynamic> json) =>
      PuntoGrafico(etiqueta: _texto(json, 'etiqueta'), valor: _numero(json, 'valor'));

  Map<String, dynamic> toJson() => {'etiqueta': etiqueta, 'valor': valor};
}

/// Nivel de prioridad de un hallazgo.
enum Severidad {
  alta('Alta'),
  media('Media'),
  baja('Baja');

  const Severidad(this.etiqueta);
  final String etiqueta;

  /// Tolerante a mayúsculas, tildes y respuestas en inglés del modelo.
  static Severidad desdeTexto(Object? valor) => switch (valor?.toString().trim().toLowerCase()) {
    'alta' || 'high' || 'critica' || 'crítica' => Severidad.alta,
    'media' || 'medium' || 'moderada' => Severidad.media,
    _ => Severidad.baja,
  };
}

/// Observación concreta detectada por la IA.
class Hallazgo {
  final String categoria;
  final String descripcion;
  final Severidad severidad;

  /// Confianza del modelo en este hallazgo (0..1).
  final double confianza;

  const Hallazgo({
    required this.categoria,
    required this.descripcion,
    required this.severidad,
    required this.confianza,
  });

  factory Hallazgo.fromJson(Map<String, dynamic> json) => Hallazgo(
    categoria: _texto(json, 'categoria'),
    descripcion: _texto(json, 'descripcion'),
    severidad: Severidad.desdeTexto(json['severidad']),
    confianza: _proporcion(json['confianza']),
  );

  Map<String, dynamic> toJson() => {
    'categoria': categoria,
    'descripcion': descripcion,
    'severidad': severidad.name,
    'confianza': confianza,
  };
}

/// Tabla de detalle (registros analizados, transcripción, etc.).
class TablaAnexo {
  final String titulo;
  final List<String> columnas;
  final List<List<String>> filas;

  const TablaAnexo({required this.titulo, required this.columnas, required this.filas});

  factory TablaAnexo.fromJson(Map<String, dynamic> json) => TablaAnexo(
    titulo: json['titulo']?.toString() ?? 'Anexo',
    columnas: (json['columnas'] as List? ?? const []).map((e) => e.toString()).toList(),
    filas: (json['filas'] as List? ?? const [])
        .whereType<List>()
        .map((fila) => fila.map((celda) => celda.toString()).toList())
        .toList(),
  );

  Map<String, dynamic> toJson() => {'titulo': titulo, 'columnas': columnas, 'filas': filas};
}

// --- Validación de la respuesta del modelo --------------------------------

String _texto(Map<String, dynamic> json, String clave) {
  final valor = json[clave];
  if (valor is String && valor.trim().isNotEmpty) return valor.trim();
  throw FormatException('Falta el campo de texto "$clave" en la respuesta.');
}

double _numero(Map<String, dynamic> json, String clave) {
  final valor = json[clave];
  if (valor is num) return valor.toDouble();
  // Algunos modelos devuelven números como texto y con coma decimal.
  final convertido = double.tryParse(valor?.toString().replaceAll(',', '.') ?? '');
  if (convertido != null) return convertido;
  throw FormatException('El campo "$clave" debe ser numérico (llegó: $valor).');
}

/// Acepta `0.92` o `92` y siempre devuelve un valor entre 0 y 1.
double _proporcion(Object? valor) {
  final numero = valor is num ? valor.toDouble() : 0.0;
  return (numero > 1 ? numero / 100 : numero).clamp(0.0, 1.0);
}

List<Map<String, dynamic>> _objetos(Map<String, dynamic> json, String clave) =>
    (json[clave] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
