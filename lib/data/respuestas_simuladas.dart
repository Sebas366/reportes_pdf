import 'dart:convert';
import 'dart:math';

import '../models/escenario.dart';

/// Respuestas de ejemplo con el mismo formato que devolvería un LLM real.
///
/// Permiten hacer la demo sin internet ni API key. Los anexos se generan
/// con una semilla fija para que el PDF salga idéntico en cada ensayo.
abstract final class RespuestasSimuladas {
  /// Texto crudo (tal cual "lo escribe" el modelo) para un [escenario].
  static String para(Escenario escenario, {required DateTime fecha}) {
    final json = const JsonEncoder.withIndent('  ');
    return switch (escenario) {
      Escenario.sentimientoClientes => json.convert(_sentimiento(fecha)),
      Escenario.rendimientoAcademico => json.convert(_academico(fecha)),
      // Este caso imita un error frecuente: el LLM envuelve el JSON en un
      // bloque de código Markdown. ReporteIa.desdeTextoLlm lo limpia.
      Escenario.resumenReunion => '```json\n${json.convert(_reunion(fecha))}\n```',
    };
  }

  static String _id(DateTime f, String sufijo) =>
      'RPT-${f.year}${_dos(f.month)}${_dos(f.day)}-$sufijo';

  static String _dos(int n) => n.toString().padLeft(2, '0');

  // ---------------------------------------------------------------------
  // 1. Sentimiento de clientes (call center)
  // ---------------------------------------------------------------------
  static Map<String, dynamic> _sentimiento(DateTime fecha) => {
    'id': _id(fecha, 'SEN'),
    'titulo': 'Análisis de sentimiento de clientes',
    'subtitulo': 'Call center · 1.250 interacciones · septiembre 2026',
    'modelo': 'gemini-2.5-flash (simulado)',
    'prompt': Escenario.sentimientoClientes.prompt,
    'generado_en': fecha.toIso8601String(),
    'confianza': 0.91,
    'resumen':
        'El 64 % de las interacciones fue positivo, el 21 % neutro y el 15 % '
        'negativo. La satisfacción subió 4,2 puntos frente a agosto, impulsada '
        'por el chat en línea. Los comentarios negativos se concentran en el '
        'tiempo de espera telefónico (6,8 min en promedio) y en cobros '
        'duplicados tras la migración del sistema de facturación. Se '
        'recomienda reforzar la línea telefónica en horas pico y auditar el '
        'proceso de facturación.',
    'metricas': [
      {'etiqueta': 'Satisfacción (CSAT)', 'valor': 78, 'unidad': '%', 'variacion': 4.2},
      {'etiqueta': 'Sentimiento positivo', 'valor': 64, 'unidad': '%', 'variacion': 3.1},
      {
        'etiqueta': 'Espera promedio',
        'valor': 6.8,
        'unidad': 'min',
        'variacion': 1.4,
        'menor_es_mejor': true,
      },
      {'etiqueta': 'NPS', 'valor': 41, 'unidad': 'pts', 'variacion': 5},
    ],
    'grafico': {
      'titulo': 'Sentimiento positivo por canal',
      'unidad': '%',
      'puntos': [
        {'etiqueta': 'Chat', 'valor': 81},
        {'etiqueta': 'Correo', 'valor': 66},
        {'etiqueta': 'Redes', 'valor': 58},
        {'etiqueta': 'Teléfono', 'valor': 49},
      ],
    },
    'hallazgos': [
      {
        'categoria': 'Tiempo de espera',
        'descripcion':
            'El 38 % de los comentarios negativos menciona esperas de más de '
            '5 minutos en la línea telefónica entre las 9:00 y las 11:00.',
        'severidad': 'alta',
        'confianza': 0.93,
      },
      {
        'categoria': 'Facturación',
        'descripcion':
            '57 quejas por cobros duplicados después de la migración del '
            'sistema de facturación del 12 de septiembre.',
        'severidad': 'alta',
        'confianza': 0.88,
      },
      {
        'categoria': 'Redes sociales',
        'descripcion':
            'Aumentan las menciones por falta de respuesta durante los fines '
            'de semana (+22 % frente a agosto).',
        'severidad': 'media',
        'confianza': 0.76,
      },
      {
        'categoria': 'Chat en línea',
        'descripcion':
            'Es el canal mejor valorado: los usuarios destacan la rapidez y el '
            'resumen que reciben por correo al cerrar el caso.',
        'severidad': 'baja',
        'confianza': 0.90,
      },
    ],
    'recomendaciones': [
      'Asignar dos agentes adicionales a la línea telefónica de 9:00 a 11:00.',
      'Auditar los cobros duplicados y enviar una disculpa proactiva con el reembolso.',
      'Activar respuestas automáticas con IA en redes sociales durante el fin de semana.',
      'Replicar en los demás canales el resumen por correo que se usa en el chat.',
    ],
    'anexo': {
      'titulo': 'Anexo A · Muestra de interacciones clasificadas por la IA',
      'columnas': ['#', 'Fecha', 'Canal', 'Comentario', 'Sentimiento', 'Puntaje'],
      'filas': _filasSentimiento(),
    },
  };

