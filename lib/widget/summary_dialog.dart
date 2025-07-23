import 'package:flutter/material.dart';
import 'package:dart/styles.dart';

class SummaryDialog extends StatelessWidget {
  final List<SummaryLine> lines;
  final VoidCallback? onOk;

  const SummaryDialog({
    super.key,
    required this.lines,
    this.onOk,
  });

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
                style: endSummaryHeaderTextStyle,
                textAlign: TextAlign.center,
              ),
            ),
            ...lines.map((line) => Container(
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
                                  ? endSummaryEmphasizedTextStyle
                                  : endSummaryTextStyle,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              line.checkSymbol!,
                              style: const TextStyle(
                                fontSize: 32,
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
                              ? endSummaryEmphasizedTextStyle
                              : endSummaryTextStyle,
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
                style: okButtonStyle,
                child: const Text(
                  'OK',
                  style: okButtonTextStyle,
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
  final String? checkSymbol; // Optional check symbol (emoji) to display after the text

  SummaryLine(this.label, this.value, {this.emphasized = false, this.checkSymbol});
}
