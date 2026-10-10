"""Render a compact, source-backed SVG excerpt from the engine VCD (stdlib only)."""
from pathlib import Path
from html import escape

root = Path(__file__).resolve().parents[1]
start, end = 50.5, 170.0  # microseconds; match/support/fall fixture
names = ('state_code', 'score', 'offset', 'shots')
labels = ('FSM state', 'Score', 'Fall offset / px', 'Resolved shots')
ids, data, scope = {}, {name: [] for name in names}, []
timestamp = 0.0
scale_us = None
in_timescale = False
units = {'s': 1e6, 'ms': 1e3, 'us': 1, 'ns': 1e-3, 'ps': 1e-6, 'fs': 1e-9}
for line in (root / 'build/engine.vcd').read_text().splitlines():
    parts = line.split()
    if not parts:
        continue
    if parts[0] == '$timescale':
        in_timescale = True
        parts = parts[1:]
    if in_timescale:
        if parts and parts[0].isdigit():
            scale_us = int(parts[0]) * units[parts[1]]
        if '$end' in parts:
            in_timescale = False
        continue
    if parts[0] == '$scope':
        scope.append(parts[2])
    elif parts[0] == '$upscope':
        scope.pop()
    elif parts[0] == '$var' and scope == ['tb_engine'] and parts[4] in names:
        ids[parts[3]] = parts[4]
    elif line.startswith('#'):
        assert scale_us is not None
        timestamp = int(line[1:]) * scale_us
        if timestamp > end:
            break
    elif line.startswith('b') and len(parts) == 2 and parts[1] in ids:
        value = parts[0][1:]
        if set(value) <= {'0', '1'}:
            data[ids[parts[1]]].append((timestamp, int(value, 2)))

assert len(ids) == len(names), 'Expected VCD signals are missing'
width, height, left, right = 1200, 420, 150, 1160
def x(t):
    return left + (t-start)/(end-start)*(right-left)

svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
       '<rect width="1200" height="420" fill="#111827"/>',
       '<style>text{font-family:monospace;fill:#cbd5e1;font-size:13px}.title{font-size:19px;fill:#d9f99d}</style>',
       '<text x="24" y="30" class="title">Dino Pop — match, score and disconnected-egg fall</text>',
       '<text x="24" y="54">GHDL simulation / synthetic frame ticks / fixture-driven regression</text>']
for tick in (60, 80, 100, 120, 140, 160):
    xx = x(tick)
    svg += [f'<path d="M{xx:.1f},76 V355" stroke="#334155"/>',
            f'<text x="{xx-12:.1f}" y="378">{tick}</text>']
for row, (name, label) in enumerate(zip(names, labels)):
    entries = data[name]
    previous = [value for t, value in entries if t <= start]
    current = previous[-1] if previous else 0
    selected = [(start, current)] + [(t,v) for t,v in entries if t > start]
    selected.append((end, selected[-1][1]))
    maximum = max(1, max(v for _, v in selected))
    base = 132 + row*72
    points = [f'M{x(start):.2f},{base-current/maximum*38:.2f}']
    for t,v in selected[1:]:
        points.append(f'H{x(t):.2f} V{base-v/maximum*38:.2f}')
    svg += [f'<text x="16" y="{base-18}">{escape(label)}</text>',
            f'<text x="16" y="{base+1}" fill="#64748b">range 0–{maximum}</text>',
            f'<path d="{" ".join(points)}" fill="none" stroke="#67e8f9" stroke-width="2"/>']
    for (t,v), (next_t,_) in zip(selected, selected[1:]):
        if x(next_t)-x(t)>32:
            svg.append(f'<text x="{x(t)+4:.1f}" y="{base-v/maximum*38-7:.1f}">{v}</text>')
svg += ['<text x="1010" y="399">Time / microseconds</text>',
        '<text x="24" y="403">State: 4 MATCH, 5 CLEAR, 6 SUPPORT, 7 FALL, 8 ADVANCE, 9 CHECK, 1 AIM</text>', '</svg>']
target = root / 'docs/images/waveform.svg'
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text('\n'.join(svg), encoding='utf-8')
print(target.relative_to(root))
