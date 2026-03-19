import re

def count_conflicts(file_path, out_file):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = re.compile(r'<<<<<<< HEAD\r?\n(.*?)\r?\n=======\r?\n(.*?)\r?\n>>>>>>>[^\n]*\r?\n', re.DOTALL)
    matches = list(pattern.finditer(content))
    heads = len(re.findall(r'<<<<<<< HEAD', content))
    out_file.write(f"{file_path}: {len(matches)} matches, {heads} HEADs\n")

with open("out2.txt", "w", encoding="utf-8") as f:
    count_conflicts(r"lib\screens\home\home_screen_content.dart", f)
    count_conflicts(r"lib\screens\recipe\recipe_detail_screen.dart", f)
