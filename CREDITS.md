# Credits and licenses

Every file that ships inside the game, and every tool used to build it, is listed here with its license.
Nothing in the game was downloaded from asset stores or sound libraries.

## Shipped with the game
| Component | Author | License | Notes |
|---|---|---|---|
| Godot Engine 4.7.2 | Godot Engine contributors | MIT | Engine and third-party notices are shown in the in-game Licenses screen via `Engine.get_license_text()` and `Engine.get_copyright_info()` |
| Open Sans (default UI font) | The Open Sans Project Authors | OFL-1.1 | Built into Godot; listed in the Licenses screen with the engine's other components |
| Game art: tiles, obstacles, cats, boosters, stars, icon | Pati Yuvası project | Original work | Drawn as SVG code in `tools/art/*.mjs` and rasterized by `tools/art/build.mjs`; no external images |
| Sound effects | Pati Yuvası project | Original work | Synthesized from code by `tools/audio/make_sfx.gd`; no recordings or sample packs |
| Levels, cat names, texts | Pati Yuvası project | Original work | `tools/levels/level_table.gd`, `game/meta/meta_rules.gd` |

## Development tools (not shipped)
| Tool | License | Use |
|---|---|---|
| gdUnit4 6.2.1 | MIT | Unit tests; excluded from exports (`LICENSES/gdUnit4-MIT.txt`) |
| @resvg/resvg-js 2.6.2 | MPL-2.0 | Rasterizes the SVG art to PNG; system fonts are not loaded |
| Node.js | MIT | Runs the art build script |
| OpenJDK 17, Android SDK command-line tools | GPL-2.0 with Classpath Exception; Android SDK License | Builds and signs the Android package |
