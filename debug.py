import sys
import re

def count_conflicts(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = re.compile(r'<<<<<<< HEAD\r?\n(.*?)\r?\n=======\r?\n(.*?)\r?\n>>>>>>>[^\n]*\r?\n', re.DOTALL)
    matches = list(pattern.finditer(content))
    print(f"{file_path}: {len(matches)} matches")
    heads = len(re.findall(r'<<<<<<< HEAD', content))
    print(f"{file_path}: {heads} HEADs")
    
count_conflicts(r"lib\screens\home\home_screen_content.dart")
count_conflicts(r"lib\screens\recipe\recipe_detail_screen.dart")
