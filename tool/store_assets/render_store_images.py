"""Composes the Google Play graphics from the captured app screens.

1. python tool/store_assets/build_emoji_fonts.py
2. flutter test tool/store_assets/capture_store_screens_test.dart   (SINK_PHOTO=<png> optional)
3. python tool/store_assets/render_store_images.py

Writes store/google_play/feature_graphic_1024x500.png and
store/google_play/screenshots/NN_*.png (1080x1920, 9:16). Needs Microsoft Edge.
"""
import os
import pathlib
import subprocess
import time

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SHOTS = ROOT / 'build/store_screens'
WORK = ROOT / 'build/store_html'
OUT = ROOT / 'store/google_play'
EDGE = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
FONTS = (ROOT / 'assets/google_fonts').as_uri()

# order, file name, screen, headline (<b> = accent), subline, floating chips
SLIDES = [
    ('01_earn_your_scroll', 'home', 'Earn your scroll<br>with a <b>clean sink</b>',
     'Apps pause after meals. One photo of your clean sink brings them back.',
     [('heroine', 'heroine_wave')]),
    ('02_apps_pause_after_meals', 'lock_overlay', 'Meal’s over?<br>Your apps take a <b>break</b>',
     'The apps you chose pause the moment a meal ends. No willpower needed.',
     [('chip', 'right', 905, '🔒', 'Locked after dinner')]),
    ('03_choose_your_apps', 'apps', '<b>You choose</b><br>which apps pause',
     'Social, games, videos… everything else stays open.',
     [('chip', 'right', 1440, '✅', '6 apps selected')]),
    ('04_set_meals_once', 'plan', 'Set your meals once.<br><b>It runs itself.</b>',
     'Change times or apps anytime, even while locked.',
     [('chip', 'left', 1262, '⏰', 'Lock at 8:30 PM')]),
    ('05_guided_sink_sprint', 'sprint', 'A quick, guided<br><b>sink sprint</b>',
     'Pick your time, put on a song and race the water.',
     [('chip', 'left', 1445, '⏱️', 'You pick the time')]),
    ('06_one_photo_ai_check', 'verifying', 'One photo.<br><b>AI checks</b> your sink.',
     'Your photo is never stored. No account, no sign-up.',
     [('chip', 'right', 1300, '🛡️', 'Private by design')]),
    ('07_apps_back_guilt_free', 'celebrating', 'Apps back.<br><b>Guilt-free.</b>',
     'A sparkling kitchen, and every scroll truly earned.',
     [('chip', 'left', 640, '🎉', 'Unlocked in 4:12')]),
    ('08_watch_your_streak', 'progress', 'Watch your<br><b>streak</b> grow',
     'Streaks, stats and badges for every clean sink.',
     [('chip', 'right', 742, '🏆', 'Badges to unlock')]),
]

# Soft per-slide washes, all from the app's mesh palette.
WASHES = [
    ('#E3F3FD', '#BFE3F8', '#E9E7FF', '#DFF6EE'),
    ('#FFF1E8', '#CDE9FA', '#FFEEE3', '#E9E7FF'),
    ('#E9E7FF', '#C9E6F9', '#D6EFFC', '#FFEEE3'),
    ('#DFF6EE', '#C3E5F8', '#E9E7FF', '#D6EFFC'),
    ('#E3F3FD', '#B9E0F7', '#DFF6EE', '#E9E7FF'),
    ('#EEF4FB', '#C8E4F7', '#E9E7FF', '#DFF6EE'),
    ('#E2F7EE', '#BFE3F8', '#FFF4E0', '#E9E7FF'),
    ('#FFF4E8', '#C6E5F8', '#FFEEE3', '#E9E7FF'),
]

STAR = ('<svg viewBox="0 0 100 100"><path d="M50 0 C55 38 62 45 100 50 C62 55 55 62 50 100 '
        'C45 62 38 55 0 50 C38 45 45 38 50 0Z" fill="currentColor"/></svg>')

