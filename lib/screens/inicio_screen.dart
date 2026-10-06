import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/escenario.dart';
import '../services/archivos_service.dart';
import '../services/ia_service.dart';
import '../services/pdf/pdf_service.dart';
import '../services/share_service.dart';
import '../theme/marca.dart';
import '../widgets/hoja_json.dart';
import '../widgets/indicador_flujo.dart';
import '../widgets/tarjeta_prompt.dart';
import '../widgets/vista_reporte.dart';
import 'vista_previa_screen.dart';

/// Pantalla principal: Prompt → IA → reporte → PDF → Compartir.
class InicioScreen extends StatefulWidget {
  const InicioScreen({
    super.key,
    required this.iaService,
    this.pdfService = const PdfService(),
    this.archivosService = const ArchivosService(),
    this.shareService,
  });

  final IaService iaService;
  final PdfService pdfService;
  final ArchivosService archivosService;

  /// Opcional para poder inyectar un doble en las pruebas.
  final ShareService? shareService;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late final ShareService _shareService =
      widget.shareService ?? ShareService(archivos: widget.archivosService);

  Escenario _escenario = Escenario.sentimientoClientes;
  RespuestaIa? _respuesta;
  bool _analizando = false;
  bool _compartiendo = false;
  bool _incluirAnexo = true;

  /// Última etapa completada del flujo (ver [IndicadorFlujo]).
  int _etapa = EtapaFlujo.prompt;

  // ---------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------

  void _seleccionarEscenario(Escenario escenario) {
    setState(() {
      _escenario = escenario;
      _respuesta = null;
      _etapa = EtapaFlujo.prompt;
    });
  }

  /// Paso 1: enviar el prompt al modelo y validar su respuesta.
  Future<void> _analizar() async {
    setState(() => _analizando = true);
    try {
      final respuesta = await widget.iaService.analizar(_escenario);
      if (!mounted) return; // La pantalla pudo cerrarse durante el await.
      setState(() {
        _respuesta = respuesta;
        _etapa = EtapaFlujo.json;
      });
    } on FormatException catch (e) {
      // El modelo respondió algo que no cumple el esquema ReporteIa.
      _mostrarMensaje('Respuesta de la IA inválida: ${e.message}', error: true);
    } catch (e) {
      _mostrarMensaje('No se pudo consultar la IA: $e', error: true);
    } finally {
      if (mounted) setState(() => _analizando = false);
    }
  }

