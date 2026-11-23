import 'package:flutter/foundation.dart';

import '../dominio/carrito.dart';
import '../dominio/contratos.dart';
import '../dominio/producto.dart';

class CarritoViewModel extends ChangeNotifier {
  final AlmacenCarrito _almacen;
  final Carrito carrito = Carrito();

  CarritoViewModel(this._almacen);

  Future<void> restaurar(Future<Producto?> Function(String) buscar) async {
    final guardados = await _almacen.cargar();
    final encontrados = <String, Producto>{};
    for (final d in guardados) {
      final id = d['id'];
      if (id is String) {
        final p = await buscar(id);
        if (p != null) encontrados[id] = p;
      }
    }
    carrito.restaurar(guardados, (id) => encontrados[id]);
    notifyListeners();
  }

  Future<void> agregar(Producto p, {int cantidad = 1}) async {
    carrito.agregar(p, cantidad: cantidad);
    await _persistir();
  }

  Future<void> cambiarCantidad(String id, int cantidad) async {
    carrito.cambiarCantidad(id, cantidad);
    await _persistir();
  }

  Future<void> quitar(String id) async {
    carrito.quitar(id);
    await _persistir();
  }

  Future<void> vaciar() async {
    carrito.vaciar();
    await _persistir();
  }

  void aplicarCupon(String codigo) {
    carrito.aplicarCupon(codigo);
    notifyListeners();
  }

  void quitarCupon() {
    carrito.quitarCupon();
    notifyListeners();
  }

  Future<void> _persistir() async {
    await _almacen.guardar(carrito.aMapas());
    notifyListeners();
  }
}
