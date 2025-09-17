import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/utils/web_helper_stub.dart'
    if (dart.library.html) 'package:dart/utils/web_helper_web.dart';

class ControllerStats extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _allStats = {};
  final bool _isLoading = false;

  Map<String, Map<String, dynamic>> get allStats => _allStats;
  bool get isLoading => _isLoading;

  ControllerStats() {
    init();
  }

  void init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAllStats();
    });
  }

  void refresh() {
    loadAllStats();
  }

  Future<void> loadAllStats() async {
    _allStats.clear();

    for (final game in Menu.games) {
      final storage = GetStorage(game.id);
      final stats = <String, dynamic>{};

      final keys = storage.getKeys();
      for (final key in keys) {
        stats[key] = storage.read(key);
      }

      if (stats.isNotEmpty) {
        _allStats[game.id] = {
          'name': game.name.replaceAll('\n', ' '),
          'stats': stats,
        };
      }
    }
    
    notifyListeners();
  }

  String _generateFileName() {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'dart_stats_$dateStr.json';
  }

  Future<String> exportStats() async {
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'games': _allStats,
    };

    return jsonEncode(exportData);
  }

  Future<void> shareExportedStats(BuildContext context) async {
    final jsonData = await exportStats();
    final fileName = _generateFileName();

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: jsonData));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistik in Zwischenablage übertragen')),
        );
      }
    } else {
      // Create a temporary file for sharing
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(jsonData);
        
        await SharePlus.instance.share(ShareParams(
          files: [XFile(tempFile.path)],
          subject: fileName,
        ));
      } catch (e) {
        // Fallback to text sharing if file sharing fails
        await SharePlus.instance.share(ShareParams(
          text: jsonData,
          subject: fileName,
        ));
      }
    }
  }

  Future<void> saveExportedStatsToFile(BuildContext context) async {
    final jsonData = await exportStats();
    final fileName = _generateFileName();

    try {
      if (kIsWeb) {
        // For web, use helper function to download file
        downloadFile(jsonData, fileName);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Statistik erfolgreich gespeichert')),
          );
        }
      } else {
        // For mobile, save to downloads directory
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Statistik gespeichert: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Speichern')),
        );
      }
    }
  }

  Future<void> importStatsFromFile(BuildContext context, Function(String) onValidDataSelected) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Statistik importieren',
      );

      if (result != null) {
        String jsonData;

        if (kIsWeb) {
          final bytes = result.files.single.bytes!;
          jsonData = String.fromCharCodes(bytes);
        } else {
          final file = File(result.files.single.path!);
          jsonData = await file.readAsString();
        }

        if (await validateImportData(jsonData)) {
          onValidDataSelected(jsonData);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ungültige Datei')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Importieren')),
        );
      }
    }
  }

  Future<bool> validateImportData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      return data is Map<String, dynamic> &&
          data.containsKey('version') &&
          data.containsKey('games');
    } catch (e) {
      return false;
    }
  }

  Future<void> importStats(String jsonData) async {
    final data = jsonDecode(jsonData);
    final games = data['games'] as Map<String, dynamic>;

    for (final gameId in games.keys) {
      final gameData = games[gameId] as Map<String, dynamic>;
      final stats = gameData['stats'] as Map<String, dynamic>;

      final storage = GetStorage(gameId);
      await storage.erase();

      for (final key in stats.keys) {
        await storage.write(key, stats[key]);
      }
    }

    await loadAllStats();
  }
}
