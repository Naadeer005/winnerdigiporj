"""Convert simulator P3 captures into PNG files using only Python's stdlib."""
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs' / 'images'
OUT.mkdir(parents=True, exist_ok=True)


def chunk(tag, payload):
    return (struct.pack('!I', len(payload)) + tag + payload
            + struct.pack('!I', zlib.crc32(tag + payload)))


for name in ('title', 'gameplay', 'win', 'lose'):
    tokens = (ROOT / 'build' / f'{name}.ppm').read_text().split()
    assert tokens[0] == 'P3' and tokens[3] == '255'
    width, height = map(int, tokens[1:3])
    pixels = bytes(map(int, tokens[4:]))
    assert len(pixels) == width * height * 3
    scanlines = b''.join(b'\0' + pixels[row * width * 3:(row + 1) * width * 3]
                         for row in range(height))
    png = (b'\x89PNG\r\n\x1a\n'
           + chunk(b'IHDR', struct.pack('!2I5B', width, height, 8, 2, 0, 0, 0))
           + chunk(b'IDAT', zlib.compress(scanlines, 9)) + chunk(b'IEND', b''))
    target = OUT / f'{name}.png'
    target.write_bytes(png)
    print(target.relative_to(ROOT))
