#!/usr/bin/env python3
import os
import re

# List of view files to refactor (excluding already done ones)
view_files = [
    'view_bigts.dart',
    'view_bobs27.dart', 
    'view_catchxx.dart',
    'view_check121.dart',
    'view_creditfinish.dart',
    'view_cricket.dart',
    'view_doublepath.dart',
    'view_killbull.dart',
    'view_shootx.dart',
    'view_speedbull.dart',
    'view_twodarts.dart',
    'view_updown.dart',
    'view_xxxcheckout.dart',
    'view_finishes.dart'
]

def refactor_view_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Replace header import with game_layout import
    content = re.sub(r"import 'package:dart/widget/header.dart';", 
                     "import 'package:dart/widget/game_layout.dart';", content)
    
    # Find the return Scaffold pattern and replace with GameLayout
    scaffold_pattern = r'return Scaffold\(\s*backgroundColor: const Color\.fromARGB\(255, 17, 17, 17\),\s*body: Column\(\s*children: \[\s*// ########## Top row.*?\n\s*const SizedBox\(height: 20\),\s*Expanded\(\s*flex: 10,\s*child: Header\(gameName: title\),\s*\),\s*// ########## Main part.*?\n\s*Expanded\(\s*flex: 70,\s*child: (.*?)\s*\),\s*// ########## Bottom row.*?\n\s*Expanded\(\s*flex: 20,\s*child: (.*?)\s*\),\s*\],\s*\),\s*\);'
    
    def replace_scaffold(match):
        main_content = match.group(1).strip()
        stats_content = match.group(2).strip()
        
        return f'''return GameLayout(
      title: title,
      mainContent: {main_content},
      statsContent: {stats_content},
    );'''
    
    content = re.sub(scaffold_pattern, replace_scaffold, content, flags=re.DOTALL)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"Refactored {filepath}")

# Process each view file
base_path = '/Users/aru/projects/dart/lib/view/'
for view_file in view_files:
    filepath = os.path.join(base_path, view_file)
    if os.path.exists(filepath):
        refactor_view_file(filepath)
    else:
        print(f"File not found: {filepath}")

print("Refactoring complete!")
