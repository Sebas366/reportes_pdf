import 'package:flutter/material.dart';

import 'screens/inicio_screen.dart';
import 'services/archivos_service.dart';
import 'services/ia_service.dart';
import 'theme/app_theme.dart';
import 'theme/marca.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Borra PDFs temporales de días anteriores sin retrasar el arranque.
  const ArchivosService().limpiarTemporales().ignore();
  runApp(const ReportesApp());
}

class ReportesApp extends StatelessWidget {
  const ReportesApp({super.key, this.iaService = const IaServiceSimulado()});

  /// Proveedor de IA. Para usar un LLM real basta con pasar otra
  /// implementación de [IaService]; el resto de la app no cambia.
  final IaService iaService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Marca.nombreApp,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      home: InicioScreen(iaService: iaService),
    );
  }
}
