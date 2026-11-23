import 'package:flutter/material.dart';
import '../dependencias.dart';
import '../dominio/dinero.dart';
import '../dominio/direccion.dart';
import '../dominio/orden.dart';
import '../dominio/tarjeta.dart';

class PantallaCheckout extends StatefulWidget {
  const PantallaCheckout({super.key});

  @override
  State<PantallaCheckout> createState() => _PantallaCheckoutState();
}

class _PantallaCheckoutState extends State<PantallaCheckout> {
  late final TextEditingController _nombre;
  late final TextEditingController _calle;
  late final TextEditingController _colonia;
  late final TextEditingController _cp;
  late final TextEditingController _ciudad;
  late final TextEditingController _estado;
  late final TextEditingController _tel;
  final _numTarjeta = TextEditingController();
  final _titular = TextEditingController();
  final _mes = TextEditingController();
  final _anio = TextEditingController();
  final _cvv = TextEditingController();
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    final u = Proveedor.de(context).sesionVm.usuario;
    final d = u?.direccion;
    _nombre = TextEditingController(text: d?.nombreRecibe ?? u?.nombre ?? '');
    _calle = TextEditingController(text: d?.calle ?? '');
    _colonia = TextEditingController(text: d?.colonia ?? '');
    _cp = TextEditingController(text: d?.codigoPostal ?? '');
    _ciudad = TextEditingController(text: d?.ciudad ?? 'Dolores Hidalgo');
    _estado = TextEditingController(text: d?.estado ?? 'Guanajuato');
    _tel = TextEditingController(text: d?.telefono ?? u?.telefono ?? '');
    _titular.text = u?.nombre ?? '';
  }

  @override
  void dispose() {
    for (final c in [_nombre, _calle, _colonia, _cp, _ciudad, _estado, _tel,
        _numTarjeta, _titular, _mes, _anio, _cvv]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pagar() async {
    final deps = Proveedor.de(context);
    final usuario = deps.sesionVm.usuario;
    if (usuario == null) return;

    final direccion = Direccion(
      nombreRecibe: _nombre.text,
      calle: _calle.text,
      colonia: _colonia.text,
      codigoPostal: _cp.text,
      ciudad: _ciudad.text,
      estado: _estado.text,
      telefono: _tel.text,
    );

    final tarjeta = DatosTarjeta(
      numero: _numTarjeta.text,
      titular: _titular.text,
      mes: int.tryParse(_mes.text.trim()) ?? 0,
      anio: int.tryParse(_anio.text.trim()) ?? 0,
      cvv: _cvv.text.trim(),
    );

    final orden = await deps.checkoutVm.pagar(
      usuarioId: usuario.id,
      direccion: direccion,
      tarjeta: tarjeta,
    );

    if (orden != null && mounted) {
      await deps.sesionVm.guardarPerfil(
        nombre: usuario.nombre,
        telefono: _tel.text,
        direccion: direccion,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => _PantallaRecibo(orden: orden)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = Proveedor.de(context);
    final vm = deps.checkoutVm;

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar compra')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Dirección de envío', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _campo(_nombre, 'Nombre de quien recibe'),
              _campo(_calle, 'Calle y número'),
              _campo(_colonia, 'Colonia'),
              Row(
                children: [
                  Expanded(child: _campo(_cp, 'Código postal', teclado: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(_tel, 'Teléfono (10 dígitos)', teclado: TextInputType.phone)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _campo(_ciudad, 'Ciudad')),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(_estado, 'Estado')),
                ],
              ),
              const SizedBox(height: 16),
              Text('Tarjeta de pago', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _campo(_numTarjeta, 'Número de tarjeta', teclado: TextInputType.number),
              _campo(_titular, 'Nombre en la tarjeta'),
              Row(
                children: [
                  Expanded(child: _campo(_mes, 'Mes (MM)', teclado: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(_anio, 'Año (AA)', teclado: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(_cvv, 'CVV', teclado: TextInputType.number, oculto: true)),
                ],
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 12),
                Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: vm.procesando ? null : _pagar,
                child: vm.procesando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Pagar ${formatearPesos(deps.carritoVm.carrito.total)}'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String etiqueta,
      {TextInputType? teclado, bool oculto = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: teclado,
        obscureText: oculto,
        decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }
}

class _PantallaRecibo extends StatelessWidget {
  final Orden orden;
  const _PantallaRecibo({required this.orden});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compra confirmada')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 12),
            Text('¡Gracias por tu compra!',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Orden: ${orden.id}'),
            Text('Referencia de pago: ${orden.referenciaPago}'),
            Text('Tarjeta: **** ${orden.tarjetaUltimos4}'),
            Text('Envío a: ${orden.direccion}'),
            const Divider(height: 24),
            for (final l in orden.lineas)
              Text('${l.cantidad} × ${l.nombre} — ${formatearPesos(l.importe)}'),
            const Divider(height: 24),
            Text('Total pagado: ${formatearPesos(orden.total)}',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Volver a la tienda'),
            ),
          ],
        ),
      ),
    );
  }
}
