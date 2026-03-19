import re
content = open(r'lib\screens\home\home_screen_content.dart', encoding='utf-8').read()
h = len(re.findall(r'<<<<<<< HEAD', content))
e = len(re.findall(r'=======', content))
t = len(re.findall(r'>>>>>>>', content))
with open("out4.txt", "w", encoding="utf-8") as f:
    f.write(f"home: HEAD={h}, ===={e}, >>>={t}\n")

content2 = open(r'lib\screens\recipe\recipe_detail_screen.dart', encoding='utf-8').read()
h2 = len(re.findall(r'<<<<<<< HEAD', content2))
e2 = len(re.findall(r'=======', content2))
t2 = len(re.findall(r'>>>>>>>', content2))
with open("out4.txt", "a", encoding="utf-8") as f:
    f.write(f"recipe: HEAD={h2}, ===={e2}, >>>={t2}\n")