  /// Botón 1: abre la vista previa nativa (desde ahí se guarda o imprime).
  Future<void> _previsualizar() async {
    final reporte = _respuesta?.reporte;
    if (reporte == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VistaPreviaScreen(
          reporte: reporte,
          incluirAnexo: _incluirAnexo,
          pdfService: widget.pdfService,
          archivosService: widget.archivosService,
          shareService: _shareService,
        ),
      ),
    );
    if (mounted) setState(() => _etapa = math.max(_etapa, EtapaFlujo.pdf));
  }

  /// Botón 2: genera el PDF y abre el menú Compartir del sistema.
  ///
  /// [contextoBoton] es el contexto del propio botón: en iPad el menú se
  /// muestra como popover anclado a él.
  Future<void> _compartir(BuildContext contextoBoton) async {
    final reporte = _respuesta?.reporte;
    if (reporte == null || _compartiendo) return; // Evita dobles toques.

    // Se calcula ANTES de cualquier await: después el widget podría no existir.
    final origen = _rectanguloDe(contextoBoton);
    setState(() => _compartiendo = true);

    try {
      // 1. Modelo de datos → bytes del PDF (en un isolate aparte).
      final bytes = await widget.pdfService.generar(reporte, incluirAnexo: _incluirAnexo);
      if (mounted) setState(() => _etapa = math.max(_etapa, EtapaFlujo.pdf));

      // 2. Bytes → archivo temporal → hoja nativa de compartir.
      final resultado = await _shareService.compartirPdf(
        bytes: bytes,
        nombreArchivo: reporte.nombreArchivo,
        asunto: reporte.titulo,
        texto: 'Te comparto el reporte "${reporte.titulo}" generado con IA.',
        origen: origen,
      );
      if (!mounted) return;

      // 3. El sistema informa qué hizo el usuario.
      debugPrint('ShareResult: ${resultado.status} · ${resultado.raw}');
      switch (resultado.status) {
        case ShareResultStatus.success:
          setState(() => _etapa = EtapaFlujo.compartir);
          _mostrarMensaje('Reporte compartido correctamente.');
        case ShareResultStatus.dismissed:
          _mostrarMensaje('Compartir cancelado.');
        case ShareResultStatus.unavailable:
          _mostrarMensaje('Menú de compartir cerrado.');
      }
    } on MissingPluginException {
      // Típico en clase: se agregó el paquete y solo se hizo hot reload.
      _mostrarMensaje(
        'Plugin nativo no registrado: detén la app y ejecuta "flutter run" de nuevo.',
        error: true,
      );
    } on PlatformException catch (e) {
      _mostrarMensaje('El sistema no pudo abrir el menú: ${e.message}', error: true);
    } on FileSystemException catch (e) {
      _mostrarMensaje('No se pudo escribir el PDF temporal: ${e.message}', error: true);
    } catch (e) {
      _mostrarMensaje('Error inesperado al compartir: $e', error: true);
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  Rect? _rectanguloDe(BuildContext contexto) {
    final caja = contexto.findRenderObject();
    if (caja is! RenderBox || !caja.hasSize) return null;
    return caja.localToGlobal(Offset.zero) & caja.size;
  }

  void _mostrarMensaje(String texto, {bool error = false}) {
    if (!mounted) return;
    final esquema = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto), backgroundColor: error ? esquema.error : null));
  }

  // ---------------------------------------------------------------------
  // Interfaz
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final respuesta = _respuesta;

    return Scaffold(
      appBar: AppBar(
        title: const Text(Marca.nombreApp),
        actions: [
          IconButton(
            tooltip: 'Ver respuesta JSON del LLM',
            icon: const Icon(Icons.data_object),
            onPressed: respuesta == null
                ? null
                : () => mostrarHojaJson(context, respuesta.textoCrudo),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          IndicadorFlujo(etapaCompletada: _etapa),
          const SizedBox(height: 20),
          Text('1. Elige el caso de uso', style: textos.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final escenario in Escenario.values)
                ChoiceChip(
                  avatar: Icon(iconoDe(escenario), size: 18),
                  label: Text(escenario.etiqueta),
                  selected: escenario == _escenario,
                  onSelected: _analizando ? null : (_) => _seleccionarEscenario(escenario),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TarjetaPrompt(escenario: _escenario),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _analizando ? null : _analizar,
            icon: _analizando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_analizando ? 'Analizando con IA…' : 'Generar análisis con IA'),
          ),
          const SizedBox(height: 24),
          if (respuesta != null) ...[
            Text('2. Reporte generado', style: textos.titleSmall),
            const SizedBox(height: 8),
            VistaReporte(reporte: respuesta.reporte),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Incluir anexo detallado'),
              subtitle: Text(
                'Agrega ${respuesta.reporte.anexo?.filas.length ?? 0} registros: '
                'demuestra la paginación automática.',
              ),
              value: _incluirAnexo,
              onChanged: (valor) => setState(() => _incluirAnexo = valor),
            ),
          ] else
            _EstadoVacio(analizando: _analizando),
        ],
      ),
      bottomNavigationBar: _BarraAcciones(
        habilitada: respuesta != null && !_analizando,
        compartiendo: _compartiendo,
        alPrevisualizar: _previsualizar,
        alCompartir: _compartir,
      ),
    );
  }
}

/// Icono de cada escenario (vive en la UI para que el modelo no dependa de Flutter).
IconData iconoDe(Escenario escenario) => switch (escenario) {
  Escenario.sentimientoClientes => Icons.support_agent,
  Escenario.rendimientoAcademico => Icons.school_outlined,
  Escenario.resumenReunion => Icons.record_voice_over_outlined,
};

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.analizando});

  final bool analizando;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            analizando ? Icons.hourglass_top : Icons.description_outlined,
            size: 48,
            color: esquema.outline,
          ),
          const SizedBox(height: 12),
          Text(
            analizando
                ? 'El modelo está leyendo los datos y redactando el reporte…'
                : 'Genera un análisis para ver el reporte y exportarlo a PDF.',
            textAlign: TextAlign.center,
            style: TextStyle(color: esquema.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Barra inferior con los dos botones principales de la demo.
class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.habilitada,
    required this.compartiendo,
    required this.alPrevisualizar,
    required this.alCompartir,
  });

  final bool habilitada;
  final bool compartiendo;
  final VoidCallback alPrevisualizar;
  final void Function(BuildContext contextoBoton) alCompartir;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: habilitada ? alPrevisualizar : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Previsualizar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // Builder da un contexto propio del botón (para el popover en iPad).
                child: Builder(
                  builder: (contextoBoton) => FilledButton.icon(
                    onPressed: habilitada && !compartiendo
                        ? () => alCompartir(contextoBoton)
                        : null,
                    icon: compartiendo
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: const Text('Compartir PDF'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
