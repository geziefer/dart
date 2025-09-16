import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart/widget/menu.dart';

class ControllerStats extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _allStats = {};
  final bool _isLoading = false;

  Map<String, Map<String, dynamic>> get allStats => _allStats;
  bool get isLoading => _isLoading;

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
  }

  Future<String> exportStats() async {
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'games': _allStats,
    };
    
    return jsonEncode(exportData);
  }

  Future<void> shareExportedStats() async {
    final jsonData = await exportStats();
    
    if (kIsWeb) {
      // On web, copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonData));
    } else {
      // On mobile, use share functionality
      await SharePlus.instance.share(ShareParams(text: jsonData));
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
