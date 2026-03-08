# Third-Party Resources

当前项目接入或缓存了以下第三方仓库与资源。

## tiny-wizard-demo

- Source: https://github.com/quiver-dev/tiny-wizard-demo
- Usage:
  - 顶视角房间地面贴图
  - 箱子、钥匙、铜币、门等 2D 场景道具
  - 当前也用于 `scripts/world/HouseInterior.gd` 的屋内地板覆层、门、箱柜、零钱和细部陈设
- License:
  - 代码见仓库 `LICENSE.txt`
  - 资源见仓库 `LICENSE_ASSETS.txt`
  - 美术、音乐、音效资源为 `CC BY 4.0`

## godot_dialogue_manager

- Source: https://github.com/nathanhoad/godot_dialogue_manager
- Usage:
  - 当前缓存于 `external/`
  - 用于后续替换现有街头气泡与任务对话系统
- License:
  - MIT

## calciumtrice OpenGameArt resources

- Source:
  - https://opengameart.org/content/forest-tileset
  - https://opengameart.org/content/trees
  - https://opengameart.org/content/medieval-tileset
  - https://opengameart.org/content/outdoor-tileset
- Local cache:
  - `assets/vendor/calciumtrice/forest_tileset.png`
  - `assets/vendor/calciumtrice/trees.png`
  - `assets/vendor/calciumtrice/medieval_tileset_exterior.png`
  - `assets/vendor/calciumtrice/medieval_tileset_interior.png`
  - `assets/vendor/calciumtrice/water.png`
- Usage:
  - `scripts/world/WorldBackdrop.gd` uses these textures for additional planar tree lines, farm-edge ground patches, half-timber buildings, and outskirts dressing.
  - `scripts/world/HouseInterior.gd` now also uses the interior tileset for炉台、柜架、桌椅、杂物堆和不同阶层房屋的室内陈设精修。
  - These assets are used for visual presentation only and do not change backend interfaces.
- License:
  - See the relevant OpenGameArt pages for the author-provided license terms.

## Slates tileset

- Source:
  - https://opengameart.org/content/slates-32x32px-orthogonal-tileset
- Local cache:
  - `assets/vendor/ivan_voirol/slates_v2.png`
- Usage:
  - `scripts/world/WorldBackdrop.gd` uses tightly cropped regions from this sheet for additional planar pine clusters, round-canopy trees, and harbor bridge-water detail patches.
- License:
  - See the relevant OpenGameArt page for the author-provided license terms.

## LPC Woodshop

- Source:
  - https://opengameart.org/content/lpc-woodshop
- Local cache:
  - `assets/vendor/lpc_woodshop.zip`
  - `assets/vendor/lpc_woodshop/lpc-woodshop/woodshop.png`
  - `assets/vendor/lpc_woodshop/lpc-woodshop/CREDITS-woodshop.txt`
- Usage:
  - `scripts/world/HouseInterior.gd` uses this atlas for工人宿舍和港口屋内的木工台、锯架、工具墙、木料堆、货箱与修补工作区。
- License:
  - OGA-BY 3.0+ / CC BY 3.0+ / GPL v2.0+ as stated in `CREDITS-woodshop.txt`

## LPC Castle Lights Repack

- Source:
  - https://opengameart.org/content/lpc-castle-lights-repack
- Local cache:
  - `assets/vendor/lpc_castle_lights.png`
- Usage:
  - `scripts/world/HouseInterior.gd` uses this sprite sheet for夜间壁灯、火把和屋内暖光层次。
- License:
  - See the OpenGameArt page for the author-provided license terms.

## example_dialogue_balloons

- Source: https://github.com/nathanhoad/example_dialogue_balloons
- Usage:
  - 当前缓存于 `external/`
  - 用作中世纪风格对话气泡、弹窗层次和过场演出的参考
- License:
  - 以仓库内 LICENSE / README 为准

## better-terrain

- Source: https://github.com/Portponky/better-terrain
- Usage:
  - 当前缓存于 `external/`
  - 用于后续编辑更复杂的 2D 地形与铺装
- License:
  - 以仓库内 LICENSE / README 为准

## superpowers-asset-packs

