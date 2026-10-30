"""Generate Singgah launcher and web icons from the in-app pin + check mark."""

from pathlib import Path

from PIL import Image, ImageDraw

NAVY = (13, 42, 71, 255)
ORANGE = (201, 79, 14, 255)
LIGHT = (242, 245, 249, 255)
SCALE = 4

ROOT = Path(__file__).resolve().parents[1]


def icon(size: int, safe: float = 1.0) -> Image.Image:
    side = size * SCALE
    image = Image.new("RGBA", (side, side), NAVY)
    draw = ImageDraw.Draw(image)

    def x(value: float) -> float:
        return side * (0.5 + (value - 0.5) * safe)

    def y(value: float) -> float:
        return side * (0.5 + (value - 0.5) * safe)

    radius = side * 0.22 * safe
    center = (x(0.5), y(0.4))
    draw.ellipse(
        [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius],
        fill=ORANGE,
    )
    draw.polygon(
        [(x(0.34), y(0.56)), (x(0.5), y(0.82)), (x(0.66), y(0.56))],
        fill=ORANGE,
    )

    width = max(1, int(side * 0.07 * safe))
    draw.line(
        [(x(0.41), y(0.40)), (x(0.48), y(0.47)), (x(0.60), y(0.33))],
        fill=LIGHT,
        width=width,
        joint="curve",
    )
    for point in [(x(0.41), y(0.40)), (x(0.48), y(0.47)), (x(0.60), y(0.33))]:
        draw.ellipse(
            [point[0] - width / 2, point[1] - width / 2, point[0] + width / 2, point[1] + width / 2],
            fill=LIGHT,
        )

    return image.resize((size, size), Image.Resampling.LANCZOS)


def save(path: Path, size: int, safe: float = 1.0) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    icon(size, safe).save(path, "PNG")
    print(f"wrote {path.relative_to(ROOT)} ({size}px)")


def main() -> None:
    for folder, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        save(ROOT / f"android/app/src/main/res/mipmap-{folder}/ic_launcher.png", size)

    save(ROOT / "web/favicon.png", 48)
    save(ROOT / "web/icons/Icon-192.png", 192)
    save(ROOT / "web/icons/Icon-512.png", 512)
    save(ROOT / "web/icons/Icon-maskable-192.png", 192, safe=0.78)
    save(ROOT / "web/icons/Icon-maskable-512.png", 512, safe=0.78)


if __name__ == "__main__":
    main()
