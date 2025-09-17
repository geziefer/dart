import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/controller/controller_stats.dart';
import 'package:dart/widget/header.dart';

class ViewStats extends StatelessWidget {
  const ViewStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ControllerStats>(
      builder: (context, controller, child) {
        // Refresh stats when view is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.refresh();
        });
        
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 17, 17, 17),
          body: Column(
            children: [
              // Header section
              const SizedBox(height: 20),
              Expanded(
                flex: 1,
                child: const Header(gameName: 'Statistik'),
              ),
              
              // Content section
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    const Divider(color: Colors.white, thickness: 3),
                    Expanded(
                      child: controller.allStats.isEmpty
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
                                      _buildGameStats(gameId, controller.allStats[gameId]!),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              // Footer section
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const Divider(color: Colors.white, thickness: 3),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: () => controller.shareExportedStats(context),
                                child: const Text('Teilen'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: () => controller.saveExportedStatsToFile(context),
                                child: const Text('Exportieren'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
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
                        ],
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

  Widget _buildGameStats(String gameId, Map<String, dynamic> gameData) {
    final stats = gameData['stats'] as Map<String, dynamic>;
    final statKeys = stats.keys.toList();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gameData['name'] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
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
                                style: const TextStyle(fontSize: 12),
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
