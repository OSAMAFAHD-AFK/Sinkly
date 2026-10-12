"""App Store rejects app icons with an alpha channel: flatten the iOS icons to RGB.

Run from the project root after generate_brand_assets_test.dart:
    python tool/brand_assets/flatten_ios_icons.py
"""
import glob

from PIL import Image

for path in glob.glob('ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png'):
    image = Image.open(path).convert('RGBA')
    background = Image.new('RGB', image.size, (90, 175, 230))
    background.paste(image, mask=image.split()[3])
    background.save(path)
    print('flattened', path)
