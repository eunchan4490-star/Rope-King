#!/usr/bin/env python3
"""Turn a 3-pose (idle/air/mid) transparent PNG sheet into a Rope King character folder.

Usage:
    python build_character.py <source.png> <character_id> "<display name>" <order> [--force]

Produces assets/characters/<character_id>/{idle.png, jump_sheet.png, character.json, _source/original.png}
relative to the project root (two levels up from this script).
"""
import argparse
import io
import json
import sys
from pathlib import Path

# Windows consoles can default to a legacy codepage (cp949/cp1252) that can't
# encode the em-dashes and arrows used in this script's messages.
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

import numpy as np
from PIL import Image
from scipy import ndimage

CROP_PADDING = 3


def project_root() -> Path:
    return Path(__file__).resolve().parents[4]


def check_alpha(img: Image.Image) -> None:
    """Refuse to proceed on an image with no real transparency.

    Background-removal tools (remove.bg and similar) occasionally export with
    a solid color background baked in instead of an alpha channel — the file
    looks fine in a quick glance but alpha is uniformly 255. Catch that early
    instead of silently treating the whole canvas as one giant "character".
    """
    arr = np.array(img.convert("RGBA"))
    alpha = arr[:, :, 3]
    if alpha.min() == 255:
        raise SystemExit(
            "This PNG has no transparency (alpha is uniformly 255) — it looks like "
            "a solid background got baked in instead of transparency. Re-export with "
            "a transparent/no background selected, not a solid color, and try again."
        )
    transparent_fraction = (alpha == 0).mean()
    if transparent_fraction < 0.05:
        print(
            f"Warning: only {transparent_fraction:.0%} of the image is fully "
            "transparent — double check the background was actually removed.",
            file=sys.stderr,
        )


def find_pose_boxes(alpha: np.ndarray) -> tuple[list[tuple[int, int, int, int, int]], np.ndarray]:
    """Return the 3 largest opaque blobs' (bbox + label id), left to right,
    plus the full label map so crop_pose can mask out other poses' pixels
    that happen to fall inside this pose's bounding rectangle.
    """
    mask = alpha > 0
    labeled, n = ndimage.label(mask, structure=np.ones((3, 3)))
    if n < 3:
        raise SystemExit(
            f"Only found {n} separate opaque region(s) — "
            "expected 3 poses (idle, air, mid). Check the source has 3 clearly separated "
            "characters with a real gap of transparent pixels between them."
        )
    sizes = ndimage.sum(mask, labeled, range(1, n + 1))
    order = np.argsort(sizes)[::-1][:3]
    boxes = []
    for idx in order:
        lid = idx + 1
        ys, xs = np.where(labeled == lid)
        boxes.append((int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max()), lid))
    boxes.sort(key=lambda b: b[0])
    return boxes, labeled


def crop_pose(img: Image.Image, box: tuple[int, int, int, int, int], labeled: np.ndarray) -> Image.Image:
    """Crop the pose's bounding rectangle, masking out any pixels that
    belong to a *different* blob (another pose's arm/leg swinging into the
    same rectangle) so they don't bleed into this pose's sprite as a stray
    fragment — e.g. a sliver of the neighboring pose's foot showing up at
    the edge of the mid pose.
    """
    x0, x1, y0, y1, lid = box
    w, h = img.size
    left = max(x0 - CROP_PADDING, 0)
    top = max(y0 - CROP_PADDING, 0)
    right = min(x1 + CROP_PADDING + 1, w)
    bottom = min(y1 + CROP_PADDING + 1, h)
    cropped = img.crop((left, top, right, bottom))
    label_crop = labeled[top:bottom, left:right]
    arr = np.array(cropped.convert("RGBA"))
    foreign = (label_crop != 0) & (label_crop != lid)
    arr[foreign, 3] = 0
    return Image.fromarray(arr, "RGBA")


def assemble_jump_sheet(air: Image.Image, mid: Image.Image) -> Image.Image:
    """Bottom-align and center both poses on a shared cell size, then concat.

    Order matters: air (index 0) then mid (index 1), matching
    JUMP_FRAME_AIR / JUMP_FRAME_MID in scripts/main.gd.
    """
    cell_w = max(air.width, mid.width)
    cell_h = max(air.height, mid.height)

    def place(img: Image.Image) -> Image.Image:
        canvas = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        x = (cell_w - img.width) // 2
        y = cell_h - img.height
        canvas.paste(img, (x, y), img)
        return canvas

    sheet = Image.new("RGBA", (cell_w * 2, cell_h), (0, 0, 0, 0))
    sheet.paste(place(air), (0, 0))
    sheet.paste(place(mid), (cell_w, 0))
    return sheet


