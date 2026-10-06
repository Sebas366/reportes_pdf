import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_pdf_ia/data/respuestas_simuladas.dart';
import 'package:reportes_pdf_ia/models/escenario.dart';
import 'package:reportes_pdf_ia/models/reporte_ia.dart';
import 'package:reportes_pdf_ia/utils/formato.dart';

/// El parser es la frontera entre el LLM (no confiable) y el PDF:
/// estas pruebas fijan cómo reacciona ante respuestas imperfectas.
void main() {
  final fecha = DateTime(2026, 10, 5, 14, 7);

  group('ReporteIa.desdeTextoLlm', () {
    for (final escenario in Escenario.values) {
      test('interpreta la respuesta simulada de "${escenario.etiqueta}"', () {
        final reporte = ReporteIa.desdeTextoLlm(RespuestasSimuladas.para(escenario, fecha: fecha));

        expect(reporte.titulo, isNotEmpty);
        expect(reporte.metricas, isNotEmpty);
        expect(reporte.grafico.puntos, isNotEmpty);
        expect(reporte.hallazgos, isNotEmpty);
        expect(reporte.anexo?.filas, isNotEmpty);
        expect(reporte.generadoEn, fecha);
      });
    }

    test('quita el bloque ```json que agregan muchos LLM', () {
      const texto = '```json\n{"id": "X-1", "titulo": "T", "resumen": "R"}\n```';
      final reporte = ReporteIa.desdeTextoLlm(texto);
      expect(reporte.id, 'X-1');
    });

    test('lanza FormatException si el texto no es JSON', () {
      expect(
        () => ReporteIa.desdeTextoLlm('Claro, aquí tienes el reporte...'),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException si la raíz no es un objeto', () {
      expect(() => ReporteIa.desdeTextoLlm('[1, 2, 3]'), throwsFormatException);
    });

    test('lanza FormatException si falta un campo obligatorio', () {
      expect(
        () => ReporteIa.desdeTextoLlm('{"id": "X-1", "titulo": "Sin resumen"}'),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', contains('resumen'))),
      );
    });

    test('normaliza confianza 92 → 0.92 y números escritos como texto', () {
      final reporte = ReporteIa.desdeTextoLlm('''
        {"id": "X", "titulo": "T", "resumen": "R", "confianza": 92,
         "metricas": [{"etiqueta": "Espera", "valor": "6,8", "unidad": "min"}],
         "hallazgos": [{"categoria": "C", "descripcion": "D", "severidad": "HIGH", "confianza": 0.5}]}
      ''');
      expect(reporte.confianza, closeTo(0.92, 1e-9));
      expect(reporte.metricas.single.valor, 6.8);
      expect(reporte.hallazgos.single.severidad, Severidad.alta);
    });

    test('toJson y fromJson son simétricos', () {
      final original = ReporteIa.desdeTextoLlm(
        RespuestasSimuladas.para(Escenario.sentimientoClientes, fecha: fecha),
      );
      final copia = ReporteIa.fromJson(original.toJson());
      expect(copia.toJson(), original.toJson());
    });

    test('genera un nombre de archivo seguro', () {
      final reporte = ReporteIa.desdeTextoLlm(
        '{"id": "RPT 2026/10", "titulo": "T", "resumen": "R"}',
      );
      expect(reporte.nombreArchivo, 'reporte_rpt_2026_10.pdf');
    });
  });

  group('Metrica y GraficoReporte', () {
    test('esMejora considera cuando bajar es bueno', () {
      expect(const Metrica(etiqueta: 'CSAT', valor: 78, variacion: 4).esMejora, isTrue);
      expect(
        const Metrica(etiqueta: 'Espera', valor: 6.8, variacion: 1.4, menorEsMejor: true).esMejora,
        isFalse,
      );
      expect(const Metrica(etiqueta: 'Duración', valor: 45).esMejora, isNull);
    });

    test('techo del eje es un número redondo', () {
      GraficoReporte con(double maximo) => GraficoReporte(
        titulo: 'g',
        puntos: [PuntoGrafico(etiqueta: 'a', valor: maximo)],
      );
      expect(con(4.5).techo, 5);
      expect(con(14).techo, 20);
      expect(con(81).techo, 100);
      expect(con(1250).techo, 2000);
    });
  });

  group('Formato', () {
    test('usa coma decimal y punto de miles', () {
      expect(Formato.numero(1250.5), '1.250,5');
      expect(Formato.numero(1250000, decimales: 0), '1.250.000');
    });

    test('pega la unidad según el tipo', () {
      expect(Formato.conUnidad(78, '%'), '78 %');
      expect(Formato.conUnidad(4.1, '/5'), '4,1/5');
      expect(Formato.conUnidad(4, '/5', decimales: 1), '4,0/5');
    });

    test('variación con signo y fecha en español', () {
      expect(Formato.variacion(4.2), '+4,2');
      expect(Formato.variacion(-1), '-1');
      expect(Formato.fechaHora(DateTime(2026, 10, 5, 9, 3)), '5 oct 2026, 09:03');
    });
  });
}
