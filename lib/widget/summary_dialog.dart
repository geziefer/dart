import 'package:flutter/material.dart';
import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';

class SummaryDialog extends StatelessWidget {
  final List<SummaryLine> lines;
  final VoidCallback? onOk;

  const SummaryDialog({
    super.key,
    required this.lines,
    this.onOk,
  });

  Widget _buildMatrixTable(Map<String, dynamic> matrixData, BuildContext context) {
    List<String> gameNames = matrixData['gameNames'];
    List<int> gameResults = matrixData['gameResults'];
    List<String> badgeNames = matrixData['badgeNames'];
    List<List<int>> badgeThresholds = matrixData['badgeThresholds'];

    return Container(
      margin: const EdgeInsets.all(10),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        columnWidths: const {
          0: FixedColumnWidth(120),
          1: FixedColumnWidth(40),
          2: FixedColumnWidth(40),
          3: FixedColumnWidth(40),
          4: FixedColumnWidth(40),
          5: FixedColumnWidth(40),
          6: FixedColumnWidth(40),
        },
        children: [
          // Header row
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text('Spiel', style: matrixHeaderTextStyle(context)),
              ),
              ...badgeNames.map((badge) => Padding(
                padding: const EdgeInsets.all(4),
                child: Text(badge, textAlign: TextAlign.center, style: matrixHeaderTextStyle(context)),
              )),
            ],
          ),
          // Game rows
          ...gameNames.asMap().entries.map((entry) {
            int gameIndex = entry.key;
            String gameName = entry.value;
            int gameResult = gameResults[gameIndex];
            
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(gameName, style: matrixGameNameTextStyle(context)),
                ),
                ...badgeThresholds[gameIndex].map((threshold) {
                  bool isAchieved;
                  if (gameIndex == 3) { // 501 Checkout (lower is better)
                    isAchieved = gameResult <= threshold && gameResult > 0;
                  } else {
                    isAchieved = gameResult >= threshold;
                  }
                  
                  return Container(
                    color: isAchieved ? Colors.green.withValues(alpha: 0.3) : null,
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      threshold.toString(),
                      textAlign: TextAlign.center,
                      style: matrixCellTextStyle(context),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              child: Text(
                "Zusammenfassung",
                style: endSummaryHeaderTextStyle(context),
                textAlign: TextAlign.center,
              ),
            ),
            ...lines.map((line) => line.isMatrix
                ? _buildMatrixTable(line.matrixData!, context)
                : line.isFinalBadge
                    ? Container(
                        margin: const EdgeInsets.all(20),
                        child: Text(
                          line.value,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 48),
                            fontFamily: "NotoColorEmoji",
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10),
                        child: line.checkSymbol != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    line.label.isEmpty
                                        ? line.value
                                        : '${line.label}: ${line.value}',
                                    style: line.emphasized
                                        ? endSummaryEmphasizedTextStyle(context)
                                        : endSummaryTextStyle(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    line.checkSymbol!,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                                          context, 32),
                                      fontFamily: "NotoColorEmoji",
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                line.label.isEmpty
                                    ? line.value
                                    : '${line.label}: ${line.value}',
                                style: line.emphasized
                                    ? endSummaryEmphasizedTextStyle(context)
                                    : endSummaryTextStyle(context),
                                textAlign: TextAlign.center,
                              ),
                      )),
            Container(
              margin: const EdgeInsets.all(10),
              child: TextButton(
                onPressed: onOk ??
                    () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                style: okButtonStyle(context),
                child: Text(
                  'OK',
                  style: okButtonTextStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryLine {
  final String label;
  final String value;
  final bool emphasized;
  final String? checkSymbol;
  final bool isMatrix;
  final bool isFinalBadge;
  final Map<String, dynamic>? matrixData;

  SummaryLine(this.label, this.value,
      {this.emphasized = false, 
       this.checkSymbol,
       this.isMatrix = false,
       this.isFinalBadge = false,
       this.matrixData});
}
