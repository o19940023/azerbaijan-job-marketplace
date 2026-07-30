import os

base = r'c:\Users\ramiz\Desktop\JobApp\compliance_site'

with open(os.path.join(base, 'app.js'), 'r', encoding='utf-8') as f:
    app_js = f.read()

with open(os.path.join(base, 'app.css'), 'r', encoding='utf-8') as f:
    app_css = f.read()

with open(os.path.join(base, 'index.html'), 'r', encoding='utf-8') as f:
    html = f.read()

# Replace external script with inline script
html = html.replace('<script src="app.js"></script>', f'<script>\n{app_js}\n</script>')

# Replace external CSS with inline CSS
html = html.replace('<link rel="stylesheet" href="app.css">', f'<style>\n{app_css}\n</style>')

with open(os.path.join(base, 'index.html'), 'w', encoding='utf-8') as f:
    f.write(html)

print("Done! app.js and app.css inlined into index.html")