BASE_CSS = f"""
@font-face {{ font-family: Jakarta; font-weight: 500; src: url('{FONTS}/PlusJakartaSans-Medium.ttf'); }}
@font-face {{ font-family: Jakarta; font-weight: 600; src: url('{FONTS}/PlusJakartaSans-SemiBold.ttf'); }}
@font-face {{ font-family: Jakarta; font-weight: 700; src: url('{FONTS}/PlusJakartaSans-Bold.ttf'); }}
@font-face {{ font-family: Jakarta; font-weight: 800; src: url('{FONTS}/PlusJakartaSans-ExtraBold.ttf'); }}
:root {{ --ink: #0F1B2D; --ink-soft: #4E6078; --sky-ink: #2B8BC6; --sky: #89CFF0; --sky-deep: #5DB4E6; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html, body {{ width: var(--w); height: var(--h); overflow: hidden; }}
body {{ font-family: Jakarta, 'Segoe UI Emoji', sans-serif; color: var(--ink); position: relative; background: #EAF6FD; }}
.blob {{ position: absolute; border-radius: 50%; filter: blur(80px); }}
.star {{ position: absolute; color: #fff; filter: drop-shadow(0 4px 14px rgba(43,139,198,.35)); }}
.star svg {{ width: 100%; height: 100%; display: block; }}
.phone {{ position: absolute; border-radius: 96px; background: #0E141C; padding: 11px;
  box-shadow: 0 0 0 2px #2C3440 inset, 0 70px 120px -30px rgba(22,72,120,.45), 0 30px 60px -20px rgba(22,72,120,.30); }}
.phone::before, .phone::after {{ content: ''; position: absolute; right: -6px; width: 6px; border-radius: 0 4px 4px 0; background: #1B222C; }}
.phone::before {{ top: 260px; height: 120px; }}
.phone::after {{ top: 420px; height: 70px; }}
.screen {{ position: relative; width: 100%; height: 100%; border-radius: 86px; overflow: hidden; background: #fff; }}
.screen img.ui {{ width: 100%; height: 100%; display: block; }}
.status {{ position: absolute; left: 0; right: 0; top: 0; height: 64px; display: flex; align-items: center;
  justify-content: space-between; padding: 6px 48px 0 56px; font-weight: 700; font-size: 25px; color: #0F1B2D; }}
.status .icons {{ display: flex; gap: 10px; align-items: center; }}
.status svg {{ height: 22px; }}
.camera {{ position: absolute; top: 20px; left: 50%; width: 26px; height: 26px; margin-left: -13px; border-radius: 50%;
  background: radial-gradient(circle at 40% 40%, #2E3A4C 0 25%, #070A0F 60%); }}
.gesture {{ position: absolute; bottom: 12px; left: 50%; width: 220px; height: 8px; margin-left: -110px; border-radius: 8px; background: rgba(15,27,45,.55); }}
.chip {{ position: absolute; display: flex; align-items: center; gap: 18px; padding: 22px 34px 22px 22px;
  border-radius: 999px; background: rgba(255,255,255,.88); backdrop-filter: blur(20px);
  box-shadow: 0 0 0 2px rgba(255,255,255,.9) inset, 0 24px 60px -12px rgba(22,72,120,.35);
  font-weight: 700; font-size: 34px; letter-spacing: -.3px; white-space: nowrap; }}
.chip .orb {{ width: 66px; height: 66px; border-radius: 50%; display: grid; place-items: center; font-size: 34px;
  background: linear-gradient(160deg, #E8F6FD, #BFE4F8); box-shadow: 0 0 0 2px #fff inset; }}
"""

STATUS_ICONS = """
<svg viewBox="0 0 24 24"><path d="M2 20h3v-4H2zm5 0h3v-8H7zm5 0h3V8h-3zm5 0h3V4h-3z" fill="#0F1B2D"/></svg>
<svg viewBox="0 0 24 18"><path d="M12 17.5l3.6-4.4a5.8 5.8 0 0 0-7.2 0zM12 1C7.4 1 3.3 2.7.2 5.5l2.4 3A12 12 0 0 1 12 5a12 12 0 0 1 9.4 3.5l2.4-3C20.7 2.7 16.6 1 12 1zm0 6.5a9 9 0 0 0-6.2 2.6l2.3 2.8A5.7 5.7 0 0 1 12 11.3a5.7 5.7 0 0 1 3.9 1.6l2.3-2.8A9 9 0 0 0 12 7.5z" fill="#0F1B2D"/></svg>
<svg viewBox="0 0 30 16"><rect x="1" y="1" width="25" height="14" rx="4" fill="none" stroke="#0F1B2D" stroke-width="2"/><rect x="4" y="4" width="16" height="8" rx="2" fill="#0F1B2D"/><rect x="27.5" y="5" width="2.5" height="6" rx="1" fill="#0F1B2D"/></svg>
"""


