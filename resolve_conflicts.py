import sys
import re

def resolve_file(file_path, resolutions):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = re.compile(r'<<<<<<< HEAD\r?\n(.*?)\r?\n=======\r?\n(.*?)\r?\n>>>>>>>[^\n]*\r?\n', re.DOTALL)
    
    matches = list(pattern.finditer(content))
    if len(matches) != len(resolutions):
        print(f"Error in {file_path}: Found {len(matches)} conflicts, but provided {len(resolutions)} resolutions.")
        for m in matches:
            print(f"Conflict at character {m.start()}")
        return False
    
    for match, res in reversed(list(zip(matches, resolutions))):
        head_content = match.group(1)
        theirs_content = match.group(2)
        
        replacement = ""
        if res == 'HEAD':
            replacement = head_content + "\n"
        elif res == 'THEIRS':
            replacement = theirs_content + "\n"
        elif callable(res):
            replacement = res(head_content, theirs_content) + "\n"
        elif isinstance(res, str):
            replacement = res + "\n"
        
        content = content[:match.start()] + replacement + content[match.end():]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Resolved {file_path}")
    return True

home_path = r"lib\screens\home\home_screen_content.dart"
num_conflicts_home = len(re.findall(r'<<<<<<< HEAD', open(home_path, encoding='utf-8').read()))
print(f"Found {num_conflicts_home} conflicts in {home_path}")
if num_conflicts_home > 0:
    if not resolve_file(home_path, ['THEIRS'] * num_conflicts_home):
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
import '../../controllers/shopping_list_controller.dart';"""

def recipe_conflict_4(h, t):
    return t

def recipe_conflict_5(h, t):
    return h

def recipe_conflict_8(h, t):
    return h

def recipe_conflict_9(h, t):
    return h

def recipe_conflict_10(h, t):
    # Need to replace color to add dark mode
    return h.replace('color: Colors.white.withOpacity(0.9),', 'color: isDark\n            ? const Color(0xFF1A1A1A).withOpacity(0.95)\n            : Colors.white.withOpacity(0.9),')

resolutions_recipe = [
    recipe_conflict_1,
    'HEAD',
    'THEIRS',
    recipe_conflict_4,
    recipe_conflict_5,
    'THEIRS',
    'THEIRS',
    recipe_conflict_8,
    recipe_conflict_9,
    recipe_conflict_10,
    'THEIRS',
]

num_conflicts_recipe = len(re.findall(r'<<<<<<< HEAD', open(recipe_path, encoding='utf-8').read()))
print(f"Found {num_conflicts_recipe} conflicts in {recipe_path}")
if num_conflicts_recipe > 0:
    if not resolve_file(recipe_path, resolutions_recipe):
        sys.exit(1)
