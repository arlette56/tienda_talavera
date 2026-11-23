import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/datos/almacenes.dart';
import 'package:tienda_talavera/datos/auth_simulada.dart';
import 'package:tienda_talavera/datos/catalogo_memoria.dart';
import 'package:tienda_talavera/datos/pasarela_simulada.dart';
import 'package:tienda_talavera/dominio/direccion.dart';
import 'package:tienda_talavera/dominio/producto.dart';
import 'package:tienda_talavera/dominio/servicio_checkout.dart';
import 'package:tienda_talavera/dominio/tarjeta.dart';
import 'package:tienda_talavera/estado/carrito_vm.dart';
import 'package:tienda_talavera/estado/catalogo_vm.dart';
import 'package:tienda_talavera/estado/checkout_vm.dart';
import 'package:tienda_talavera/estado/sesion_vm.dart';

const buena = DatosTarjeta(numero: '4242424242424242', titular: 'Ana', mes: 12, anio: 30, cvv: '123');
const dir = Direccion(
  nombreRecibe: 'Ana Pérez', calle: 'Calle 5 de Febrero 10', colonia: 'Centro',
  codigoPostal: '37800', ciudad: 'Dolores Hidalgo', estado: 'Guanajuato', telefono: '4181234567');

void main() {
  group('catalogo_vm', () {
    test('carga y filtra por texto y categoría', () async {
      final vm = CatalogoViewModel(CatalogoMemoria());
      await vm.cargar();
      expect(vm.todos.length, 8);

      vm.buscar('jarron');
      expect(vm.filtrados.map((p) => p.id), ['jarron']);

      vm.buscar('');
      vm.elegirCategoria(Categoria.dulces);
      expect(vm.filtrados.length, 2);
    });
  });

  group('carrito_vm', () {
    test('agrega, persiste y restaura', () async {
      final cat = CatalogoMemoria();
      final almacen = AlmacenCarritoMemoria();
      final jarron = (await cat.porId('jarron'))!;

      final vm1 = CarritoViewModel(almacen);
      await vm1.agregar(jarron, cantidad: 2);
      expect(vm1.carrito.cantidadTotal, 2);

      final vm2 = CarritoViewModel(almacen);
      await vm2.restaurar(cat.porId);
      expect(vm2.carrito.cantidadTotal, 2);
    });
  });

  group('sesion_vm', () {
    test('registra, alterna favoritos y cierra sesión', () async {
      final vm = SesionViewModel(AuthSimulada(AlmacenSeguroMemoria()));
      await vm.registrar('Ana Pérez', 'ana@correo.com', 'clave1234');
      expect(vm.haySesion, isTrue);

      await vm.alternarFavorito('jarron');
      expect(vm.usuario!.favoritos, contains('jarron'));

      await vm.cerrarSesion();
      expect(vm.haySesion, isFalse);
    });
  });

  group('checkout_vm', () {
    test('completa compra, vacía carrito y guarda orden', () async {
      final cat = CatalogoMemoria();
      final ordenes = OrdenesMemoria();
      final pasarela = PasarelaSimulada();
      final servicio = ServicioCheckout(catalogo: cat, ordenes: ordenes, pasarela: pasarela);
      final carritoVm = CarritoViewModel(AlmacenCarritoMemoria());
      await carritoVm.agregar((await cat.porId('jarron'))!);

      final vm = CheckoutViewModel(
        servicio: servicio,
        ordenes: ordenes,
        carritoVm: carritoVm,
        onCatalogoCambio: () async {},
      );

      final orden = await vm.pagar(usuarioId: 'u1', direccion: dir, tarjeta: buena);
      expect(orden, isNotNull);
      expect(carritoVm.carrito.estaVacio, isTrue);
      expect(vm.historial.length, 1);
    });
  });
}
