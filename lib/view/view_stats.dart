import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/controller/controller_stats.dart';
import 'package:dart/widget/header.dart';

class ViewStats extends StatelessWidget {
  const ViewStats({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ControllerStats>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          const Header(gameName: 'Statistik'),
          Expanded(
            child: FutureBuilder(
              future: controller.loadAllStats(),
              builder: (context, snapshot) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var gameId in controller.allStats.keys)
                          _buildGameStats(gameId, controller.allStats[gameId]!),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  controller.shareExportedStats(context),
                              child: const Text('Teilen'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  controller.saveExportedStatsToFile(context),
                              child: const Text('Exportieren'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats(String gameId, Map<String, dynamic> gameData) {
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
            for (var key in (gameData['stats'] as Map<String, dynamic>).keys)
              Text('$key: ${gameData['stats'][key]}'),
          ],
        ),
      ),
    );
  }
}
