import '../data/respuestas_simuladas.dart';
import '../models/escenario.dart';
import '../models/reporte_ia.dart';

/// Resultado de una consulta al modelo: el texto crudo y el reporte validado.
///
/// Se conserva el texto crudo para mostrarlo en la demo ("esto respondió el
/// LLM") y para auditoría.
class RespuestaIa {
  const RespuestaIa({required this.textoCrudo, required this.reporte});

  final String textoCrudo;
  final ReporteIa reporte;
}

/// Contrato de cualquier proveedor de IA (Gemini, OpenAI, un modelo local...).
///
/// La pantalla solo conoce esta interfaz; cambiar de proveedor no toca la UI
/// ni el generador de PDF.
abstract interface class IaService {
  Future<RespuestaIa> analizar(Escenario escenario);
}

/// Proveedor simulado: responde JSON de ejemplo tras una latencia artificial.
///
/// Ideal para la exposición: funciona sin internet ni API key y siempre
/// produce el mismo resultado.
class IaServiceSimulado implements IaService {
  const IaServiceSimulado({this.latencia = const Duration(milliseconds: 1200)});

  /// Tiempo que "tarda" el modelo; en las pruebas se usa `Duration.zero`.
  final Duration latencia;

  @override
  Future<RespuestaIa> analizar(Escenario escenario) async {
    await Future<void>.delayed(latencia);
    final texto = RespuestasSimuladas.para(escenario, fecha: DateTime.now());
    return RespuestaIa(textoCrudo: texto, reporte: ReporteIa.desdeTextoLlm(texto));
  }
}

// Para conectar un LLM real basta con otra implementación, por ejemplo:
//
// class IaServiceGemini implements IaService {
//   @override
//   Future<RespuestaIa> analizar(Escenario escenario) async {
//     final texto = await llamarApiDelModelo(
//       prompt: escenario.prompt,
//       formatoRespuesta: 'application/json', // salida estructurada
//     );
//     return RespuestaIa(
//       textoCrudo: texto,
//       reporte: ReporteIa.desdeTextoLlm(texto),
//     );
//   }
// }
//
// Ver la sección "Conectar un LLM real" del README.
