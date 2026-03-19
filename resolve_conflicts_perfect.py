import sys
import os

def resolve_file(file_path, resolutions):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []
    i = 0
    conflict_idx = 0
    
    while i < len(lines):
        if lines[i].startswith('<<<<<<< HEAD'):
            head_lines = []
            theirs_lines = []
            i += 1
            while not lines[i].startswith('======='):
                head_lines.append(lines[i])
                i += 1
            i += 1
            while not lines[i].startswith('>>>>>>>'):
                theirs_lines.append(lines[i])
                i += 1
            
            h_str = "".join(head_lines)
            t_str = "".join(theirs_lines)
            
            res = resolutions[conflict_idx]
            conflict_idx += 1
            
            if res == 'HEAD':
                out_lines.append(h_str)
            elif res == 'THEIRS':
                out_lines.append(t_str)
            elif callable(res):
                out_lines.append(res(h_str, t_str))
            elif isinstance(res, str):
                if res and not res.endswith('\n'):
                    res += '\n'
                out_lines.append(res)
        else:
            out_lines.append(lines[i])
        i += 1
        
    if conflict_idx != len(resolutions):
        print(f"Error {file_path}: Expected {len(resolutions)} but found {conflict_idx}")
        return False

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)
        
    print(f"Resolved {file_path}")
    return True


home_path = r"lib\screens\home\home_screen_content.dart"
if not resolve_file(home_path, ['THEIRS'] * 7):
    sys.exit(1)

recipe_path = r"lib\screens\recipe\recipe_detail_screen.dart"

def recipe_conflict_1(h, t):
    return """import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/cooking_controller.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/shopping_list_controller.dart';\n"""

def recipe_conflict_11(h, t):
    return h.replace('color: Colors.white.withOpacity(0.9),', 'color: isDark\n            ? const Color(0xFF1A1A1A).withOpacity(0.95)\n            : Colors.white.withOpacity(0.9),')

resolutions_recipe = [
    recipe_conflict_1,   # 1
    'HEAD',              # 2
    'HEAD',              # 3
    'THEIRS',            # 4
    'THEIRS',            # 5
    'HEAD',              # 6
    'THEIRS',            # 7
    'THEIRS',            # 8
    'HEAD',              # 9
    'HEAD',              # 10
    recipe_conflict_11,  # 11
    'THEIRS',            # 12
]

if not resolve_file(recipe_path, resolutions_recipe):
    sys.exit(1)

print("All conflicts resolved!")
