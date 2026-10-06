import 'package:flutter/material.dart';

import '../models/escenario.dart';

/// Muestra el caso de uso y el prompt exacto que se envía al modelo.
class TarjetaPrompt extends StatelessWidget {
  const TarjetaPrompt({super.key, required this.escenario});

  final Escenario escenario;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, size: 18, color: esquema.primary),
                const SizedBox(width: 8),
                Text('Prompt para el LLM', style: textos.labelLarge),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              escenario.descripcion,
              style: textos.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: esquema.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                escenario.prompt,
                style: const TextStyle(fontFamily: 'NotoSansMono', fontSize: 12, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
