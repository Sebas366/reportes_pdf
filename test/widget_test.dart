import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_pdf_ia/main.dart';
import 'package:reportes_pdf_ia/services/ia_service.dart';

/// Prueba de interfaz del flujo principal con la IA simulada sin latencia.
void main() {
  Finder boton(String texto) => find.ancestor(
    of: find.text(texto),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );

  bool habilitado(WidgetTester tester, String texto) =>
      tester.widget<ButtonStyleButton>(boton(texto)).enabled;

  /// Pantalla de teléfono (Pixel: 412 x 915 dp) en lugar de 800 x 600.
  Future<void> abrirApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ReportesApp(iaService: IaServiceSimulado(latencia: Duration.zero)),
    );
  }

  /// Desplaza la lista hasta el elemento y lo toca.
  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  testWidgets('elegir caso, generar con IA y habilitar la exportación', (tester) async {
    await abrirApp(tester);

    // Sin reporte no se puede exportar.
    expect(habilitado(tester, 'Previsualizar'), isFalse);
    expect(habilitado(tester, 'Compartir PDF'), isFalse);

    await tocar(tester, 'Rendimiento académico');
    expect(find.textContaining('Actúa como tutor académico'), findsOneWidget);

    await tocar(tester, 'Generar análisis con IA');

    expect(find.text('Diagnóstico de rendimiento académico'), findsOneWidget);
    expect(habilitado(tester, 'Previsualizar'), isTrue);
    expect(habilitado(tester, 'Compartir PDF'), isTrue);

    // La hoja con el JSON crudo del modelo.
    await tester.tap(find.byTooltip('Ver respuesta JSON del LLM'));
    await tester.pumpAndSettle();
    expect(find.text('Respuesta cruda del LLM'), findsOneWidget);
  });

  testWidgets('cambiar de caso descarta el reporte anterior', (tester) async {
    await abrirApp(tester);
    await tocar(tester, 'Generar análisis con IA');
    expect(find.text('Análisis de sentimiento de clientes'), findsOneWidget);

    await tocar(tester, 'Resumen de reunión');

    expect(find.text('Análisis de sentimiento de clientes'), findsNothing);
    expect(habilitado(tester, 'Compartir PDF'), isFalse);
  });
}
