import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/controller/controller_stats.dart';
import 'package:dart/services/highscore_service.dart';
import 'package:dart/services/result_history_service.dart';
import 'package:dart/services/throw_log_service.dart';
import 'package:dart/view/view_scolia_settings.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/heatmap_view.dart';
import 'package:dart/widget/trend_sparkline.dart';

class ViewStats extends StatelessWidget {
  const ViewStats({super.key});

  @override
  Widget build(BuildContext context) {
    const statsButtonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.black),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      side: WidgetStatePropertyAll(
          BorderSide(color: Colors.white38)),
    );
    return Consumer<ControllerStats>(
      builder: (context, controller, child) {
        // Refresh stats when view is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.refresh();
        });
        
        return GameLayout(
          title: 'Statistik / Einstellungen',
          mainContent: controller.allStats.isEmpty
              ? const Center(
                  child: Text(
                    'Keine Statistik vorhanden',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var gameId in controller.allStats.keys.toList()
                          ..sort((a, b) => controller.allStats[a]!['name']
                              .toString()
                              .compareTo(controller.allStats[b]!['name'].toString())))
                          _buildGameStats(context, controller, gameId, controller.allStats[gameId]!),
                      ],
                    ),
                  ),
                ),
          statsContent: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: OutlinedButton(
                          style: statsButtonStyle,
                          onPressed: () => controller.shareExportedStats(context),
                          child: const Text('Teilen'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: OutlinedButton(
                          style: statsButtonStyle,
                          onPressed: () => controller.saveExportedStatsToFile(context),
                          child: const Text('Exportieren'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: OutlinedButton(
                          style: statsButtonStyle,
                          onPressed: () => controller.importStatsFromFile(context, (jsonData) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Import bestätigen'),
                                content: const Text('Willst du wirklich die Statistik überschreiben?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Nein'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await controller.importStats(jsonData);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Statistik erfolgreich importiert')),
                                        );
                                      }
                                    },
                                    child: const Text('Ja'),
                                  ),
                                ],
                              ),
                            );
                          }),
                          child: const Text('Import'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: OutlinedButton(
                          style: statsButtonStyle,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ViewScoliaSettings(),
                            ),
                          ),
                          child: const Text('Scolia'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameStats(BuildContext context, ControllerStats controller,
      String gameId, Map<String, dynamic> gameData) {
    final stats = gameData['stats'] as Map<String, dynamic>;
    // The highscore list is rendered separately below; keep it out of the
    // generic key/value grid (it is stored as a JSON string).
    final statKeys =
        stats.keys.where((k) => k != highscoreStorageKey).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white38),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gameData['name'] as String,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.scatter_plot,
                      color: Color.fromARGB(255, 215, 198, 132)),
                  tooltip: 'Wurfbild (Heatmap)',
                  onPressed: () => _openHeatmap(context, gameId,
                      gameData['name'] as String),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Statistik löschen',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Statistik löschen'),
                      content: Text(
                          'Statistik für "${gameData['name']}" wirklich löschen?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Nein'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            controller.deleteStatsForGame(gameId);
                          },
                          child: const Text('Ja',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            // Display stats in rows with fixed 6 columns
            for (int i = 0; i < statKeys.length; i += 6)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    for (int j = 0; j < 6; j++)
                      Expanded(
                        child: j + i < statKeys.length
                            ? Text(
                                '${statKeys[i + j]}: ${_formatValue(stats[statKeys[i + j]])}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
                                textAlign: TextAlign.left,
                              )
                            : const SizedBox(),
                      ),
                  ],
                ),
              ),
            _buildHighscoreSection(gameId, stats),
            _buildTrendSection(gameId, stats),
          ],
        ),
      ),
    );
  }

  /// Open a dialog showing the throw-landing heatmap for [gameId], reading the
  /// darts from the in-memory [ThrowLogService]. Shows a graceful empty state
  /// when no coordinate data has been logged yet (e.g. numpad-only games or
  /// before any real-board Scolia session).
  void _openHeatmap(BuildContext context, String gameId, String gameName) {
    final darts =
        context.read<ThrowLogService?>()?.dartsForGame(gameId) ?? const [];
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color.fromARGB(255, 17, 17, 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white38),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: HeatmapView(darts: darts, title: 'Wurfbild – $gameName'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Schließen',
                      style:
                          TextStyle(color: Color.fromARGB(255, 215, 198, 132))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the highscore block for a game: rank #1 shown inline, ranks 2-10 in
  /// an expandable section. Returns an empty widget when the game has no
  /// highscore configuration.
  Widget _buildHighscoreSection(String gameId, Map<String, dynamic> stats) {
    final config = highscoreConfigs[gameId];
    if (config == null) return const SizedBox.shrink();

    final entries = _parseHighscores(stats[highscoreStorageKey]);

    const headerStyle = TextStyle(
        color: Color.fromARGB(255, 215, 198, 132),
        fontSize: 13,
        fontWeight: FontWeight.bold);
    const entryStyle = TextStyle(color: Colors.white70, fontSize: 12);

    String formatEntry(int rank, HighscoreEntry e) {
      final v = config.formatValue(e.value);
      final v2 = config.formatValue2(e.value2);
      final v2Part = (config.label2 != null && v2.isNotEmpty)
          ? '  ${config.label2}: $v2'
          : '';
      return '$rank. ${config.label}: $v$v2Part  (${e.date})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24),
        Row(
          children: [
            const Icon(Icons.emoji_events,
                color: Color.fromARGB(255, 215, 198, 132), size: 16),
            const SizedBox(width: 6),
            Text(
              entries.isEmpty
                  ? 'Highscore: —'
                  : 'Highscore  ${formatEntry(1, entries.first)}',
              style: headerStyle,
            ),
          ],
        ),
        if (entries.length > 1)
          Theme(
            data: ThemeData.dark().copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(left: 22, bottom: 8),
              title: const Text('Plätze 2-10',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              iconColor: Colors.white54,
              collapsedIconColor: Colors.white54,
              children: [
                for (int i = 1; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(formatEntry(i + 1, entries[i]),
                          style: entryStyle),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build the trend sparkline block for a game from its stored result history.
  /// Returns an empty widget when fewer than two results exist.
  Widget _buildTrendSection(String gameId, Map<String, dynamic> stats) {
    final entries = ResultHistoryService.decode(stats[resultHistoryKey]);
    if (entries.length < 2) return const SizedBox.shrink();

    final higherIsBetter = highscoreConfigs[gameId]?.higherIsBetter ?? true;
    final values = entries.map((e) => e.value).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.show_chart, color: Colors.white54, size: 16),
          const SizedBox(width: 6),
          const Text('Verlauf',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 10),
          TrendSparkline(values: values, higherIsBetter: higherIsBetter),
        ],
      ),
    );
  }

  List<HighscoreEntry> _parseHighscores(dynamic raw) {
    if (raw is! String || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => HighscoreEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
  
  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}
