import 'package:flutter/material.dart';
import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';

class RTCXModeDialog extends StatefulWidget {
  const RTCXModeDialog({super.key});

  @override
  State<RTCXModeDialog> createState() => _RTCXModeDialogState();
}

class _RTCXModeDialogState extends State<RTCXModeDialog> {
  final List<Map<String, dynamic>> modes = [
    {'id': 'RTCD', 'name': 'Double', 'max': 20},
    {'id': 'RTCT', 'name': 'Triple', 'max': 20},
  ];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveUtils.isPhoneSize(context);
    final itemMargin = isPhone ? 2.0 : 10.0;
    final containerPadding = isPhone ? 10.0 : 20.0;
    
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isPhone ? 300.0 : 0.0,
          ),
          child: Container(
            padding: EdgeInsets.all(containerPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.all(itemMargin),
                  child: Text(
                    'Welcher Spielmodus?',
                    style: endSummaryHeaderTextStyle(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...modes.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> mode = entry.value;
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
                              mode['name'],
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
                        onPressed: () => Navigator.of(context).pop(modes[selectedIndex]),
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
      ),
    );
  }
}
