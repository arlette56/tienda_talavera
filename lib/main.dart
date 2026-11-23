import 'package:flutter/material.dart';
import 'dependencias.dart';
import 'pantallas/catalogo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = Dependencias.produccion();
  await deps.iniciar();
  runApp(TiendaApp(deps: deps));
}

class TiendaApp extends StatelessWidget {
  final Dependencias deps;
  const TiendaApp({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    return Proveedor(
      deps: deps,
      child: MaterialApp(
        title: 'Artesanías Dolores',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1B4F9C),
          useMaterial3: true,
        ),
        home: const PantallaCatalogo(),
      ),
    );
  }
}