def dark_background_preview(idle: Image.Image, air: Image.Image, mid: Image.Image, out_path: Path) -> None:
    """Composite all 3 poses over a dark background for a quick hole-check preview.

    White fabric and a transparent hole both render as white on white — this
    catches the difference immediately.
    """
    scale = 2
    imgs = [im.resize((im.width * scale, im.height * scale), Image.NEAREST) for im in (idle, air, mid)]
    total_w = sum(im.width for im in imgs) + 10 * (len(imgs) + 1)
    max_h = max(im.height for im in imgs) + 20
    bg = Image.new("RGBA", (total_w, max_h), (20, 35, 60, 255))
    x = 10
    for im in imgs:
        bg.paste(im, (x, bg.height - im.height - 10), im)
        x += im.width + 10
    bg.save(out_path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Path to the 3-pose transparent PNG source sheet")
    parser.add_argument("character_id", help="Folder-safe id, e.g. uniform_girl")
    parser.add_argument("display_name", help="Display name shown in the character picker")
    parser.add_argument("order", type=int, help="Sort order in the character picker")
    parser.add_argument("--unlocked", type=lambda s: s.lower() != "false", default=True)
    parser.add_argument("--force", action="store_true", help="Overwrite an existing character folder")
    parser.add_argument(
        "--body-top-fraction",
        type=float,
        default=0.0,
        help=(
            "Fraction (0.0-0.45) of the idle pose's height that is a tall "
            "accessory (ears, a hat, antennae) to exclude from size scaling. "
            "Leave at 0 on the first build; only set this after comparing the "
            "built character against an existing one in-game and seeing it "
            "render smaller — see SKILL.md for why and how to estimate it."
        ),
    )
    parser.add_argument(
        "--scale-multiplier",
        type=float,
        default=1.0,
        help=(
            "Extra overall size multiplier (0.5-2.0) applied on top of the "
            "usual auto-fit scale, e.g. 1.5 to make a character 50%% bigger "
            "in-game than the rest of the roster. A deliberate style choice, "
            "unrelated to body_top_fraction (which corrects for tall "
            "accessories, not a size difference the user actually wants)."
        ),
    )
    parser.add_argument(
        "--enable-jump-rescale",
        action="store_true",
        help=(
            "Opt back into rescaling jump poses by their own bounding-box "
            "height relative to idle (the old default). Pipeline-built "
            "characters come from one source image at one consistent scale, "
            "so this rescale is off by default — turning it on reintroduces "
            "the 'grows/shrinks mid-jump' bug for crouched poses that are "
            "genuinely shorter than standing, not mis-scaled. Only needed if "
            "idle.png and jump_sheet.png truly come from different-resolution "
            "sources (like the original default/pirate_girl assets)."
        ),
    )
    args = parser.parse_args()

    if not args.source.exists():
        raise SystemExit(f"Source file not found: {args.source}")

    img = Image.open(args.source).convert("RGBA")
    check_alpha(img)

    dest = project_root() / "assets" / "characters" / args.character_id
    if dest.exists() and not args.force:
        raise SystemExit(f"{dest} already exists. Pass --force to overwrite.")
    (dest / "_source").mkdir(parents=True, exist_ok=True)

    arr = np.array(img)
    boxes, labeled = find_pose_boxes(arr[:, :, 3])
    cleaned = Image.fromarray(arr.astype(np.uint8), "RGBA")

    poses = [crop_pose(cleaned, box, labeled) for box in boxes]
    idle, air, mid = poses

    idle.save(dest / "idle.png")
    assemble_jump_sheet(air, mid).save(dest / "jump_sheet.png")

    metadata = {
        "display_name": args.display_name,
        "order": args.order,
        "unlocked_by_default": args.unlocked,
    }
    if args.body_top_fraction > 0.0:
        metadata["body_top_fraction"] = args.body_top_fraction
    if args.scale_multiplier != 1.0:
        metadata["scale_multiplier"] = args.scale_multiplier
    if not args.enable_jump_rescale:
        metadata["disable_jump_rescale"] = True
    (dest / "character.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    import shutil

    shutil.copy(args.source, dest / "_source" / "original.png")

    preview_path = dest / "_source" / "dark_background_preview.png"
    dark_background_preview(idle, air, mid, preview_path)

    print(f"Character '{args.character_id}' built at {dest}")
    print(f"  idle.png: {idle.size}")
    print(f"  jump_sheet.png: {(air.width + mid.width, max(air.height, mid.height))}")
    print(f"  Preview over dark background: {preview_path}")
    print("  Check the preview for holes before reporting done — white shirt should stay white,")
    print("  gaps between legs/under arms should be visibly transparent (checkerboard), not solid.")
    if args.body_top_fraction > 0.0:
        print(f"  body_top_fraction: {args.body_top_fraction}")
    print("  If this character has tall ears/a hat/antennae, compare its in-game size against an")
    print("  existing character next to it — if it renders smaller, see SKILL.md for how to set")
    print("  body_top_fraction in character.json (no need to rerun this script, just re-export).")


if __name__ == "__main__":
    main()
