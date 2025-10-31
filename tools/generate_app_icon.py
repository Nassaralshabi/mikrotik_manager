import sys
from pathlib import Path
from PIL import Image, ImageOps

SRC = Path('/project/workspace/Screenshot_٢٠٢٥-٠٩-٢٠-١٣-١٣-٥٢-٢٢٢_com.facebook.lite.jpg')
OUT_ICON = Path('/project/workspace/Nassaralshabi/mikrotik_manager/assets/icon/app_icon.png')

# Mipmap targets
MIPMAP_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}
RES_DIR = Path('/project/workspace/Nassaralshabi/mikrotik_manager/android/app/src/main/res')


def brightness(c):
    r, g, b = c[:3]
    return int(0.299*r + 0.587*g + 0.114*b)


def find_subject_bbox(img, thresh=35, pad_ratio=0.06):
    # Returns bbox around non-dark (bright) pixels
    rgb = img.convert('RGB')
    gray = ImageOps.grayscale(rgb)
    # Create mask: 255 where bright, 0 where near black
    mask = gray.point(lambda v: 255 if v > thresh else 0).convert('L')
    bbox = mask.getbbox()
    if not bbox:
        # Fallback to centered crop (middle square)
        w, h = img.size
        side = min(w, h)
        left = (w - side)//2
        top = (h - side)//2
        return (left, top, left+side, top+side)
    # Add padding
    left, top, right, bottom = bbox
    w, h = img.size
    pad = int(max(w, h) * pad_ratio)
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(w, right + pad)
    bottom = min(h, bottom + pad)
    return (left, top, right, bottom)


def make_rgba_with_transparency(img, dark_thresh=25):
    rgb = img.convert('RGB')
    alpha = ImageOps.grayscale(rgb).point(lambda v: 0 if v <= dark_thresh else 255).convert('L')
    rgba = rgb.convert('RGBA')
    rgba.putalpha(alpha)
    return rgba


def generate_app_icon():
    if not SRC.exists():
        print(f'Source image not found: {SRC}', file=sys.stderr)
        sys.exit(1)

    src = Image.open(SRC)
    bbox = find_subject_bbox(src)
    cropped = src.crop(bbox)

    # Transparent background for foreground graphic
    subject_rgba = make_rgba_with_transparency(cropped)

    # Fit inside 1024x1024 with some safe margin
    canvas_size = 1024
    margin = int(canvas_size * 0.06)
    target_inner = canvas_size - 2*margin

    # Resize while keeping aspect
    w, h = subject_rgba.size
    if w >= h:
        new_w = target_inner
        new_h = max(1, int(h * (target_inner / w)))
    else:
        new_h = target_inner
        new_w = max(1, int(w * (target_inner / h)))
    subject_resized = subject_rgba.resize((new_w, new_h), Image.LANCZOS)

    # Place on transparent canvas; Android adaptive background will be black per config
    canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = ((canvas_size - new_w)//2, (canvas_size - new_h)//2)
    canvas.paste(subject_resized, offset, subject_resized)

    OUT_ICON.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT_ICON)
    print(f'Wrote {OUT_ICON}')

    return canvas


def generate_mipmaps(base_rgba):
    # Composite over black background for legacy icons so they read well at tiny sizes
    for folder, size in MIPMAP_SIZES.items():
        bg = Image.new('RGBA', (size, size), (0, 0, 0, 255))
        # fit subject keeping ratio and small padding
        inner = int(size * 0.86)
        w, h = base_rgba.size
        if w >= h:
            nw = inner
            nh = max(1, int(h * (inner / w)))
        else:
            nh = inner
            nw = max(1, int(w * (inner / h)))
        resized = base_rgba.resize((nw, nh), Image.LANCZOS)
        offset = ((size - nw)//2, (size - nh)//2)
        bg.paste(resized, offset, resized)
        out_dir = RES_DIR / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / 'ic_launcher.png'
        bg.convert('RGBA').save(out_path)
        print(f'Wrote {out_path} ({size}x{size})')


if __name__ == '__main__':
    icon_rgba = generate_app_icon()
    if '--mipmaps' in sys.argv:
        generate_mipmaps(icon_rgba)
