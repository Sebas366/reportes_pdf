import 'package:flutter/material.dart';

import '../models/reporte_ia.dart';
import '../theme/marca.dart';
import '../utils/formato.dart';

/// Versión en pantalla del reporte. Reproduce la estructura del PDF
/// (portada, resumen, KPIs, gráfico, hallazgos, recomendaciones) para que
/// el usuario sepa qué va a exportar.
class VistaReporte extends StatelessWidget {
  const VistaReporte({super.key, required this.reporte});

  final ReporteIa reporte;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Portada(reporte: reporte),
        const SizedBox(height: 12),
        _Seccion(
          titulo: 'Resumen ejecutivo',
          icono: Icons.notes,
          child: Text(reporte.resumen, style: const TextStyle(height: 1.45)),
        ),
        const SizedBox(height: 12),
        _GrillaKpi(metricas: reporte.metricas),
        const SizedBox(height: 12),
        _Seccion(
          titulo: reporte.grafico.titulo,
          icono: Icons.bar_chart,
          child: _GraficoBarras(grafico: reporte.grafico),
        ),
        const SizedBox(height: 12),
        _Seccion(
          titulo: 'Hallazgos',
          icono: Icons.search,
          child: Column(
            children: [for (final hallazgo in reporte.hallazgos) _FilaHallazgo(hallazgo: hallazgo)],
          ),
        ),
        const SizedBox(height: 12),
        _Seccion(
          titulo: 'Recomendaciones',
          icono: Icons.checklist,
          child: Column(
            children: [
              for (var i = 0; i < reporte.recomendaciones.length; i++)
                _FilaRecomendacion(numero: i + 1, texto: reporte.recomendaciones[i]),
            ],
          ),
        ),
      ],
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.reporte});

  final ReporteIa reporte;

  @override
  Widget build(BuildContext context) {
    const suave = Color(Marca.primarioSuave);
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(Marca.primarioOscuro), Color(Marca.primario)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPORTE DE ANÁLISIS POR IA',
            style: textos.labelSmall?.copyWith(color: suave, letterSpacing: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            reporte.titulo,
            style: textos.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if (reporte.subtitulo.isNotEmpty)
            Text(reporte.subtitulo, style: textos.bodySmall?.copyWith(color: suave)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Dato(icono: Icons.memory, texto: reporte.modelo),
              _Dato(icono: Icons.schedule, texto: Formato.fechaHora(reporte.generadoEn)),
              _Dato(icono: Icons.tag, texto: reporte.id),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Confianza', style: textos.labelMedium?.copyWith(color: suave)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: reporte.confianza,
                    minHeight: 6,
                    color: const Color(0xFF80CBC4),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Formato.porcentaje(reporte.confianza),
                style: textos.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: const Color(Marca.primarioSuave)),
        const SizedBox(width: 4),
        // Flexible: en pantallas angostas o con letra grande se recorta.
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono, required this.child});

  final String titulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: esquema.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(titulo, style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// KPIs en 2 columnas (cabe en cualquier ancho de teléfono).
class _GrillaKpi extends StatelessWidget {
  const _GrillaKpi({required this.metricas});

  final List<Metrica> metricas;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        const espacio = 12.0;
        final ancho = (restricciones.maxWidth - espacio) / 2;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final metrica in metricas)
              SizedBox(
                width: ancho,
                child: _TarjetaKpi(metrica: metrica),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaKpi extends StatelessWidget {
  const _TarjetaKpi({required this.metrica});

  final Metrica metrica;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final variacion = metrica.variacion;
    final colorVariacion = switch (metrica.esMejora) {
      true => const Color(Marca.exito),
      false => esquema.error,
      null => esquema.onSurfaceVariant,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metrica.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textos.labelMedium?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              metrica.valorFormateado,
              style: textos.headlineSmall?.copyWith(
                color: esquema.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (metrica.esMejora != null)
                  Icon(
                    (variacion ?? 0) > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: colorVariacion,
                  ),
                Flexible(
                  child: Text(
                    variacion == null ? 'Sin comparación' : Formato.variacion(variacion),
                    style: textos.labelMedium?.copyWith(color: colorVariacion),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barras horizontales animadas (Flutter puro, sin paquetes de gráficos).
class _GraficoBarras extends StatelessWidget {
  const _GraficoBarras({required this.grafico});

  final GraficoReporte grafico;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final punto in grafico.puntos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(punto.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: Container(
                    height: 14,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: esquema.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (punto.valor / grafico.techo).clamp(0, 1)),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, factor, _) => FractionallySizedBox(
                        widthFactor: factor,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: esquema.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    Formato.conUnidad(punto.valor, grafico.unidad, decimales: grafico.decimales),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilaHallazgo extends StatelessWidget {
  const _FilaHallazgo({required this.hallazgo});

  final Hallazgo hallazgo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final color = Color(switch (hallazgo.severidad) {
      Severidad.alta => Marca.peligro,
      Severidad.media => Marca.alerta,
      Severidad.baja => Marca.exito,
    });
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hallazgo.categoria,
                  style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  hallazgo.severidad.etiqueta,
                  style: textos.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(hallazgo.descripcion, style: textos.bodySmall),
          Text(
            'Confianza del modelo: ${Formato.porcentaje(hallazgo.confianza)}',
            style: textos.labelSmall?.copyWith(color: esquema.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FilaRecomendacion extends StatelessWidget {
  const _FilaRecomendacion({required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(Marca.acento),
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
