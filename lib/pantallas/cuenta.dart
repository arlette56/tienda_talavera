import 'package:flutter/material.dart';
import '../dependencias.dart';
import '../dominio/dinero.dart';

class PantallaCuenta extends StatefulWidget {
  final bool volverAlTerminar;
  const PantallaCuenta({super.key, this.volverAlTerminar = false});

  @override
  State<PantallaCuenta> createState() => _PantallaCuentaState();
}

class _PantallaCuentaState extends State<PantallaCuenta> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _esRegistro = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final deps = Proveedor.de(context);
    final sesion = deps.sesionVm;
    final ok = _esRegistro
        ? await sesion.registrar(_nombre.text, _correo.text, _password.text)
        : await sesion.iniciarSesion(_correo.text, _password.text);
    if (ok && mounted) {
      await deps.checkoutVm.cargarHistorial(sesion.usuario!.id);
      if (widget.volverAlTerminar && mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = Proveedor.de(context);
    final sesion = deps.sesionVm;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListenableBuilder(
        listenable: Listenable.merge([sesion, deps.checkoutVm]),
        builder: (context, _) {
          final u = sesion.usuario;
          if (u != null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u.nombre),
                  subtitle: Text(u.correo),
                ),
                if (u.direccion != null)
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Dirección guardada'),
                    subtitle: Text(u.direccion.toString()),
                  ),
                const Divider(height: 24),
                Text('Mis compras (${deps.checkoutVm.historial.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (deps.checkoutVm.historial.isEmpty)
                  const Text('Aún no tienes compras registradas.')
                else
                  for (final o in deps.checkoutVm.historial)
                    Card(
                      child: ListTile(
                        title: Text(o.id),
                        subtitle: Text('${o.lineas.length} productos • **** ${o.tarjetaUltimos4}'),
                        trailing: Text(formatearPesos(o.total)),
                      ),
                    ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: sesion.cerrarSesion,
                  child: const Text('Cerrar sesión'),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(_esRegistro ? 'Crear cuenta' : 'Iniciar sesión',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (_esRegistro) ...[
                TextField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (mínimo 8 caracteres, letras y números)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (sesion.error != null) ...[
                const SizedBox(height: 12),
                Text(sesion.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: sesion.cargando ? null : _enviar,
                child: Text(_esRegistro ? 'Crear cuenta' : 'Entrar'),
              ),
              TextButton(
                onPressed: () => setState(() => _esRegistro = !_esRegistro),
                child: Text(_esRegistro ? 'Ya tengo cuenta' : 'No tengo cuenta, registrarme'),
              ),
            ],
          );
        },
      ),
    );
  }
}
