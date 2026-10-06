import 'package:flutter/material.dart';

/// Índices de las etapas del flujo de la demo.
abstract final class EtapaFlujo {
  static const prompt = 0;
  static const llm = 1;
  static const json = 2;
  static const pdf = 3;
  static const compartir = 4;
}

/// Muestra el recorrido Prompt → LLM → JSON → PDF → Compartir y resalta
/// las etapas completadas. Sirve de "mapa" durante la exposición.
class IndicadorFlujo extends StatelessWidget {
  const IndicadorFlujo({super.key, required this.etapaCompletada});

  final int etapaCompletada;

  static const _etapas = [
    (Icons.edit_note, 'Prompt'),
    (Icons.auto_awesome, 'LLM'),
    (Icons.data_object, 'JSON'),
    (Icons.picture_as_pdf_outlined, 'PDF'),
    (Icons.share, 'Compartir'),
  ];

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _etapas.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 2,
                  color: i <= etapaCompletada ? esquema.primary : esquema.outlineVariant,
                ),
              ),
            ),
          _Paso(icono: _etapas[i].$1, etiqueta: _etapas[i].$2, completado: i <= etapaCompletada),
        ],
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.icono, required this.etiqueta, required this.completado});

  final IconData icono;
  final String etiqueta;
  final bool completado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completado ? esquema.primary : esquema.surfaceContainerHighest,
          ),
          child: Icon(
            icono,
            size: 18,
            color: completado ? esquema.onPrimary : esquema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: completado ? esquema.primary : esquema.onSurfaceVariant,
            fontWeight: completado ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
