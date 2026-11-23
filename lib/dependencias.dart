import 'package:flutter/widgets.dart';
import 'datos/almacenes.dart';
import 'datos/auth_simulada.dart';
import 'datos/catalogo_memoria.dart';
import 'datos/pasarela_simulada.dart';
import 'dominio/contratos.dart';
import 'dominio/servicio_checkout.dart';
import 'estado/carrito_vm.dart';
import 'estado/catalogo_vm.dart';
import 'estado/checkout_vm.dart';
import 'estado/sesion_vm.dart';

class Dependencias {
  final RepositorioCatalogo catalogo;
  final CatalogoViewModel catalogoVm;
  final CarritoViewModel carritoVm;
  final SesionViewModel sesionVm;
  final CheckoutViewModel checkoutVm;

  Dependencias._({
    required this.catalogo,
    required this.catalogoVm,
    required this.carritoVm,
    required this.sesionVm,
    required this.checkoutVm,
  });

  factory Dependencias.produccion() => _construir(
        almacenCarrito: AlmacenCarritoPrefs(),
        almacenSeguro: AlmacenSeguroFlutter(),
        latenciaPasarela: const Duration(milliseconds: 500),
      );

  factory Dependencias.pruebas() => _construir(
        almacenCarrito: AlmacenCarritoMemoria(),
        almacenSeguro: AlmacenSeguroMemoria(),
        latenciaPasarela: Duration.zero,
      );

  static Dependencias _construir({
    required AlmacenCarrito almacenCarrito,
    required AlmacenSeguro almacenSeguro,
    required Duration latenciaPasarela,
  }) {
    final catalogo = CatalogoMemoria();
    final ordenes = OrdenesMemoria();
    final pasarela = PasarelaSimulada(latencia: latenciaPasarela);
    final auth = AuthSimulada(almacenSeguro);
    final checkout = ServicioCheckout(catalogo: catalogo, ordenes: ordenes, pasarela: pasarela);

    final catalogoVm = CatalogoViewModel(catalogo);
    final carritoVm = CarritoViewModel(almacenCarrito);
    final sesionVm = SesionViewModel(auth);
    final checkoutVm = CheckoutViewModel(
      servicio: checkout,
      ordenes: ordenes,
      carritoVm: carritoVm,
      onCatalogoCambio: catalogoVm.cargar,
    );

    return Dependencias._(
      catalogo: catalogo,
      catalogoVm: catalogoVm,
      carritoVm: carritoVm,
      sesionVm: sesionVm,
      checkoutVm: checkoutVm,
    );
  }

  Future<void> iniciar() async {
    await catalogoVm.cargar();
    await carritoVm.restaurar(catalogo.porId);
    await sesionVm.restaurar();
  }
}

class Proveedor extends InheritedWidget {
  final Dependencias deps;
  const Proveedor({super.key, required this.deps, required super.child});

  static Dependencias de(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<Proveedor>();
    assert(p != null, 'Falta Proveedor arriba en el árbol de widgets');
    return p!.deps;
  }

  @override
  bool updateShouldNotify(Proveedor oldWidget) => false;
}