- Source: https://github.com/sparklinlabs/superpowers-asset-packs
- Usage:
  - 当前缓存于 `external/superpowers-asset-packs`
  - 已复用 `medieval-fantasy` 像素包里的树、房子、木箱、铁炉、地表瓦片和小道具
  - 已整合进 `assets/vendor/superpowers/medieval-fantasy`
  - 当前由 `WorldBackdrop.gd` 直接用于替换部分程序化地图和装饰元素
  - 当前也由 `scripts/world/HouseInterior.gd` 复用桶、板条箱、食物、武器、金杯、宝石等中世纪室内陈设
- License:
  - MIT

## OpenGameArt Turtle Sprite

- Source: https://opengameart.org/content/turtle-sprite
- Usage:
  - Cached at `assets/vendor/opengameart/turtle_sprite_sheet.png`
  - Used by `scripts/world/Player.gd` as animated shell overlay frames for the turtle protagonist
- Author:
  - Master484 / OpenGameArt submission page attribution
- License:
  - CC0

## OpenGameArt Stendhal Animals

- Source: https://opengameart.org/content/stendhal-animals
- Usage:
  - Cached at `assets/vendor/opengameart/stendhal_animals/`
  - Used by `scripts/world/NPCView.gd` as base creature sprite sheets for NPC body animation
- Author:
  - Kimmo Rundelin (kiheru)
- License:
  - CC BY-SA 3.0 or later

## OpenGameArt Pixel Speech Bubbles V2

- Source: https://opengameart.org/content/pixel-speech-bubbles
- Usage:
  - Cached at `assets/vendor/opengameart/pixel_speech_bubbles/`
  - Used by `scripts/world/NPCView.gd` as pixel dialogue balloon backplates for NPC speech bubbles
- Author:
  - Tallbeard Studio / OpenGameArt submission page attribution
- License:
  - CC0

## Kenney Emotes Pack

- Source: https://kenney.nl/assets/emotes-pack
- Usage:
  - Cached at `assets/vendor/kenney_emotes_pack/`
  - Used by `scripts/world/Player.gd` and `scripts/world/NPCView.gd` for pixel emote icons during talk, rest, alerts, and social reactions
- Author:
  - Kenney
- License:
  - CC0

## OpenGameArt 496 Medieval/Fantasy RPG Icons

- Source: https://opengameart.org/content/496-pixel-art-icons-for-medievalfantasy-rpg
- Usage:
  - Cached at `assets/vendor/opengameart/496_RPG_icons/`
  - Used by `scripts/world/Player.gd` and `scripts/world/NPCView.gd` for carry, ledger, coin, scroll, bread, and tool interaction props
- Author:
  - 7Soul1 / OpenGameArt submission page attribution
- License:
  - CC0

## OpenGameArt Simple Animated Character

- Source: https://opengameart.org/content/simple-animated-character
- Usage:
  - Cached at `assets/vendor/downloads/sora.zip`
  - Extracted to `assets/vendor/sora_character/`
  - Used by `scripts/world/Player.gd` for the rebuilt four-direction player sprite animation set
- Author:
  - Sora / OpenGameArt submission page attribution
- License:
  - CC0

## Square Characters Animated 8 Directions Top Down Free

- Source:
  - Original pack metadata cached in `assets/vendor/downloads/square_characters_animated_8_directions_top_down_free_cc0.zip`
  - Extracted to `assets/vendor/square_characters/`
- Usage:
  - Generated sheets cached in `assets/generated/character_sheets/`
  - Used by `scripts/world/Player.gd` and `scripts/world/NPCView.gd` for the rebuilt cartoon player and NPC idle/move animation sets
- License:
  - CC0 as stated in `assets/vendor/square_characters/Square characters animated 8 directions top down free cc0/License.txt`

## LPC 2D RPG Town Tileset

- Source: https://lpc.opengameart.org/content/2d-rpg-town-tileset
- Usage:
  - Cached at `assets/vendor/downloads/2DRP_CCArt_RPGTown.tar.gz`
  - Primary atlas cached at `assets/vendor/downloads/2DRP CCArt RPG Town (32x32).png`
  - Used by `scripts/world/WorldBackdrop.gd` for the new forest farm and harbor-side subregion dressing
- License:
  - CC-BY-SA 3.0 as stated on the LPC / OpenGameArt page