  static List<List<String>> _filasSentimiento() {
    const comentarios = [
      ('Me resolvieron el problema en el chat en menos de 5 minutos.', 'Positivo', 0.94),
      ('Excelente atención, el agente fue muy amable y claro.', 'Positivo', 0.92),
      ('Llevo 20 minutos en espera y nadie contesta.', 'Negativo', 0.12),
      ('Me cobraron dos veces la factura de septiembre.', 'Negativo', 0.08),
      ('La información fue correcta, aunque tardaron un poco.', 'Neutro', 0.55),
      ('Gracias por el resumen que me enviaron al correo.', 'Positivo', 0.88),
      ('Escribí por Instagram el sábado y no hubo respuesta.', 'Negativo', 0.21),
      ('Necesito saber el estado de mi solicitud de cambio de plan.', 'Neutro', 0.50),
      ('El nuevo portal es más fácil de usar que el anterior.', 'Positivo', 0.81),
      ('Me transfirieron tres veces entre áreas distintas.', 'Negativo', 0.18),
      ('Solucionaron el cobro duplicado y me devolvieron el dinero.', 'Positivo', 0.79),
      ('Quisiera actualizar mis datos de contacto.', 'Neutro', 0.52),
      ('El técnico llegó a tiempo y explicó todo muy bien.', 'Positivo', 0.90),
      ('La llamada se cortó y tuve que empezar de nuevo.', 'Negativo', 0.15),
    ];
    const canales = ['Chat', 'Teléfono', 'Correo', 'Redes'];
    final azar = Random(2026);
    return List.generate(42, (i) {
      final (texto, sentimiento, puntaje) = comentarios[azar.nextInt(comentarios.length)];
      final dia = 1 + azar.nextInt(30);
      return [
        '${i + 1}',
        '${_dos(dia)}/09/2026',
        canales[azar.nextInt(canales.length)],
        texto,
        sentimiento,
        puntaje.toStringAsFixed(2).replaceAll('.', ','),
      ];
    });
  }

