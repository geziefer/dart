import 'package:flutter/material.dart';

import 'package:dart/scolia/scolia_service.dart';
import 'package:dart/scolia/scolia_settings.dart';
import 'package:dart/view/view_scolia_monitor.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:provider/provider.dart';

/// Settings page for entering the local-only Scolia credentials (board serial
/// number + access token). Reached via the "Scolia" button on the
/// "Statistik / Einstellungen" page.
class ViewScoliaSettings extends StatefulWidget {
  const ViewScoliaSettings({super.key, this.settings});

  /// Injectable for testing; defaults to a device-local [ScoliaSettings].
  final ScoliaSettings? settings;

  @override
  State<ViewScoliaSettings> createState() => _ViewScoliaSettingsState();
}

class _ViewScoliaSettingsState extends State<ViewScoliaSettings> {
  late final ScoliaSettings _settings;
  late final TextEditingController _serialController;
  late final TextEditingController _tokenController;
  bool _obscureToken = true;
  bool _simulator = true;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? ScoliaSettings();
    _serialController = TextEditingController(text: _settings.serialNumber);
    _tokenController = TextEditingController(text: _settings.accessToken);
    _simulator = _settings.simulatorEnabled;
  }

  @override
  void dispose() {
    _serialController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _save() {
    _settings.save(
      serialNumber: _serialController.text,
      accessToken: _tokenController.text,
    );
    if (mounted) {
      setState(() {}); // re-evaluate canMonitor with the new credentials
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scolia-Zugangsdaten gespeichert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameLayout(
      title: 'Scolia',
      mainContent: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zugangsdaten werden nur lokal auf diesem Gerät gespeichert.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _serialController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Board-Seriennummer',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              obscureText: _obscureToken,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Access Token',
                labelStyle: const TextStyle(color: Colors.white70),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureToken ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      setState(() => _obscureToken = !_obscureToken),
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.black),
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                side: WidgetStatePropertyAll(
                    BorderSide(color: Colors.white38)),
              ),
              onPressed: _save,
              child: const Text('Speichern'),
            ),
            const Divider(height: 40, color: Colors.white24),
            // Simulator switch: mock (on-screen dartboard) vs. real board.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simulator-Modus',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'An: Eingabe über Dartscheibe am Bildschirm. Aus: echtes Scolia-Board.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _simulator,
              activeThumbColor: const Color.fromARGB(255, 215, 198, 132),
              activeTrackColor: const Color.fromARGB(120, 215, 198, 132),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.black,
              trackOutlineColor: WidgetStateProperty.all(Colors.white38),
              onChanged: (v) {
                setState(() => _simulator = v);
                _settings.simulatorEnabled = v;
              },
            ),
            const SizedBox(height: 16),
            // The Monitor only makes sense with the real board (not simulator).
            Builder(builder: (context) {
              final canMonitor = !_simulator && _settings.isConfigured;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(Colors.black),
                      foregroundColor: const WidgetStatePropertyAll(Colors.white),
                      side: WidgetStatePropertyAll(
                          BorderSide(color: canMonitor ? Colors.white38 : Colors.white12)),
                    ),
                    icon: const Icon(Icons.monitor_heart),
                    label: const Text('Monitor öffnen'),
                    onPressed: canMonitor ? _openMonitor : null,
                  ),
                  if (!canMonitor)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Monitor nur mit echtem Board verfügbar '
                        '(Simulator aus + Zugangsdaten gesetzt).',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
      statsContent: const SizedBox(),
    );
  }

  void _openMonitor() {
    final svc = context.read<ScoliaService?>();
    if (svc == null) return;
    svc.connect();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ViewScoliaMonitor(),
      ),
    );
  }
}
