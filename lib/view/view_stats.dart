import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/controller/controller_stats.dart';
import 'package:dart/view/view_scolia_settings.dart';
import 'package:dart/widget/game_layout.dart';

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
    final statKeys = stats.keys.toList();

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
          ],
        ),
      ),
    );
  }
  
  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}
