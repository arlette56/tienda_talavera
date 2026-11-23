import 'dart:math';

import 'package:flutter/foundation.dart';

import '../dominio/contratos.dart';
import '../dominio/direccion.dart';
import '../dominio/excepciones.dart';
import '../dominio/orden.dart';
import '../dominio/servicio_checkout.dart';
import '../dominio/tarjeta.dart';
import 'carrito_vm.dart';

class CheckoutViewModel extends ChangeNotifier {
  final ServicioCheckout _servicio;
  final RepositorioOrdenes _ordenes;
  final CarritoViewModel _carritoVm;
  final Future<void> Function() _onCatalogoCambio;

  String _claveIdempotencia = _nuevaClave();
  bool procesando = false;
  String? error;
  List<Orden> historial = [];

  CheckoutViewModel({
    required ServicioCheckout servicio,
    required RepositorioOrdenes ordenes,
    required CarritoViewModel carritoVm,
    required Future<void> Function() onCatalogoCambio,
  })  : _servicio = servicio,
        _ordenes = ordenes,
        _carritoVm = carritoVm,
        _onCatalogoCambio = onCatalogoCambio;

  static String _nuevaClave() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';

  Future<void> cargarHistorial(String usuarioId) async {
    historial = await _ordenes.delUsuario(usuarioId);
    notifyListeners();
  }

  Future<Orden?> pagar({
    required String usuarioId,
    required Direccion direccion,
    required DatosTarjeta tarjeta,
  }) async {
    if (procesando) return null;
    procesando = true;
    error = null;
    notifyListeners();
    try {
      final orden = await _servicio.pagar(
        usuarioId: usuarioId,
        carrito: _carritoVm.carrito,
        direccion: direccion,
        tarjeta: tarjeta,
        claveIdempotencia: _claveIdempotencia,
      );
      _claveIdempotencia = _nuevaClave();
      await _carritoVm.vaciar();
      await _onCatalogoCambio();
      await cargarHistorial(usuarioId);
      return orden;
    } catch (e) {
      error = mensajeSeguro(e);
      return null;
    } finally {
      procesando = false;
      notifyListeners();
    }
  }
}
