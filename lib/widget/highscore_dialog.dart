import 'package:dart/services/highscore_service.dart';
import 'package:dart/services/storage_service.dart';
import 'package:flutter/material.dart';

/// Dialog showing a game's Top-10 highscore list (ranks 1-10). Empty ranks are
/// shown as placeholders so the full 1-10 table is always visible, as
/// requested. Loads the list fresh from the game's own storage container.
class HighscoreDialog extends StatelessWidget {
  final String gameId;
  final String gameName;

  /// Optional injected entries (used by tests to avoid real storage).
  final List<HighscoreEntry>? entries;

  const HighscoreDialog({
    super.key,
    required this.gameId,
    required this.gameName,
    this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final config = highscoreConfigs[gameId];
    final list = entries ??
        (config == null
            ? <HighscoreEntry>[]
            : HighscoreService(StorageService(gameId), config).getHighscores());

    return Dialog(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white38),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Color.fromARGB(255, 215, 198, 132)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Highscores – $gameName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              if (config == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Keine Highscores für dieses Spiel',
                      style: TextStyle(color: Colors.white70)),
                )
              else
                _buildTable(context, config, list),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen',
                    style: TextStyle(color: Color.fromARGB(255, 215, 198, 132))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable(
      BuildContext context, HighscoreConfig config, List<HighscoreEntry> list) {
    const headerStyle = TextStyle(
        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold);
    const cellStyle = TextStyle(color: Colors.white, fontSize: 14);

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(40),
        3: FixedColumnWidth(100),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          const Padding(
              padding: EdgeInsets.all(4), child: Text('#', style: headerStyle)),
          Padding(
              padding: const EdgeInsets.all(4),
              child: Text(config.label, style: headerStyle)),
          Padding(
              padding: const EdgeInsets.all(4),
              child: Text(config.label2 ?? '', style: headerStyle)),
          const Padding(
              padding: EdgeInsets.all(4),
              child: Text('Datum', style: headerStyle)),
        ]),
        for (int i = 0; i < maxHighscoreEntries; i++)
          TableRow(children: [
            Padding(
                padding: const EdgeInsets.all(4),
                child: Text('${i + 1}', style: cellStyle)),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                i < list.length ? config.formatValue(list[i].value) : '—',
                style: i == 0 && i < list.length
                    ? cellStyle.copyWith(
                        color: const Color.fromARGB(255, 215, 198, 132),
                        fontWeight: FontWeight.bold)
                    : cellStyle,
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                    i < list.length ? config.formatValue2(list[i].value2) : '',
                    style: cellStyle)),
            Padding(
                padding: const EdgeInsets.all(4),
                child: Text(i < list.length ? list[i].date : '',
                    style: cellStyle)),
          ]),
      ],
    );
  }
}
