import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/reporte_ia.dart';
import '../../theme/marca.dart';
import '../../utils/formato.dart';

// Colores de marca convertidos al tipo del paquete pdf.
final _primario = PdfColor.fromInt(Marca.primario);
final _primarioOscuro = PdfColor.fromInt(Marca.primarioOscuro);
final _primarioSuave = PdfColor.fromInt(Marca.primarioSuave);
final _acento = PdfColor.fromInt(Marca.acento);
final _texto = PdfColor.fromInt(Marca.texto);
final _textoSuave = PdfColor.fromInt(Marca.textoSuave);
final _fondoSuave = PdfColor.fromInt(Marca.fondoSuave);
final _borde = PdfColor.fromInt(Marca.borde);

/// Logo vectorial: el paquete pdf dibuja SVG simples sin rasterizarlos.
const _logoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <rect width="48" height="48" rx="12" fill="#3949AB"/>
  <path d="M24 9 L27.5 20.5 L39 24 L27.5 27.5 L24 39 L20.5 27.5 L9 24 L20.5 20.5 Z" fill="#FFFFFF"/>
  <circle cx="36.5" cy="11.5" r="3.5" fill="#80CBC4"/>
</svg>
''';

/// Piezas visuales del reporte, construidas con `package:pdf/widgets.dart`.
///
/// Se parecen a los widgets de Flutter (Row, Column, Container, Text...),
/// pero NO son los de Flutter: no hay estado, ni gestos, ni animaciones.
/// Cada widget se mide, se ubica y se "pinta" una sola vez como
/// instrucciones vectoriales dentro del archivo PDF.
class ComponentesPdf {
  ComponentesPdf(this.reporte, {required this.fuenteMono});

  final ReporteIa reporte;

  /// Fuente monoespaciada para mostrar el prompt como "código".
  final pw.Font fuenteMono;

  // -------------------------------------------------------------------------
  // Encabezado y pie (se repiten en cada página)
  // -------------------------------------------------------------------------

  /// Encabezado compacto desde la página 2 (la 1 ya tiene la portada).
  pw.Widget encabezado(pw.Context context) {
    if (context.pageNumber == 1) return pw.SizedBox();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _borde, width: 0.8)),
      ),
      child: pw.Row(
        children: [
          pw.SvgImage(svg: _logoSvg, width: 14, height: 14),
          pw.SizedBox(width: 6),
          pw.Text(
            Marca.nombreApp,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primario),
          ),
          pw.Spacer(),
          pw.Text(reporte.titulo, style: pw.TextStyle(fontSize: 8, color: _textoSuave)),
        ],
      ),
    );
  }

  /// Pie con el ID del reporte y la numeración "Página X de Y".
  ///
  /// `context.pagesCount` se conoce porque MultiPage maqueta todo el
  /// documento antes de pintar los pies.
  pw.Widget piePagina(pw.Context context) {
    final estilo = pw.TextStyle(fontSize: 7.5, color: _textoSuave);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borde, width: 0.8)),
      ),
      child: pw.Row(
        children: [
          pw.Text('${reporte.id} · Generado con Flutter + pdf', style: estilo),
          pw.Spacer(),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: estilo),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Contenido
  // -------------------------------------------------------------------------

  /// Bloque de portada: logo, título, subtítulo y datos del modelo.
  pw.Widget portada() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _primarioOscuro,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.SvgImage(svg: _logoSvg, width: 42, height: 42),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REPORTE DE ANÁLISIS POR IA',
                      style: pw.TextStyle(
                        fontSize: 8,
                        letterSpacing: 1.4,
                        fontWeight: pw.FontWeight.bold,
                        color: _primarioSuave,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      reporte.titulo,
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    if (reporte.subtitulo.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        reporte.subtitulo,
                        style: pw.TextStyle(fontSize: 10, color: _primarioSuave),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _datoPortada('Reporte', reporte.id),
              _datoPortada('Generado', Formato.fechaHora(reporte.generadoEn)),
              _datoPortada('Modelo', reporte.modelo),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _etiquetaPortada('Confianza del modelo'),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.LinearProgressIndicator(
                            value: reporte.confianza,
                            minHeight: 5,
                            backgroundColor: _primario,
                            valueColor: PdfColor.fromInt(0xFF80CBC4),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          Formato.porcentaje(reporte.confianza),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Título de sección con una barra de color a la izquierda.
  pw.Widget tituloSeccion(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(width: 3, height: 13, color: _acento),
          pw.SizedBox(width: 6),
          pw.Text(
            texto,
            style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: _texto),
          ),
        ],
      ),
    );
  }

  /// Resumen ejecutivo redactado por la IA.
  pw.Widget resumen() {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: pw.BoxDecoration(
        color: _fondoSuave,
        border: pw.Border(left: pw.BorderSide(color: _primario, width: 3)),
      ),
      child: pw.Text(
        reporte.resumen,
        textAlign: pw.TextAlign.justify,
        style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2.5, color: _texto),
      ),
    );
  }

  /// KPIs en filas de 4 tarjetas del mismo ancho.
  pw.Widget indicadores() {
    const porFila = 4;
    final filas = <pw.Widget>[];
    for (var i = 0; i < reporte.metricas.length; i += porFila) {
      final grupo = reporte.metricas.skip(i).take(porFila).toList();
      filas.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < porFila; j++) ...[
                if (j > 0) pw.SizedBox(width: 8),
                // Los huecos se rellenan para que todas las tarjetas midan igual.
                pw.Expanded(child: j < grupo.length ? _tarjetaKpi(grupo[j]) : pw.SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return pw.Column(children: filas);
  }

  /// Gráfico de barras con el motor de gráficos incluido en el paquete pdf.
  pw.Widget grafico() {
    final datos = reporte.grafico;
    final techo = datos.techo;
    final decimales = techo <= 10 ? 1 : 0;
    final estiloEje = pw.TextStyle(fontSize: 8, color: _textoSuave);

    return pw.Container(
      height: 190,
      padding: const pw.EdgeInsets.fromLTRB(4, 8, 8, 4),
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis.fromStrings(
            [for (final p in datos.puntos) p.etiqueta],
            marginStart: 30,
            marginEnd: 30,
            ticks: true,
            textStyle: estiloEje,
          ),
          yAxis: pw.FixedAxis(
            [for (var i = 0; i <= 5; i++) techo * i / 5],
            format: (v) => Formato.numero(v, decimales: decimales),
            divisions: true,
            divisionsColor: _borde,
            textStyle: estiloEje,
          ),
        ),
        datasets: [
          pw.BarDataSet(
            color: _primario,
            width: 34,
            data: [
              for (var i = 0; i < datos.puntos.length; i++)
                pw.PointChartValue(i.toDouble(), datos.puntos[i].valor),
            ],
            // Etiqueta con el valor encima de cada barra.
            valuePosition: pw.ValuePosition.top,
            buildValue: (context, punto) => pw.Text(
              Formato.conUnidad(punto.y, datos.unidad, decimales: datos.decimales),
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _texto),
            ),
          ),
        ],
      ),
    );
  }

  /// Tabla de hallazgos construida a mano para poder meter "píldoras" de
  /// color en la columna de severidad.
  pw.Widget tablaHallazgos() {
    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(95),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(58),
        3: pw.FixedColumnWidth(58),
      },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _borde, width: 0.6),
        bottom: pw.BorderSide(color: _borde, width: 0.6),
      ),
      children: [
        // repeat: true => si la tabla salta de página, esta fila se repite.
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _primario),
          children: [
            for (final titulo in ['Categoría', 'Hallazgo', 'Severidad', 'Confianza'])
              _celdaEncabezado(titulo),
          ],
        ),
        for (final hallazgo in reporte.hallazgos)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _celda(hallazgo.categoria, negrita: true),
              _celda(hallazgo.descripcion),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                // Align evita que la píldora se estire a todo el ancho.
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: _pildoraSeveridad(hallazgo.severidad),
                ),
              ),
              _celda(Formato.porcentaje(hallazgo.confianza)),
            ],
          ),
      ],
    );
  }

  /// Lista numerada. Se devuelve como lista de widgets (y no un Column) para
  /// que MultiPage pueda cortar entre recomendaciones si no caben.
  List<pw.Widget> recomendaciones() {
    return [
      for (var i = 0; i < reporte.recomendaciones.length; i++)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 16,
                height: 16,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(color: _acento, shape: pw.BoxShape.circle),
                child: pw.Text(
                  '${i + 1}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.5),
                  child: pw.Text(
                    reporte.recomendaciones[i],
                    style: pw.TextStyle(fontSize: 10, color: _texto),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  /// Trazabilidad: prompt, modelo, aviso de IA y un QR de verificación.
  ///
  /// Un documento generado por IA debe decir que lo es y cómo se produjo.
  pw.Widget trazabilidad() {
    final pequeno = pw.TextStyle(fontSize: 7.5, color: _textoSuave);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borde),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'Trazabilidad del contenido generado por IA',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _texto),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Prompt enviado al modelo', style: pequeno),
                pw.SizedBox(height: 3),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: _fondoSuave,
                  child: pw.Text(
                    reporte.prompt,
                    style: pw.TextStyle(font: fuenteMono, fontSize: 7.5, color: _texto),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Modelo: ${reporte.modelo}   ·   '
                  'Confianza global: ${Formato.porcentaje(reporte.confianza)}   ·   '
                  'Generado: ${Formato.fechaHora(reporte.generadoEn)}',
                  style: pequeno,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Aviso: este documento fue generado automáticamente por un modelo '
                  'de inteligencia artificial. Verifique la información antes de '
                  'tomar decisiones.',
                  style: pequeno.copyWith(fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Column(
            children: [
              // El paquete pdf trae el generador de códigos (barcode): el QR
              // se dibuja como vectores, sin imágenes ni red.
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data:
                    'Reporte ${reporte.id} | ${reporte.modelo} | '
                    '${reporte.generadoEn.toIso8601String()} | '
                    'confianza ${Formato.porcentaje(reporte.confianza)}',
                width: 66,
                height: 66,
                color: _texto,
                // Sin texto bajo el código; si no, usaría Courier (sin Unicode).
                drawText: false,
                textStyle: pw.TextStyle(font: fuenteMono, fontSize: 6),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Escanee para verificar',
                style: pw.TextStyle(fontSize: 6.5, color: _textoSuave),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tabla larga del anexo. `TableHelper.fromTextArray` crea la tabla a
  /// partir de listas de texto, la parte entre páginas y repite el
  /// encabezado en cada una.
  pw.Widget tablaAnexo(TablaAnexo anexo) {
    return pw.TableHelper.fromTextArray(
      headers: anexo.columnas,
      data: anexo.filas,
      border: null,
      headerDecoration: pw.BoxDecoration(color: _primario),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: pw.TextStyle(fontSize: 8, color: _texto),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      oddRowDecoration: pw.BoxDecoration(color: _fondoSuave),
      columnWidths: _anchosProporcionales(anexo),
    );
  }

  // -------------------------------------------------------------------------
  // Piezas internas
  // -------------------------------------------------------------------------

  pw.Widget _etiquetaPortada(String texto) =>
      pw.Text(texto, style: pw.TextStyle(fontSize: 7, color: _primarioSuave));

  pw.Widget _datoPortada(String etiqueta, String valor) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(right: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _etiquetaPortada(etiqueta),
            pw.SizedBox(height: 3),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _tarjetaKpi(Metrica metrica) {
    final mejora = metrica.esMejora;
    final colorVariacion = switch (mejora) {
      true => PdfColor.fromInt(Marca.exito),
      false => PdfColor.fromInt(Marca.peligro),
      null => _textoSuave,
    };
    final variacion = metrica.variacion;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borde),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            metrica.etiqueta.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 6.5,
              letterSpacing: 0.4,
              fontWeight: pw.FontWeight.bold,
              color: _textoSuave,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            metrica.valorFormateado,
            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _primario),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            variacion == null
                ? 'Sin comparación'
                : '${Formato.variacion(variacion)} vs. periodo anterior',
            style: pw.TextStyle(fontSize: 7, color: colorVariacion),
          ),
        ],
      ),
    );
  }

  pw.Widget _celdaEncabezado(String texto) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      texto,
      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    ),
  );

  pw.Widget _celda(String texto, {bool negrita = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      texto,
      style: pw.TextStyle(
        fontSize: 9,
        color: _texto,
        fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  pw.Widget _pildoraSeveridad(Severidad severidad) {
    final color = PdfColor.fromInt(switch (severidad) {
      Severidad.alta => Marca.peligro,
      Severidad.media => Marca.alerta,
      Severidad.baja => Marca.exito,
    });
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Text(
        severidad.etiqueta,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  /// Ancho de cada columna según su contenido: las columnas cortas
  /// (fecha, canal...) reciben lo justo para no partir palabras y la columna
  /// de texto largo (comentario, intervención) se queda con el resto.
  static Map<int, pw.TableColumnWidth> _anchosProporcionales(TablaAnexo anexo) {
    double peso(int col) {
      final largos = [for (final fila in anexo.filas) col < fila.length ? fila[col].length : 0];
      final maximo = largos.fold(0, math.max);
      final promedio = largos.isEmpty ? 0.0 : largos.reduce((a, b) => a + b) / largos.length;
      final caracteres = math.max(
        anexo.columnas[col].length.toDouble(),
        maximo <= 14 ? maximo.toDouble() : promedio,
      );
      // +2 compensa el padding de la celda.
      return (caracteres + 2).clamp(4, 42).toDouble();
    }

    return {
      for (var col = 0; col < anexo.columnas.length; col++) col: pw.FlexColumnWidth(peso(col)),
    };
  }
}
