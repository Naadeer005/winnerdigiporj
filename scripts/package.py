"""Package only source, project settings and submission documentation."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
target = root / 'build/dino-pop-source.zip'
target.parent.mkdir(exist_ok=True)
paths = [root / 'README.md', root / '.gitignore']
for folder in ('rtl', 'sim', 'scripts', 'docs'):
    paths.extend(p for p in (root / folder).rglob('*')
                 if p.is_file() and '__pycache__' not in p.parts)
paths.extend(root / 'quartus' / name for name in
             ('dino_pop.qpf', 'dino_pop.qsf', 'dino_pop.sdc'))
with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(paths):
        archive.write(path, path.relative_to(root).as_posix())
print(target)
