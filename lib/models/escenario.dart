/// Casos de uso reales de IA que la app sabe convertir en reporte PDF.
///
/// Cada escenario trae el prompt que se enviaría al LLM. El servicio
/// simulado responde con un JSON de ejemplo; uno real (Gemini, OpenAI...)
/// recibiría exactamente este texto.
enum Escenario {
  sentimientoClientes(
    etiqueta: 'Sentimiento de clientes',
    descripcion: 'Call center: clasifica comentarios y detecta problemas.',
    prompt:
        'Actúa como analista de experiencia del cliente. Analiza las 1.250 '
        'interacciones del call center de septiembre de 2026 (CSV adjunto). '
        'Clasifica el sentimiento de cada comentario (positivo, neutro, '
        'negativo), calcula indicadores, detecta problemas recurrentes y '
        'propone acciones. Responde SOLO con JSON válido según el esquema '
        'ReporteIa.',
  ),
  rendimientoAcademico(
    etiqueta: 'Rendimiento académico',
    descripcion: 'StudyBuddy IA: diagnóstico por asignatura y plan de mejora.',
    prompt:
        'Actúa como tutor académico. Con base en las notas, las sesiones de '
        'estudio y los quizzes del estudiante en el semestre 2026-2, genera un '
        'diagnóstico de rendimiento por asignatura, identifica riesgos y '
        'propone un plan de mejora. Responde SOLO con JSON válido según el '
        'esquema ReporteIa.',
  ),
  resumenReunion(
    etiqueta: 'Resumen de reunión',
    descripcion: 'Transcripción de audio: decisiones, compromisos y riesgos.',
    prompt:
        'Resume la transcripción de la reunión de seguimiento del proyecto '
        'final (45 min, 4 participantes). Extrae decisiones, compromisos con '
        'responsable y riesgos, y calcula la participación de cada persona. '
        'Responde SOLO con JSON válido según el esquema ReporteIa.',
  );

  const Escenario({required this.etiqueta, required this.descripcion, required this.prompt});

  /// Nombre corto para chips y botones.
  final String etiqueta;

  /// Explicación de una línea del caso de uso.
  final String descripcion;

  /// Instrucción enviada al modelo de lenguaje.
  final String prompt;
}
