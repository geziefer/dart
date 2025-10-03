import 'package:flutter/material.dart';
import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';

class FinishesRangeDialog extends StatefulWidget {
  const FinishesRangeDialog({super.key});

  @override
  State<FinishesRangeDialog> createState() => _FinishesRangeDialogState();
}

class _FinishesRangeDialogState extends State<FinishesRangeDialog> {
  final List<Map<String, int>> ranges = [
    {'from': 61, 'to': 80},
    {'from': 81, 'to': 107},
    {'from': 108, 'to': 135},
    {'from': 136, 'to': 170},
  ];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveUtils.isPhoneSize(context);
    final itemMargin = isPhone ? 5.0 : 10.0;
    final containerPadding = isPhone ? 10.0 : 20.0;
    
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      child: IntrinsicWidth(
        child: Container(
          padding: EdgeInsets.all(containerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              margin: EdgeInsets.all(itemMargin),
              child: Text(
                'Finishes Bereich wählen',
                style: endSummaryHeaderTextStyle(context),
                textAlign: TextAlign.center,
              ),
            ),
            ...ranges.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, int> range = entry.value;
              return Container(
                margin: EdgeInsets.all(itemMargin),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: selectedIndex == index 
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedIndex == index 
                            ? Colors.blue 
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                            color: selectedIndex == index 
                                ? Colors.blue 
                                : Colors.transparent,
                          ),
                          child: selectedIndex == index
                              ? const Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${range['from']}-${range['to']}',
                          style: endSummaryTextStyle(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Container(
              margin: EdgeInsets.all(itemMargin),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: okButtonStyle(context),
                    child: Text('Abbrechen', style: okButtonTextStyle(context)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(ranges[selectedIndex]),
                    style: okButtonStyle(context),
                    child: Text('Start', style: okButtonTextStyle(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
