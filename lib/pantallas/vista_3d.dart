import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../dominio/producto.dart';

class Vista3dProducto extends StatelessWidget {
  final Producto producto;
  const Vista3dProducto({super.key, required this.producto});

  bool get _enPruebas =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    if (!producto.tieneModelo3d || _enPruebas) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: colores.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(producto.emoji, style: const TextStyle(fontSize: 76)),
              if (producto.tieneModelo3d)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Chip(
                    avatar: Icon(Icons.view_in_ar, size: 18),
                    label: Text('Vista 3D y AR disponible'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ModelViewer(
            src: producto.modeloGlb!,
            iosSrc: producto.modeloUsdz,
            alt: 'Modelo 3D de ${producto.nombre}',
            ar: true,
            arModes: const ['scene-viewer', 'webxr', 'quick-look'],
            autoRotate: true,
            cameraControls: true,
            disableZoom: false,
            backgroundColor: colores.surfaceContainerHighest,
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Chip(
              avatar: const Icon(Icons.view_in_ar, size: 18),
              label: const Text('Gira en 3D • Toca el cubo para AR'),
              backgroundColor: colores.surface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
