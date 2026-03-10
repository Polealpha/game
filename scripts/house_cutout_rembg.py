from __future__ import annotations

import json
from pathlib import Path

from PIL import Image
from rembg import new_session, remove


ROOT = Path(r"E:\Desktop\gamexu")
SOURCE = ROOT / "ditu_8k_realesrgan.png"
GENERATED = ROOT / "assets" / "generated"


STAGE1_ITEMS = [
    {"name": "hilltop_temple_block", "rect": [420, 220, 2250, 1880]},
    {"name": "hill_stair_shop", "rect": [820, 1180, 1860, 2500]},
    {"name": "closed_market_block", "rect": [560, 1960, 1980, 3640]},
    {"name": "general_store_block", "rect": [900, 2960, 2280, 4360]},
    {"name": "fish_market_block", "rect": [0, 3440, 1460, 5040]},
    {"name": "subway_station", "rect": [120, 4540, 2700, 5463]},
    {"name": "exchange_row_left", "rect": [3100, 120, 4560, 1020]},
    {"name": "exchange_row_mid", "rect": [4460, 100, 5660, 1040]},
    {"name": "stock_exchange", "rect": [5360, 80, 7820, 1200]},
    {"name": "clocktower_building", "rect": [7440, 20, 8192, 1040]},
    {"name": "exchange_row_right", "rect": [6940, 300, 8192, 1240]},
    {"name": "bank_hall", "rect": [2900, 1080, 4880, 2260]},
    {"name": "bank_side_shop", "rect": [4580, 1140, 5520, 2260]},
    {"name": "lower_exchange_stalls", "rect": [3120, 2000, 5060, 3040]},
    {"name": "memorial_row", "rect": [6600, 760, 8192, 1700]},
    {"name": "fountain_right_row", "rect": [6420, 1320, 8192, 2300]},
    {"name": "warehouse_small", "rect": [5080, 2720, 6240, 3980]},
    {"name": "iron_claw_factory", "rect": [5640, 2460, 7880, 3880]},
    {"name": "factory_right_row", "rect": [7320, 2100, 8192, 3820]},
    {"name": "seal_flour", "rect": [4940, 3760, 6480, 4860]},
    {"name": "warehouse_24", "rect": [6340, 4140, 8192, 5120]},
    {"name": "harbor_office", "rect": [7240, 4480, 8192, 5360]},
    {"name": "lighthouse", "rect": [5840, 4340, 7080, 5463]},
    {"name": "container_yard", "rect": [6420, 4680, 8192, 5463]},
]


STAGE2_ITEMS = [
    {"name": "hilltop_temple_block", "rect": [500, 220, 2140, 1020]},
    {"name": "hill_stair_shop", "rect": [860, 1180, 1760, 1960]},
    {"name": "closed_market_block", "rect": [620, 1980, 1920, 2780]},
    {"name": "general_store_block", "rect": [980, 3000, 2220, 3720]},
    {"name": "fish_market_block", "rect": [0, 3460, 1320, 4180]},
    {"name": "subway_station", "rect": [160, 4560, 2520, 5060]},
    {"name": "exchange_row_left", "rect": [3140, 120, 4520, 680]},
    {"name": "exchange_row_mid", "rect": [4440, 100, 5640, 680]},
    {"name": "stock_exchange", "rect": [5380, 80, 7800, 660]},
    {"name": "clocktower_building", "rect": [7440, 20, 8192, 740]},
    {"name": "exchange_row_right", "rect": [6940, 300, 8192, 820]},
    {"name": "bank_hall", "rect": [2940, 1100, 4860, 1520]},
    {"name": "bank_side_shop", "rect": [4600, 1160, 5520, 1720]},
    {"name": "lower_exchange_stalls", "rect": [3160, 2020, 5040, 2260]},
    {"name": "memorial_row", "rect": [6620, 780, 8192, 1260]},
    {"name": "fountain_right_row", "rect": [6440, 1340, 8192, 1760]},
    {"name": "warehouse_small", "rect": [5100, 2760, 6220, 3340]},
    {"name": "iron_claw_factory", "rect": [5660, 2480, 7860, 3080]},
    {"name": "factory_right_row", "rect": [7340, 2120, 8192, 3260]},
    {"name": "seal_flour", "rect": [4960, 3780, 6460, 4300]},
    {"name": "warehouse_24", "rect": [6360, 4160, 8192, 4580]},
    {"name": "harbor_office", "rect": [7240, 4480, 8192, 5040]},
    {"name": "lighthouse", "rect": [5900, 4380, 7000, 5463]},
    {"name": "container_yard", "rect": [6420, 4720, 8192, 5463]},
]


STAGES = {
    "stage1_irregular": {
        "items": STAGE1_ITEMS,
        "folder": GENERATED / "ditu_8k_house_layers_stage1_irregular",
        "preview": ROOT / "tmp_stage1_irregular_preview.png",
        "manifest": GENERATED / "ditu_8k_house_layers_stage1_irregular_manifest.json",
    },
    "stage2_irregular_no_road": {
        "items": STAGE2_ITEMS,
        "folder": GENERATED / "ditu_8k_house_layers_stage2_irregular_no_road",
        "preview": ROOT / "tmp_stage2_irregular_no_road_preview.png",
        "manifest": GENERATED / "ditu_8k_house_layers_stage2_irregular_no_road_manifest.json",
    },
}


def ensure_empty_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    for item in path.iterdir():
        if item.is_file():
            item.unlink()


def process_stage(stage_name: str) -> None:
    config = STAGES[stage_name]
    folder: Path = config["folder"]
    ensure_empty_dir(folder)

    source = Image.open(SOURCE).convert("RGBA")
    preview = Image.new("RGBA", source.size, (0, 0, 0, 0))
    session = new_session("u2net")

    manifest_items = []
    for item in config["items"]:
        left, top, right, bottom = item["rect"]
        crop = source.crop((left, top, right, bottom))
        cutout = remove(crop, session=session)
        out_path = folder / f"{item['name']}.png"
        cutout.save(out_path)
        preview.alpha_composite(cutout, (left, top))
        manifest_items.append(
            {
                "name": item["name"],
                "path": str(out_path),
                "left": left,
                "top": top,
            }
        )

    preview.save(config["preview"])
    config["manifest"].write_text(
        json.dumps({"stage": stage_name, "items": manifest_items}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    process_stage("stage1_irregular")
    process_stage("stage2_irregular_no_road")
