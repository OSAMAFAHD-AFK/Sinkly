"""Builds Plus Jakarta Sans + colour emoji fonts for the store screen capture.

The Flutter test engine has no font fallback, so emoji in the app would render
as boxes. This copies the emoji the app uses (Windows Segoe UI Emoji, COLR)
into each Plus Jakarta Sans weight. Output: build/store_fonts/*.ttf, picked up
by capture_store_screens_test.dart. Only used for screenshots, never shipped.

Run from the project root:  python tool/store_assets/build_emoji_fonts.py
"""
import glob
import os

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.ttLib.scaleUpem import scale_upem

EMOJI_FONT = 'C:/Windows/Fonts/seguiemj.ttf'
OUT = 'build/store_fonts'
WEIGHTS = ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']


def used_codepoints():
    cps = {0xFE0F, 0x200D}
    for path in glob.glob('lib/**/*.dart', recursive=True) + ['assets/translations/en.json']:
        with open(path, encoding='utf8') as f:
            cps.update(ord(ch) for ch in f.read() if ord(ch) >= 0x2190)
    return cps


def main():
    os.makedirs(OUT, exist_ok=True)
    emoji = TTFont(EMOJI_FONT)
    emoji_cmap = emoji.getBestCmap()
    latin = TTFont('assets/google_fonts/PlusJakartaSans-Regular.ttf').getBestCmap()
    wanted = sorted(cp for cp in used_codepoints() if cp in emoji_cmap and cp not in latin)
    options = subset.Options()
    options.layout_features = []
    options.drop_tables += ['GSUB', 'GPOS', 'GDEF', 'kern', 'meta']
    options.notdef_outline = False
    sub = subset.Subsetter(options)
    sub.populate(unicodes=wanted)
    sub.subset(emoji)
    emoji_cmap = emoji.getBestCmap()
    emoji_names = [g for g in emoji.getGlyphOrder() if g != '.notdef']

    for weight in WEIGHTS:
        base = TTFont(f'assets/google_fonts/PlusJakartaSans-{weight}.ttf')
        scale_upem(base, emoji['head'].unitsPerEm)
        base_cmap = base.getBestCmap()
        clash = set(base.getGlyphOrder()) & set(emoji_names)
        assert not clash, clash

        order = base.getGlyphOrder() + emoji_names
        glyf, hmtx = base['glyf'], base['hmtx']
        for name in emoji_names:
            glyf.glyphs[name] = emoji['glyf'][name]
            hmtx.metrics[name] = emoji['hmtx'].metrics[name]
        base.setGlyphOrder(order)
        glyf.setGlyphOrder(order)
        for table in base['cmap'].tables:
            if table.isUnicode():
                for cp, name in emoji_cmap.items():
                    if cp not in base_cmap and (table.format != 4 or cp <= 0xFFFF):
                        table.cmap[cp] = name
        # A format-4 table cannot hold astral emoji: make sure a format-12 one exists.
        if not any(t.format == 12 for t in base['cmap'].tables):
            from fontTools.ttLib.tables._c_m_a_p import CmapSubtable
            t12 = CmapSubtable.newSubtable(12)
            t12.platformID, t12.platEncID, t12.language = 3, 10, 0
            t12.cmap = dict(base.getBestCmap())
            t12.cmap.update({cp: n for cp, n in emoji_cmap.items() if cp not in base_cmap})
            base['cmap'].tables.append(t12)
        base['COLR'] = emoji['COLR']
        base['CPAL'] = emoji['CPAL']
        base.save(f'{OUT}/PlusJakartaSans-{weight}.ttf')
        print('wrote', weight, len(emoji_names), 'emoji glyphs')


if __name__ == '__main__':
    main()