def phone(screen, left, top, width, extra_style=''):
    height = round(width * 892 / 412) + 22
    return f"""
<div class="phone" style="left:{left}px; top:{top}px; width:{width + 22}px; height:{height}px; {extra_style}">
  <div class="screen">
    <img class="ui" src="{(SHOTS / (screen + '.png')).as_uri()}">
    <div class="status"><span>9:41</span><span class="icons">{STATUS_ICONS}</span></div>
    <div class="camera"></div>
    <div class="gesture"></div>
  </div>
</div>"""


def stars(spec):
    return ''.join(
        f'<div class="star" style="left:{x}px; top:{y}px; width:{s}px; height:{s}px; opacity:{o}">{STAR}</div>'
        for x, y, s, o in spec
    )


def heroine_asset(name):
    """Heroine PNG cropped to her bounding box."""
    WORK.mkdir(parents=True, exist_ok=True)
    out = WORK / f'{name}_crop.png'
    im = Image.open(SHOTS / f'{name}.png')
    im.crop(im.getbbox()).save(out)
    return out.as_uri()


def tight(text):
    """Plus Jakarta Sans leaves a wide gap before '.' at display sizes."""
    return text.replace('.', '<span class="dot">.</span>').replace('’', '<span class="apo">’</span>')


def slide_html(index, screen, headline, sub, extras):
    a, b, c, d = WASHES[index]
    headline = tight(headline)
    phone_w, phone_left, phone_top = 660, (1080 - 682) // 2, 452
    parts = []
    for extra in extras:
        if extra[0] == 'heroine':
            parts.append(f'<img src="{heroine_asset(extra[1])}" style="position:absolute; left:6px; top:1440px; '
                         f'height:440px; filter: drop-shadow(0 30px 40px rgba(22,72,120,.30));">')
        else:
            _, side, top, icon, text = extra
            pos = 'left:34px' if side == 'left' else 'right:34px'
            parts.append(f'<div class="chip" style="{pos}; top:{top}px"><span class="orb">{icon}</span>{text}</div>')
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{BASE_CSS}
:root {{ --w: 1080px; --h: 1920px; }}
body {{ background: linear-gradient(180deg, {a} 0%, #F4FAFE 34%, {b} 100%); }}
h1 {{ position: absolute; left: 70px; right: 70px; top: 112px; text-align: center; font-weight: 800;
  font-size: 84px; line-height: 1.06; letter-spacing: -1.8px; }}
h1 .dot, .dot {{ margin-left: -.09em; }}
h1 .apo {{ margin: 0 -.07em; }}
h1 b {{ font-weight: 800; background: linear-gradient(100deg, #2B8BC6, #4FB0E8); -webkit-background-clip: text; color: transparent; }}
p.sub {{ position: absolute; left: 110px; right: 110px; top: 322px; text-align: center; font-weight: 500;
  font-size: 33px; line-height: 1.35; color: var(--ink-soft); letter-spacing: -.2px; }}
</style></head><body>
<div class="blob" style="left:-220px; top:520px; width:640px; height:640px; background:{c}; opacity:.9"></div>
<div class="blob" style="right:-240px; top:980px; width:700px; height:700px; background:{d}; opacity:.9"></div>
<div class="blob" style="left:240px; top:1500px; width:700px; height:500px; background:#9ED6F3; opacity:.55"></div>
{stars([(86, 470, 44, .95), (948, 430, 60, 1), (980, 1560, 34, .9), (60, 1160, 28, .8)])}
<h1>{headline}</h1>
<p class="sub">{sub}</p>
{phone(screen, phone_left, phone_top, phone_w)}
{''.join(parts)}
</body></html>"""


def feature_html():
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{BASE_CSS}
:root {{ --w: 1024px; --h: 500px; }}
body {{ background: linear-gradient(120deg, #EAF7FE 0%, #CBEAFB 45%, #8FD0F2 100%); }}
.brand {{ position: absolute; left: 70px; top: 70px; display: flex; align-items: center; gap: 18px; }}
.brand img {{ width: 72px; height: 72px; border-radius: 18px; box-shadow: 0 14px 30px -8px rgba(22,72,120,.45); }}
.brand span {{ font-weight: 800; font-size: 40px; letter-spacing: -1px; }}
h1 {{ position: absolute; left: 70px; top: 176px; font-weight: 800; font-size: 74px; line-height: 1.0; letter-spacing: -2px; }}
h1 .dot {{ margin-left: -.09em; }}
h1 b {{ background: linear-gradient(100deg, #2B8BC6, #4FB0E8); -webkit-background-clip: text; color: transparent; }}
p.sub {{ position: absolute; left: 72px; top: 345px; width: 420px; font-weight: 500; font-size: 23px; line-height: 1.4; color: #3F5672; }}
.phone {{ border-radius: 46px; padding: 6px; }}
.screen {{ border-radius: 40px; }}
.status {{ height: 30px; font-size: 12px; padding: 3px 22px 0 26px; }}
.status svg {{ height: 10px; }}
.status .icons {{ gap: 5px; }}
.camera {{ top: 9px; width: 12px; height: 12px; margin-left: -6px; }}
.gesture {{ bottom: 6px; width: 100px; height: 4px; margin-left: -50px; }}
.phone::before, .phone::after {{ display: none; }}
</style></head><body>
<div class="blob" style="left:520px; top:-160px; width:520px; height:420px; background:#ffffff; opacity:.75"></div>
<div class="blob" style="left:-120px; top:300px; width:420px; height:320px; background:#E9E7FF; opacity:.9"></div>
{stars([(560, 70, 30, 1), (955, 64, 40, 1), (612, 400, 20, .9), (520, 250, 16, .9)])}
<div class="brand"><img src="{(OUT / 'app_icon_512.png').as_uri()}"><span>Sinkly</span></div>
<h1>{tight('Clean sink.<br><b>Clear mind.</b>')}</h1>
<p class="sub">Your apps pause after meals. A photo of your clean sink unlocks them.</p>
{phone('celebrating', 742, 52, 236, 'transform: rotate(7deg); box-shadow: 0 0 0 1px #2C3440 inset, 0 40px 60px -20px rgba(22,72,120,.5);')}
<img src="{heroine_asset('heroine_cheer')}" style="position:absolute; left:592px; top:150px; height:330px;
  filter: drop-shadow(0 20px 26px rgba(22,72,120,.30));">
</body></html>"""


def _is_complete(path):
    try:
        Image.open(path).load()
        return True
    except Exception:
        return False


def render(html, out_path, width, height):
    WORK.mkdir(parents=True, exist_ok=True)
    page = WORK / (out_path.stem + '.html')
    page.write_text(html, encoding='utf8')
    raw = WORK / (out_path.stem + '_raw.png')
    raw.unlink(missing_ok=True)
    subprocess.run([EDGE, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    f'--user-data-dir={WORK / "edge_profiles" / out_path.stem}', '--force-device-scale-factor=1',
                    f'--window-size={width},{height}', '--virtual-time-budget=3000', f'--screenshot={raw}',
                    page.as_uri()], check=True, capture_output=True)
    # msedge.exe may hand the job to a child process and return before the file is written.
    for _ in range(120):
        if raw.exists() and raw.stat().st_size and _is_complete(raw):
            break
        time.sleep(0.5)
    im = Image.open(raw).convert('RGB')
    assert im.size == (width, height), im.size
    out_path.parent.mkdir(parents=True, exist_ok=True)
    im.save(out_path, optimize=True)
    print(out_path.relative_to(ROOT), im.size, f'{os.path.getsize(out_path) / 1e6:.2f} MB')


def main():
    render(feature_html(), OUT / 'feature_graphic_1024x500.png', 1024, 500)
    for index, (name, screen, headline, sub, extras) in enumerate(SLIDES):
        render(slide_html(index, screen, headline, sub, extras), OUT / 'screenshots' / f'{name}.png', 1080, 1920)


if __name__ == '__main__':
    main()
