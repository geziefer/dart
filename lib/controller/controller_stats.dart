import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/services/highscore_service.dart';

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

  /// Delete all stats for a single game (erase its storage container).
  Future<void> deleteStatsForGame(String gameId) async {
    final storage = GetStorage(gameId);
    await storage.erase();
    loadAllStats();
    notifyListeners();
  }

  Future<void> loadAllStats() async {
    _allStats.clear();

    // Get all current menu games
    final allGameIds = Menu.games.map((game) => game.id).toList();
    
    // Add legacy/split game IDs that might have stats but aren't in current menu
    allGameIds.addAll(['RTCD', 'RTCT']);
    // Add the header-shortcut games (not in the Menu.games grid): the Quiz
    // (FQ) and the Bayrisches Sportabzeichen (CHALLENGE, which keeps a medal
    // highscore list).
    allGameIds.addAll(['FQ', 'CHALLENGE']);

    for (final gameId in allGameIds) {
      final storage = GetStorage(gameId);
      final stats = <String, dynamic>{};

      final keys = storage.getKeys();
      for (final key in keys) {
        stats[key] = storage.read(key);
      }

      if (stats.isNotEmpty) {
        // Try to find the game name from menu first
        final menuGame = Menu.games.where((game) => game.id == gameId).firstOrNull;
        String gameName;
        
        if (menuGame != null) {
          gameName = menuGame.name.replaceAll('\n', ' ');
        } else {
          // Fallback names for legacy IDs
          switch (gameId) {
            case 'RTCD':
              gameName = 'RTC Double max 20';
              break;
            case 'RTCT':
              gameName = 'RTC Triple max 20';
              break;
            case 'FQ':
              gameName = 'FinishQuest';
              break;
            case 'CHALLENGE':
              gameName = 'Bayrisches Sportabzeichen';
              break;
            default:
              gameName = gameId;
          }
        }

        _allStats[gameId] = {
          'name': gameName,
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
    // Build export with structured per-game stats. The highscore list is
    // decoded from its stored JSON string into a real array so the export is
    // self-describing. Version 2.0 introduces the per-game highscore lists.
    final games = <String, dynamic>{};
    _allStats.forEach((gameId, gameData) {
      final stats = Map<String, dynamic>.from(gameData['stats'] as Map);
      final exportStatsMap = <String, dynamic>{};
      for (final entry in stats.entries) {
        if (entry.key == highscoreStorageKey) {
          exportStatsMap[entry.key] = _decodeHighscores(entry.value);
        } else {
          exportStatsMap[entry.key] = entry.value;
        }
      }
      games[gameId] = {
        'name': gameData['name'],
        'stats': exportStatsMap,
      };
    });

    final exportData = {
      'version': '2.0',
      'exportDate': DateTime.now().toIso8601String(),
      'games': games,
    };

    return jsonEncode(exportData);
  }

  /// Decode a stored highscore JSON string into a list; returns an empty list
  /// for anything unparseable.
  List<dynamic> _decodeHighscores(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  /// Export the stats to a file the user chooses via the system file picker
  /// (SAF on Android — Google Drive and other providers appear as
  /// Export the stats via `file_picker`'s saveFile, mirroring the import flow.
  /// On Android (SAF) the user picks a destination, so Google Drive and other
  /// providers are available. On web the file is downloaded by the browser
  /// (file_picker's web implementation has no location dialog).
  ///
  /// A fresh timestamped filename is used each time, so on Android the picker
  /// always creates a new file rather than overwriting one in place (avoiding a
  /// known file_picker Android truncation issue when a shorter payload replaces
  /// a longer existing file).
  Future<void> exportStatsToFile(BuildContext context) async {
    final jsonData = await exportStats();
    final fileName = _generateFileName();

    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(jsonData)),
        mimeType: 'application/json',
        dialogTitle: 'Statistik exportieren',
      );

      if (!context.mounted) return;
      if (uri == null) {
        // User cancelled the picker — nothing to report.
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statistik erfolgreich exportiert')),
      );
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
      PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.any,
        dialogTitle: 'Statistik importieren',
      );

      if (pickedFile != null) {
        String jsonData;

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          jsonData = String.fromCharCodes(bytes);
        } else {
          final file = File(pickedFile.path!);
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
        if (key == highscoreStorageKey) {
          // The highscore list is stored as a JSON string inside the game's
          // container; re-encode the imported array.
          await storage.write(key, jsonEncode(stats[key]));
        } else {
          await storage.write(key, stats[key]);
        }
      }
    }

    await loadAllStats();
  }
}
