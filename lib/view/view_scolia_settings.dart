import 'package:flutter/material.dart';

import 'package:dart/scolia/scolia_settings.dart';
import 'package:dart/widget/game_layout.dart';

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

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? ScoliaSettings();
    _serialController = TextEditingController(text: _settings.serialNumber);
    _tokenController = TextEditingController(text: _settings.accessToken);
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
            ElevatedButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
      statsContent: const SizedBox(),
    );
  }
}