  // ---------------------------------------------------------------------
  // 2. Rendimiento académico (StudyBuddy IA)
  // ---------------------------------------------------------------------
  static Map<String, dynamic> _academico(DateTime fecha) => {
    'id': _id(fecha, 'ACA'),
    'titulo': 'Diagnóstico de rendimiento académico',
    'subtitulo': 'StudyBuddy IA · Semestre 2026-2 · primer corte',
    'modelo': 'gemini-2.5-flash (simulado)',
    'prompt': Escenario.rendimientoAcademico.prompt,
    'generado_en': fecha.toIso8601String(),
    'confianza': 0.87,
    'resumen':
        'El promedio proyectado es 4,1/5, tres décimas más que el corte '
        'anterior. Dispositivos Móviles y UX muestran un desempeño sólido y '
        'constante. Ingeniería Legal es la asignatura en riesgo: los quizzes '
        'de nómina y liquidación tienen solo 52 % de aciertos. El 70 % del '
        'estudio ocurre después de las 22:00, lo que coincide con los peores '
        'resultados en los quizzes.',
    'metricas': [
      {'etiqueta': 'Promedio proyectado', 'valor': 4.1, 'unidad': '/5', 'variacion': 0.3},
      {'etiqueta': 'Horas de estudio', 'valor': 46, 'unidad': 'h', 'variacion': 8},
      {'etiqueta': 'Quizzes aprobados', 'valor': 82, 'unidad': '%', 'variacion': 6},
      {'etiqueta': 'Asignaturas en riesgo', 'valor': 1, 'variacion': -1, 'menor_es_mejor': true},
    ],
    'grafico': {
      'titulo': 'Nota proyectada por asignatura',
      'unidad': '/5',
      'puntos': [
        {'etiqueta': 'Móviles', 'valor': 4.5},
        {'etiqueta': 'UX', 'valor': 4.2},
        {'etiqueta': 'Telemát.', 'valor': 4.0},
        {'etiqueta': 'Redes', 'valor': 3.9},
        {'etiqueta': 'BI', 'valor': 3.6},
        {'etiqueta': 'Legal', 'valor': 3.2},
      ],
    },
    'hallazgos': [
      {
        'categoria': 'Ingeniería Legal',
        'descripcion':
            'Bajo desempeño en cálculos de nómina, horas extra y liquidación '
            '(52 % de aciertos en los quizzes).',
        'severidad': 'alta',
        'confianza': 0.87,
      },
      {
        'categoria': 'Inteligencia de Negocios',
        'descripcion':
            'Confusión entre granularidad y dimensiones al diseñar el modelo '
            'estrella del Taller 2.',
        'severidad': 'media',
        'confianza': 0.81,
      },
      {
        'categoria': 'Hábitos de estudio',
        'descripcion':
            'El 70 % de las sesiones empieza después de las 22:00 y dura más '
            'de 2 horas sin pausas.',
        'severidad': 'media',
        'confianza': 0.74,
      },
      {
        'categoria': 'Dispositivos Móviles',
        'descripcion': 'Constancia alta: entregas a tiempo y práctica semanal con Flutter.',
        'severidad': 'baja',
        'confianza': 0.92,
      },
    ],
    'recomendaciones': [
      'Resolver 3 ejercicios de nómina por semana con la tabla de recargos a la vista.',
      'Repasar granularidad con un ejemplo de ventas antes del examen práctico de BI.',
      'Mover el estudio a bloques Pomodoro antes de las 21:00.',
      'Mantener el ritmo en Móviles y documentar el repositorio de la exposición.',
    ],
    'anexo': {
      'titulo': 'Anexo A · Sesiones de estudio analizadas',
      'columnas': ['Fecha', 'Asignatura', 'Actividad', 'Minutos', 'Quiz'],
      'filas': _filasAcademico(),
    },
  };

  static List<List<String>> _filasAcademico() {
    const asignaturas = [
      ('Móviles', ['Live coding Flutter', 'Lectura de documentación', 'Práctica con paquetes']),
      ('UX', ['Informe SUS', 'Mapeo de entrevista', 'Prototipo']),
      ('BI', ['Transformación en Pentaho', 'Consultas SQL', 'Modelo estrella']),
      ('Redes', ['Packet Tracer VLSM', 'Módulo CCNA', 'Subnetting']),
      ('Telemáticos', ['Servidor DNS (BIND9)', 'Configuración DHCP', 'Docker']),
      ('Legal', ['Ejercicios de nómina', 'Horas extra y recargos', 'Lectura Ley 2466']),
    ];
    final azar = Random(7);
    return List.generate(36, (i) {
      final (asignatura, actividades) = asignaturas[azar.nextInt(asignaturas.length)];
      final nota = asignatura == 'Legal'
          ? 2.6 + azar.nextDouble() * 1.2
          : 3.5 + azar.nextDouble() * 1.5;
      return [
        '${_dos(1 + i % 28)}/${i < 28 ? '09' : '10'}/2026',
        asignatura,
        actividades[azar.nextInt(actividades.length)],
        '${30 + azar.nextInt(10) * 10}',
        nota.toStringAsFixed(1).replaceAll('.', ','),
      ];
    });
  }

