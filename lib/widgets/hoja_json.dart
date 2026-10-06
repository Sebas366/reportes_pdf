import 'package:flutter/material.dart';

/// Hoja inferior con el texto crudo que respondió el LLM.
///
/// En la exposición sirve para mostrar el paso "Respuesta LLM → modelo de
/// datos": el PDF nunca se dibuja desde texto libre, sino desde JSON validado.
Future<void> mostrarHojaJson(BuildContext context, String textoCrudo) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controlador) {
        final esquema = Theme.of(context).colorScheme;
        final textos = Theme.of(context).textTheme;
        return ListView(
          controller: controlador,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Respuesta cruda del LLM', style: textos.titleMedium),
            const SizedBox(height: 6),
            Text(
              'ReporteIa.desdeTextoLlm() limpia este texto (por ejemplo, los '
              'bloques ```json), lo valida y lo convierte en objetos Dart. '
              'PdfService solo dibuja datos ya validados.',
              style: textos.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: esquema.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                textoCrudo,
                style: const TextStyle(fontFamily: 'NotoSansMono', fontSize: 11, height: 1.4),
              ),
            ),
          ],
        );
      },
    ),
  );
}
