import 'package:flutter/foundation.dart';

import '../dominio/contratos.dart';
import '../dominio/excepciones.dart';
import '../dominio/producto.dart';

class CatalogoViewModel extends ChangeNotifier {
  final RepositorioCatalogo _repo;
  List<Producto> _todos = [];
  Categoria? _categoria;
  String _consulta = '';
  bool cargando = false;
  String? error;

  CatalogoViewModel(this._repo);

  List<Producto> get todos => _todos;
  Categoria? get categoria => _categoria;
  String get consulta => _consulta;

  List<Producto> get filtrados {
    final q = _normalizar(_consulta);
    return _todos.where((p) {
      if (_categoria != null && p.categoria != _categoria) return false;
      if (q.isEmpty) return true;
      return _normalizar(p.nombre).contains(q) || _normalizar(p.descripcion).contains(q);
    }).toList();
  }

  static String _normalizar(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      _todos = await _repo.listar();
    } catch (e) {
      error = mensajeSeguro(e);
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void elegirCategoria(Categoria? c) {
    _categoria = c;
    notifyListeners();
  }

  void buscar(String texto) {
    _consulta = texto;
    notifyListeners();
  }
}
