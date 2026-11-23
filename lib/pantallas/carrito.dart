import 'package:flutter/material.dart';
import '../dependencias.dart';
import '../dominio/dinero.dart';
import '../dominio/excepciones.dart';
import 'checkout.dart';
import 'cuenta.dart';

class PantallaCarrito extends StatefulWidget {
  const PantallaCarrito({super.key});

  @override
  State<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends State<PantallaCarrito> {
  final _cuponCtrl = TextEditingController();

  @override
  void dispose() {
    _cuponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = Proveedor.de(context);
    final vm = deps.carritoVm;

    return Scaffold(
      appBar: AppBar(title: const Text('Tu carrito')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final c = vm.carrito;
          if (c.estaVacio) {
            return const Center(child: Text('Tu carrito está vacío.'));
          }

          return Column(
            children: [
              if (c.faltaParaEnvioGratis > 0)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Te faltan ${formatearPesos(c.faltaParaEnvioGratis)} para envío gratis.',
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final l in c.lineas)
                      Card(
                        child: ListTile(
                          leading: Text(l.producto.emoji, style: const TextStyle(fontSize: 32)),
                          title: Text(l.producto.nombre),
                          subtitle: Text('${formatearPesos(l.producto.precioCentavos)} c/u'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => vm.cambiarCantidad(l.producto.id, l.cantidad - 1),
                              ),
                              Text('${l.cantidad}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  try {
                                    await vm.cambiarCantidad(l.producto.id, l.cantidad + 1);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(mensajeSeguro(e))),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (c.cupon == null)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cuponCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Cupón (ej. DOLORES10)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              try {
                                vm.aplicarCupon(_cuponCtrl.text);
                                _cuponCtrl.clear();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(mensajeSeguro(e))),
                                );
                              }
                            },
                            child: const Text('Aplicar'),
                          ),
                        ],
                      )
                    else
                      Chip(
                        label: Text('Cupón ${c.cupon!.codigo} (-${c.cupon!.porcentaje}%)'),
                        onDeleted: vm.quitarCupon,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fila('Subtotal', formatearPesos(c.subtotal)),
                    if (c.descuento > 0) _fila('Descuento', '-${formatearPesos(c.descuento)}'),
                    _fila('Envío', c.envio == 0 ? 'GRATIS' : formatearPesos(c.envio)),
                    _fila('IVA incluido', formatearPesos(c.iva)),
                    const Divider(),
                    _fila('Total', formatearPesos(c.total), negrita: true),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        if (!deps.sesionVm.haySesion) {
                          final ok = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const PantallaCuenta(volverAlTerminar: true)),
                          );
                          if (ok != true || !context.mounted) return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PantallaCheckout()),
                        );
                      },
                      child: const Text('Continuar al pago'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {bool negrita = false}) {
    final estilo = negrita ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(etiqueta, style: estilo), Text(valor, style: estilo)],
      ),
    );
  }
}