  // ---------------------------------------------------------------------
  // 3. Resumen de reunión (transcripción de audio)
  // ---------------------------------------------------------------------
  static Map<String, dynamic> _reunion(DateTime fecha) => {
    'id': _id(fecha, 'REU'),
    'titulo': 'Resumen de reunión: seguimiento del proyecto final',
    'subtitulo': 'Transcripción de 45 min · 4 participantes · 3 oct 2026',
    'modelo': 'gemini-2.5-flash (simulado)',
    'prompt': Escenario.resumenReunion.prompt,
    'generado_en': fecha.toIso8601String(),
    'confianza': 0.84,
    'resumen':
        'El equipo validó el alcance del MVP: login, registro de apuntes y '
        'resumen automático con IA. Se decidió generar los reportes PDF en el '
        'dispositivo para no depender del backend. El principal riesgo es el '
        'límite de solicitudes de la API del modelo; se acordó usar caché '
        'local y reintentos con espera exponencial. Quedan 7 compromisos con '
        'responsable y fecha.',
    'metricas': [
      {'etiqueta': 'Duración', 'valor': 45, 'unidad': 'min'},
      {'etiqueta': 'Decisiones', 'valor': 5},
      {'etiqueta': 'Compromisos', 'valor': 7},
      {'etiqueta': 'Riesgos abiertos', 'valor': 3, 'variacion': -2, 'menor_es_mejor': true},
    ],
    'grafico': {
      'titulo': 'Participación por persona',
      'unidad': 'min',
      'puntos': [
        {'etiqueta': 'Ana', 'valor': 14},
        {'etiqueta': 'Carla', 'valor': 12},
        {'etiqueta': 'Bruno', 'valor': 11},
        {'etiqueta': 'David', 'valor': 8},
      ],
    },
    'hallazgos': [
      {
        'categoria': 'Riesgo',
        'descripcion':
            'La API del modelo limita las solicitudes por minuto; en la demo '
            'con 30 usuarios podría responder con error 429.',
        'severidad': 'alta',
        'confianza': 0.86,
      },
      {
        'categoria': 'Decisión',
        'descripcion':
            'Los reportes PDF se generan en el cliente con el paquete pdf y se '
            'comparten con share_plus.',
        'severidad': 'baja',
        'confianza': 0.95,
      },
      {
        'categoria': 'Compromiso',
        'descripcion': 'Bruno entrega el módulo de autenticación el 10 de octubre.',
        'severidad': 'media',
        'confianza': 0.90,
      },
      {
        'categoria': 'Riesgo',
        'descripcion': 'No hay pruebas automatizadas del parser de respuestas del modelo.',
        'severidad': 'media',
        'confianza': 0.79,
      },
    ],
    'recomendaciones': [
      'Ana: implementar caché local y reintentos con espera exponencial (8 oct).',
      'Carla: escribir pruebas unitarias del parser JSON del modelo (9 oct).',
      'David: preparar el guion de la demo y el README del repositorio (12 oct).',
      'Todos: ensayo general con el emulador el 13 de octubre a las 18:00.',
    ],
    'anexo': {
      'titulo': 'Anexo A · Transcripción segmentada',
      'columnas': ['Min', 'Participante', 'Intervención'],
      'filas': [
        ['00:00', 'Ana', 'Abre la reunión y revisa los pendientes de la semana anterior.'],
        ['02:10', 'Bruno', 'Reporta que el login con correo ya funciona en el emulador.'],
        ['05:30', 'Carla', 'Propone generar los PDF en el teléfono para no pagar servidor.'],
        ['07:45', 'David', 'Pregunta si el PDF soporta tildes; Carla confirma con fuentes TTF.'],
        ['10:20', 'Ana', 'Se aprueba generar los reportes en el cliente.'],
        ['13:05', 'Bruno', 'Advierte sobre el límite de solicitudes de la API del modelo.'],
        ['16:40', 'Ana', 'Propone caché local y reintentos con espera exponencial.'],
        ['19:15', 'Carla', 'Muestra el JSON que devuelve el modelo y el esquema esperado.'],
        ['22:30', 'David', 'Sugiere validar el JSON antes de dibujar el PDF.'],
        ['25:00', 'Carla', 'Se compromete a escribir pruebas unitarias del parser.'],
        ['28:10', 'Bruno', 'Se compromete a entregar autenticación el 10 de octubre.'],
        ['31:20', 'Ana', 'Revisa el cronograma de la exposición y la rúbrica.'],
        ['34:45', 'David', 'Se encarga del guion de la demo y del README.'],
        ['38:00', 'Carla', 'Pide que el repositorio sea público antes del 12 de octubre.'],
        ['41:30', 'Ana', 'Define el ensayo general para el 13 de octubre.'],
        ['44:10', 'Ana', 'Cierra la reunión y comparte este resumen por correo.'],
      ],
    },
  };
}
