import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/dependencias.dart';
import 'package:tienda_talavera/main.dart';

void main() {
  testWidgets('flujo completo: catálogo -> carrito -> registro -> checkout -> recibo',
      (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final deps = Dependencias.pruebas();
    await deps.iniciar();

    await tester.pumpWidget(TiendaApp(deps: deps));
    await tester.pumpAndSettle();

    expect(find.text('Jarrón Talavera azul'), findsOneWidget);

    await tester.tap(find.text('Agregar').first);
    await tester.pump();
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Carrito'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar al pago'), findsOneWidget);

    await tester.tap(find.text('Continuar al pago'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No tengo cuenta, registrarme'));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Ana Pérez');
    await tester.enterText(campos.at(1), 'ana@correo.com');
    await tester.enterText(campos.at(2), 'clave1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar compra'), findsOneWidget);

    final camposCheckout = find.byType(TextField);
    await tester.enterText(camposCheckout.at(1), 'Calle 5 de Febrero 10');
    await tester.enterText(camposCheckout.at(2), 'Centro');
    await tester.enterText(camposCheckout.at(3), '37800');
    await tester.enterText(camposCheckout.at(4), '4181234567');
    await tester.enterText(camposCheckout.at(7), '4242424242424242');
    await tester.enterText(camposCheckout.at(9), '12');
    await tester.enterText(camposCheckout.at(10), '30');
    await tester.enterText(camposCheckout.at(11), '123');

    final botonPagar = find.widgetWithText(FilledButton, 'Pagar \$1,250.00');
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(botonPagar);
    await tester.pumpAndSettle();

    expect(find.text('¡Gracias por tu compra!'), findsOneWidget);
  });

  testWidgets('detalle de producto con modelo 3D muestra opción 3D y AR', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final deps = Dependencias.pruebas();
    await deps.iniciar();

    await tester.pumpWidget(TiendaApp(deps: deps));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jarrón Talavera azul'));
    await tester.pumpAndSettle();

    expect(find.text('Vista 3D y AR disponible'), findsOneWidget);
    expect(find.text('Medidas: 30 × 18 × 18 cm'), findsOneWidget);
  });
}
