from __future__ import annotations

import argparse
import json
import os
from collections import deque
from pathlib import Path

from PIL import Image


DIRECTIONS = ["front", "left", "right", "back"]
BACKGROUND_TOLERANCE = 24
FOREGROUND_TOLERANCE = 18


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Split 4-view NPC sheets into transparent directional sprites."
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=Path(r"C:\Users\More\Desktop\龟\人物图片"),
        help="Directory that contains the original PNG sheets.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(r"C:\Users\More\Desktop\龟\assets\generated\npc_directions"),
        help="Directory for extracted directional sprites.",
    )
    parser.add_argument(
        "--canvas-size",
        type=int,
        default=256,
        help="Square output size in pixels.",
    )
    parser.add_argument(
        "--max-scale",
        type=float,
        default=0.84,
        help="Maximum portion of the canvas used by the extracted sprite.",
    )
    return parser.parse_args()


def clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(value, maximum))


def color_distance(pixel: tuple[int, int, int], background: tuple[int, int, int]) -> int:
    return max(
        abs(int(pixel[0]) - background[0]),
        abs(int(pixel[1]) - background[1]),
        abs(int(pixel[2]) - background[2]),
    )


def sample_background(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    width, height = rgb.size
    sample_points = [
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
        (width // 2, 0),
        (width // 2, height - 1),
        (0, height // 2),
        (width - 1, height // 2),
    ]
    pixels = rgb.load()
    total_r = 0
    total_g = 0
    total_b = 0
    for x, y in sample_points:
        r, g, b = pixels[x, y]
        total_r += r
        total_g += g
        total_b += b
    count = len(sample_points)
    return (total_r // count, total_g // count, total_b // count)


def find_segments(flags: list[bool]) -> list[tuple[int, int]]:
    segments: list[tuple[int, int]] = []
    start: int | None = None
    for index, flag in enumerate(flags):
        if flag and start is None:
            start = index
        elif not flag and start is not None:
            segments.append((start, index - 1))
            start = None
    if start is not None:
        segments.append((start, len(flags) - 1))
    return segments


def choose_central_segment(
    segments: list[tuple[int, int]], length: int, center_bias: float = 1.7
) -> tuple[int, int]:
    if not segments:
        return (0, length - 1)
    center = length / 2.0
    best_segment = segments[0]
    best_score = float("-inf")
    for start, end in segments:
        width = end - start + 1
        segment_center = (start + end) / 2.0
        distance_penalty = abs(segment_center - center) * center_bias
        score = width - distance_penalty
        if score > best_score:
            best_score = score
            best_segment = (start, end)
    return best_segment


def detect_bbox(slice_image: Image.Image) -> tuple[int, int, int, int]:
    rgb = slice_image.convert("RGB")
    width, height = rgb.size
    detection_bottom = max(1, int(height * 0.78))
    background = sample_background(rgb)
    pixels = rgb.load()

    min_column_pixels = max(3, detection_bottom // 45)
    column_flags: list[bool] = []
    for x in range(width):
        foreground_count = 0
        for y in range(detection_bottom):
            if color_distance(pixels[x, y], background) >= FOREGROUND_TOLERANCE:
                foreground_count += 1
        column_flags.append(foreground_count >= min_column_pixels)

    x_start, x_end = choose_central_segment(find_segments(column_flags), width)
    x_margin = max(6, width // 18)
    x_start = clamp(x_start - x_margin, 0, width - 1)
    x_end = clamp(x_end + x_margin, 0, width - 1)

    min_row_pixels = max(3, (x_end - x_start + 1) // 18)
    row_flags: list[bool] = []
    for y in range(detection_bottom):
        foreground_count = 0
        for x in range(x_start, x_end + 1):
            if color_distance(pixels[x, y], background) >= FOREGROUND_TOLERANCE:
                foreground_count += 1
        row_flags.append(foreground_count >= min_row_pixels)

    y_start, y_end = choose_central_segment(find_segments(row_flags), detection_bottom, 0.35)
    y_margin = max(6, height // 22)
    y_start = clamp(y_start - y_margin, 0, height - 1)
    y_end = clamp(y_end + y_margin, 0, height - 1)
    return (x_start, y_start, x_end + 1, y_end + 1)


def remove_edge_background(
    image: Image.Image, background: tuple[int, int, int]
) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited = [[False for _ in range(width)] for _ in range(height)]
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= width or y < 0 or y >= height:
            continue
        if visited[y][x]:
            continue
        visited[y][x] = True
        r, g, b, a = pixels[x, y]
        if a == 0:
            continue
        if color_distance((r, g, b), background) > BACKGROUND_TOLERANCE:
            continue
        pixels[x, y] = (r, g, b, 0)
        queue.append((x - 1, y))
        queue.append((x + 1, y))
        queue.append((x, y - 1))
        queue.append((x, y + 1))

    return rgba


def keep_largest_component(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited = [[False for _ in range(width)] for _ in range(height)]
    largest_component: list[tuple[int, int]] = []

    for y in range(height):
        for x in range(width):
            if visited[y][x]:
                continue
            if pixels[x, y][3] == 0:
                visited[y][x] = True
                continue

            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[y][x] = True
            component: list[tuple[int, int]] = []
            while queue:
                current_x, current_y = queue.popleft()
                if pixels[current_x, current_y][3] == 0:
                    continue
                component.append((current_x, current_y))
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
                        continue
                    if visited[next_y][next_x]:
                        continue
                    visited[next_y][next_x] = True
                    if pixels[next_x, next_y][3] > 0:
                        queue.append((next_x, next_y))

            if len(component) > len(largest_component):
                largest_component = component

    if not largest_component:
        return rgba

    largest_set = set(largest_component)
    cleaned = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    cleaned_pixels = cleaned.load()
    for x, y in largest_set:
        cleaned_pixels[x, y] = pixels[x, y]
    return cleaned


def trim_transparent(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def fit_to_canvas(image: Image.Image, canvas_size: int, max_scale: float) -> Image.Image:
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    available = max(1, int(canvas_size * max_scale))
    sprite = image.copy()
    sprite.thumbnail((available, available), Image.Resampling.LANCZOS)
    x = (canvas_size - sprite.width) // 2
    y = canvas_size - sprite.height - max(4, canvas_size // 16)
    canvas.alpha_composite(sprite, (x, y))
    return canvas


def extract_sprite(slice_image: Image.Image, canvas_size: int, max_scale: float) -> Image.Image:
    bbox = detect_bbox(slice_image)
    cropped = slice_image.crop(bbox)
    transparent = remove_edge_background(cropped, sample_background(slice_image))
    main_component = keep_largest_component(transparent)
    trimmed = trim_transparent(main_component)
    return fit_to_canvas(trimmed, canvas_size=canvas_size, max_scale=max_scale)


def build_preview(
    preview_rows: list[dict[str, str]], output_path: Path, canvas_size: int
) -> None:
    if not preview_rows:
        return
    columns = len(DIRECTIONS)
    tile = canvas_size
    margin = 18
    label_height = 26
    rows = len(preview_rows)
    sheet = Image.new(
        "RGBA",
        (
            margin + columns * (tile + margin),
            margin + rows * (tile + label_height + margin),
        ),
        (250, 250, 250, 255),
    )
    for row_index, row in enumerate(preview_rows):
        for column_index, direction in enumerate(DIRECTIONS):
            sprite = Image.open(row[direction]).convert("RGBA")
            x = margin + column_index * (tile + margin)
            y = margin + row_index * (tile + label_height + margin)
            sheet.alpha_composite(sprite, (x, y))
    sheet.save(output_path)


def main() -> None:
    args = parse_args()
    input_dir = args.input_dir
    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    source_files = sorted(
        input_dir.glob("*.png"),
        key=lambda path: (os.stat(path).st_mtime, path.name.lower()),
    )
    manifest: list[dict[str, object]] = []
    preview_rows: list[dict[str, str]] = []

    for index, source_path in enumerate(source_files, start=1):
        image = Image.open(source_path).convert("RGBA")
        width, height = image.size
        slice_width = width / 4.0
        entry: dict[str, object] = {
            "seq": index,
            "source": source_path.name,
            "size": [width, height],
            "outputs": {},
        }
        preview_row: dict[str, str] = {}

        for direction_index, direction_name in enumerate(DIRECTIONS):
            left = round(direction_index * slice_width)
            right = round((direction_index + 1) * slice_width)
            slice_image = image.crop((left, 0, right, height))
            sprite = extract_sprite(
                slice_image, canvas_size=args.canvas_size, max_scale=args.max_scale
            )
            output_name = f"npc_{index:02d}_{direction_name}.png"
            output_path = output_dir / output_name
            sprite.save(output_path)
            entry["outputs"][direction_name] = output_name
            preview_row[direction_name] = str(output_path)

        manifest.append(entry)
        preview_rows.append(preview_row)

    manifest_path = output_dir / "manifest.json"
    preview_path = output_dir / "preview.png"
    manifest_path.write_text(
        json.dumps(
            {
                "count": len(manifest),
                "canvas_size": args.canvas_size,
                "directions": DIRECTIONS,
                "items": manifest,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    build_preview(preview_rows, preview_path, args.canvas_size)
    print(f"Processed {len(manifest)} source images into {output_dir}")
    print(f"Manifest: {manifest_path}")
    print(f"Preview:  {preview_path}")


if __name__ == "__main__":
    main()
