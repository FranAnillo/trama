import 'package:flutter/material.dart';

import 'data/sync.dart';

class AccountPage extends StatefulWidget {
  const AccountPage(this.engine, {super.key});
  final SyncEngine engine;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool consent = false, busy = false;
  SupabaseRemote? remote;
  String? status;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> sync() async {
    if (busy) return;
    setState(() {
      busy = true;
      status = null;
    });
    try {
      remote ??= await SupabaseRemote.login(email.text.trim(), password.text);
      password.clear();
      await widget.engine.sync(remote!);
      if (mounted) {
        setState(() => status = 'Sesiones terminadas y repasos sincronizados.');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => status = e is StateError ? e.message.toString() : 'Sin conexión con el servicio. Tu progreso está guardado aquí. Reintenta cuando vuelva la conexión.',
        );
      }
      remote = null;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cuenta y sincronización')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 710),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!SupabaseRemote.configured) ...[
              Text(
                'Tu progreso se guarda en este dispositivo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'La sincronización está pendiente de conectar el servicio de cuentas de Trama. Puedes seguir estudiando y descargando unidades.',
              ),
            ] else ...[
              const Text(
                'Conecta tu cuenta del piloto para reunir tus sesiones terminadas y repasos en varios dispositivos. Los borradores y las descargas se gestionan en cada dispositivo.',
              ),
              TextField(
                controller: email,
                enabled: !busy && remote == null,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              TextField(
                controller: password,
                enabled: !busy && remote == null,
                obscureText: true,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              CheckboxListTile(
                value: consent,
                onChanged: busy
                    ? null
                    : (v) => setState(() => consent = v ?? false),
                title: const Text(
                  'Vincular este cuaderno a mi cuenta y enviar mis sesiones terminadas y repasos.',
                ),
              ),
              FilledButton(
                onPressed: busy || !consent ? null : sync,
                child: Text(busy ? 'Sincronizando…' : 'Sincronizar ahora'),
              ),
              const Text(
                'La sesión se mantiene mientras esta pantalla esté abierta. Al volver a entrar se pedirá la contraseña.',
              ),
              if (status != null)
                Semantics(liveRegion: true, child: Text(status!)),
            ],
          ],
        ),
      ),
    ),
  );
}
