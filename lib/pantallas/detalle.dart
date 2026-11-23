import 'package:flutter/material.dart';
import '../dependencias.dart';
import '../dominio/dinero.dart';
import '../dominio/excepciones.dart';
import '../dominio/producto.dart';
import 'vista_3d.dart';

class PantallaDetalle extends StatelessWidget {
  final String productoId;
  const PantallaDetalle({super.key, required this.productoId});

  @override
  Widget build(BuildContext context) {
    final deps = Proveedor.de(context);

    return ListenableBuilder(
      listenable: Listenable.merge([deps.catalogoVm, deps.sesionVm]),
      builder: (context, _) {
        final producto = deps.catalogoVm.todos.cast<Producto?>().firstWhere(
              (p) => p?.id == productoId,
              orElse: () => null,
            );
        if (producto == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Producto no encontrado.')));
        }
        final esFav = deps.sesionVm.usuario?.favoritos.contains(producto.id) ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(producto.nombre),
            actions: [
              if (deps.sesionVm.haySesion)
                IconButton(
                  tooltip: 'Favorito',
                  icon: Icon(esFav ? Icons.favorite : Icons.favorite_border,
                      color: esFav ? Colors.red : null),
                  onPressed: () => deps.sesionVm.alternarFavorito(producto.id),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Vista3dProducto(producto: producto),
              const SizedBox(height: 16),
              Text(producto.categoria.etiqueta, style: Theme.of(context).textTheme.labelLarge),
              Text(producto.nombre, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(formatearPesos(producto.precioCentavos),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(producto.descripcion),
              const SizedBox(height: 12),
              Text('Disponibles: ${producto.existencias} piezas',
                  style: Theme.of(context).textTheme.bodyMedium),
              if (producto.dimensiones != null) ...[
                const SizedBox(height: 4),
                Text('Medidas: ${producto.dimensiones}', style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: producto.disponible
                    ? () async {
                        try {
                          await deps.carritoVm.agregar(producto);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Agregado al carrito')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(mensajeSeguro(e))),
                            );
                          }
                        }
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(producto.disponible ? 'Agregar al carrito' : 'Agotado'),
              ),
            ],
          ),
        );
      },
    );
  }
}

