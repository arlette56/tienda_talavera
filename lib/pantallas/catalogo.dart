import 'package:flutter/material.dart';
import '../dependencias.dart';
import '../dominio/dinero.dart';
import '../dominio/excepciones.dart';
import '../dominio/producto.dart';
import 'carrito.dart';
import 'cuenta.dart';
import 'detalle.dart';

class PantallaCatalogo extends StatelessWidget {
  const PantallaCatalogo({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Proveedor.de(context);
    final catalogo = deps.catalogoVm;
    final carrito = deps.carritoVm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artesanías Dolores'),
        actions: [
          IconButton(
            tooltip: 'Mi cuenta',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaCuenta()),
            ),
          ),
          ListenableBuilder(
            listenable: carrito,
            builder: (_, _) => IconButton(
              tooltip: 'Carrito',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaCarrito()),
              ),
              icon: Badge.count(
                count: carrito.carrito.cantidadTotal,
                isLabelVisible: !carrito.carrito.estaVacio,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: catalogo,
        builder: (context, _) {
          if (catalogo.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (catalogo.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(catalogo.error!),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: catalogo.cargar, child: const Text('Reintentar')),
                ],
              ),
            );
          }

          final productos = catalogo.filtrados;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar artesanía...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: catalogo.buscar,
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('Todo'),
                        selected: catalogo.categoria == null,
                        onSelected: (_) => catalogo.elegirCategoria(null),
                      ),
                    ),
                    for (final c in Categoria.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(c.etiqueta),
                          selected: catalogo.categoria == c,
                          onSelected: (_) => catalogo.elegirCategoria(c),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: productos.isEmpty
                    ? const Center(child: Text('No encontramos productos con ese filtro.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: productos.length,
                        itemBuilder: (_, i) => _TarjetaProducto(producto: productos[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  final Producto producto;
  const _TarjetaProducto({required this.producto});

  @override
  Widget build(BuildContext context) {
    final deps = Proveedor.de(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PantallaDetalle(productoId: producto.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(child: Text(producto.emoji, style: const TextStyle(fontSize: 56))),
                    if (producto.tieneModelo3d)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Chip(
                          label: Text('3D', style: TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(formatearPesos(producto.precioCentavos),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              FilledButton.tonal(
                onPressed: producto.disponible
                    ? () async {
                        try {
                          await deps.carritoVm.agregar(producto);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text('Agregado: ${producto.nombre}')));
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
                child: Text(producto.disponible ? 'Agregar' : 'Agotado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
