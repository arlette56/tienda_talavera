import 'package:flutter/foundation.dart';

import '../dominio/contratos.dart';
import '../dominio/direccion.dart';
import '../dominio/excepciones.dart';
import '../dominio/usuario.dart';

class SesionViewModel extends ChangeNotifier {
  final ServicioAuth _auth;
  Usuario? _usuario;
  bool cargando = false;
  String? error;

  SesionViewModel(this._auth);

  Usuario? get usuario => _usuario;
  bool get haySesion => _usuario != null;

  Future<void> restaurar() async {
    _usuario = await _auth.restaurarSesion();
    notifyListeners();
  }

  Future<bool> iniciarSesion(String correo, String password) =>
      _ejecutar(() async => _usuario = await _auth.iniciarSesion(correo: correo, password: password));

  Future<bool> registrar(String nombre, String correo, String password) =>
      _ejecutar(() async =>
          _usuario = await _auth.registrar(nombre: nombre, correo: correo, password: password));

  Future<bool> guardarPerfil({required String nombre, required String telefono, Direccion? direccion}) =>
      _ejecutar(() async {
        final actual = _usuario;
        if (actual == null) throw const SesionRequeridaException();
        _usuario = await _auth.actualizarPerfil(
          actual.copiarCon(nombre: nombre, telefono: telefono, direccion: direccion),
        );
      });

  Future<void> alternarFavorito(String productoId) async {
    final actual = _usuario;
    if (actual == null) return;
    final favs = {...actual.favoritos};
    if (!favs.add(productoId)) favs.remove(productoId);
    _usuario = await _auth.actualizarPerfil(actual.copiarCon(favoritos: favs));
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await _auth.cerrarSesion();
    _usuario = null;
    notifyListeners();
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } catch (e) {
      error = mensajeSeguro(e);
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
