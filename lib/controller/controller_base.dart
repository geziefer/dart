import 'package:flutter/material.dart';

abstract class ControllerBase extends ChangeNotifier {
  String createMultilineString(List list1, List list2, String prefix,
      String postfix, List optional, int limit, bool enumerate) {
    String result = "";
    String enhancedPrefix = "";
    String enhancedPostfix = "";
    String optionalStatus = "";
    String listText = "";
    // max limit entries
    int to = list1.length;
    int from = (to > limit) ? to - limit : 0;
    for (int i = from; i < list1.length; i++) {
      enhancedPrefix = enumerate
          ? '$prefix ${i + 1}: '
          : (prefix.isNotEmpty ? '$prefix: ' : '');
      enhancedPostfix = postfix.isNotEmpty ? ' $postfix' : '';
      if (optional.isNotEmpty) {
        optionalStatus = optional[i] ? " ✅" : " ❌";
      }
      listText = list2.isEmpty ? '${list1[i]}' : '${list1[i]}: ${list2[i]}';
      result += '$enhancedPrefix$listText$enhancedPostfix$optionalStatus\n';
    }
    // delete last line break if any
    if (result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
