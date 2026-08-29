---
name: rope-king-character-import
description: Turn a 3-pose transparent PNG character sheet (idle/air/mid) into a playable 줄넘킹(Rope King) character — background/shadow cleanup, pose splitting, idle.png + jump_sheet.png + character.json, and a rebuild+test pass. Use this whenever the user drops a new character image into the "julnumking asset" folder (or anywhere else) and wants it added, replaced, or fixed in this project — including requests like "이 캐릭터 추가해줘", "새 캐릭터 넣어줘", or "에셋 다시 넣어줘" after re-exporting a PNG.
---

# Rope King character import

This packages the workflow we iterated on manually: taking a hand-made or
AI-generated character sheet and turning it into the two files the game
actually loads (`idle.png`, `jump_sheet.png`) plus its `character.json`,
without reintroducing the mistakes that caused real regressions along the
way — an invisible hole punched through the shirt, a growing-on-jump bug,
and images that looked transparent but weren't.

## Input contract

The source PNG must have **3 poses side by side**, left to right:
1. idle — standing still
2. air — full-extension apex pose
3. mid — transition pose between idle and air

This matches the game's animation convention: playback order is
`idle → mid → air → mid → idle` (1-3-2-3-1), and `scripts/main.gd` expects
`jump_sheet.png` to contain exactly the air and mid poses in that order
(`JUMP_FRAME_AIR = 0`, `JUMP_FRAME_MID = 1`).

If the user gives you an image pasted directly into chat, it has no
filesystem path you can read — ask them to save it into
`Desktop\julnumking asset\` (or tell you wherever they put it) and give you
the filename, the same way the working pattern developed over this project.

## Run the pipeline

Use the bundled script — it encodes several fixes that are easy to
reintroduce if you redo this by hand:

```bash
python "scripts/build_character.py" "<source.png>" <character_id> "<display name>" <order>
```

Example:
```bash
python ".claude/skills/rope-king-character-import/scripts/build_character.py" \
  "D:\사용자 폴더\UserK\Desktop\julnumking asset\girl.png" \
  uniform_girl "교복소녀" 20
```

Run it with the project root as the working directory (it resolves
`assets/characters/<id>/` relative to itself). Pass `--force` to overwrite an
existing character folder, and `--unlocked False` if it shouldn't be
available from the start.

The script will hard-stop with a clear message if the source has no real
alpha channel (uniformly opaque) — that means whatever tool made the "PNG"
baked in a solid background instead of transparency (remove.bg does this
if a color swatch gets picked instead of the transparent/checkerboard
option). Relay that message to the user and ask them to re-export rather
than trying to work around it — there's no background to remove from a
flat image, guessing would just fabricate a cutout.

## Why the pipeline works this way (read before changing it)

Every step here exists because a simpler version of it broke something:

- **Shadow removal by color, not by position.** The source art often bakes
  in a soft drop shadow ellipse under each pose. The game already draws its
  own shadow at runtime, so leaving it in doubles up. Matching by color
  distance (not "everything near the feet") means it survives poses where
  the shadow overlaps the standing pose's own feet.
- **Enclosed-hole removal was removed entirely.** An earlier version of the
  pipeline treated any enclosed light-colored blob (near-white, low
  saturation) as background residue and deleted it, on the theory that real
  gaps (between legs, under an arm) are narrow while a torso/sleeve is wide.
  Even with a width cap that heuristic still punched holes through
  legitimate light-colored art it had no business touching — white shirt
  fronts, eye highlights, a light character belly. The project's sources are
  now always already-clean transparent PNGs the user cut out themselves, so
  this step bought nothing but risk — it's gone, not just disabled. Do not
  reintroduce color-based enclosed-region deletion; if a source genuinely has
  baked-in background residue, that's a re-export problem, not something to
  paper over with a heuristic that also eats real art.
- **Verify against a dark background, not white.** A transparent hole and
  white fabric render identically against a white or light-checkered
  backdrop, which is how the hole above went unnoticed on first pass. The
  script writes `_source/dark_background_preview.png` — always look at that
  file (or composite the poses over a dark color yourself) before telling
  the user it's done, especially after touching the hole-removal or matte
  logic.
- **Matte erosion is capped at a couple of iterations with a mid-brightness
  band.** This cleans up the thin anti-aliased halo left from the original
  background removal without eating into legitimate dark shading or bright
  fabric — a wider brightness range or more iterations will start eroding
  real art, not just the halo.
- **Tall accessories (ears, hats, antennae) need `body_top_fraction`.** The
  game fits a character's whole silhouette height into a fixed-size box
  (`_scale_for_region` in `scripts/main.gd`). If a character wears something
  tall on their head, that box now has to fit "body + accessory", so the body
  itself renders smaller than every other character even though the art was
  drawn at the same scale — this is exactly what happened with `바니걸`'s
  rabbit ears. `character.json` already has a field for this:
  `"body_top_fraction": 0.2` tells the game to size off the bottom 80% of the
  silhouette only. There's no reliable way to detect this automatically from
  pixels alone (a first attempt at an automatic width-profile heuristic
  false-flagged a normal hairstyle and missed the actual ears — hair narrows
  and widens in ways that look just like an ear pinch), so estimate it by
  eye instead:
  1. Open `idle.png` and find the row where the *head/hair* actually starts
     (below any ears/hat/antennae) — the point after which the silhouette
     stops looking like a floating accessory and starts looking like hair on
     a scalp.
  2. `body_top_fraction ≈ (that row's y) / (idle.png's total visible height)`,
     rounded to something like 0.15–0.3 for most ear/hat cases.
  3. Set it with `--body-top-fraction <value>` when running the script, or
     just add `"body_top_fraction": <value>` to `character.json` directly
     afterward — the field only affects rendering, not the saved image files,
     so no need to rerun the whole pipeline for it.
  4. Rebuild the web export and compare the new character standing next to
     an existing one — adjust up or down (capped at 0.45) until the bodies
     look the same size.
- **Deliberately wanting a character bigger or smaller is a different
  knob: `scale_multiplier`.** Don't reach for `body_top_fraction` for this —
  that field corrects an artifact (tall headwear skewing the auto-fit), while
  `scale_multiplier` (also in `character.json`, e.g. `"scale_multiplier": 1.3`
  for 30% bigger) is a plain stylistic size change. **It only affects the
  character-select card preview** (`_draw_character_card` in
  `scripts/main.gd`) — the user specifically asked for the picker to look
  bigger while gameplay sizing stayed untouched, so it's intentionally not
  wired into `_prepare_character_regions` (the in-game jump-rope scale). If a
  future request wants it to affect gameplay too, that's a one-line addition
  there, but don't assume it should by default. Settable via
  `--scale-multiplier` on the script, or by editing `character.json` directly
  and just rebuilding the web export — no need to rerun the pipeline.
- **A per-character in-game size tweak is a third, separate knob:
  `gameplay_scale_multiplier`.** Same idea as `scale_multiplier` but wired
  into `_prepare_character_regions` in `scripts/main.gd`, so it actually
  changes how big the character renders during play (not just the picker
  card). Use this when the user asks for one specific character to look
  smaller/bigger *while playing* — e.g. `"gameplay_scale_multiplier": 0.9`
  for 10% smaller. Just edit `character.json` and rebuild the web export;
  no need to rerun the pipeline.
- **A fourth knob, `air_pose_scale_multiplier`, scales only the apex/air jump
  frame.** With `disable_jump_rescale` on (the default), all jump frames
  share one scalar sized off idle's height — a source pose with arms flung
  wide reads as noticeably bigger than idle even though it's shorter, because
  nothing corrects for the extra width. Wired into `_draw_player_sprite` in
  `scripts/main.gd`, applied only when the air/apex frame is showing (not the
  mid frame). Use when the user says one character's jump/apex pose looks
  oversized — e.g. `"air_pose_scale_multiplier": 0.95` for 5% smaller just at
  the apex. Edit `character.json` and rebuild the web export.
- **Jump-pose rescaling is off by default for pipeline-built characters
  (`disable_jump_rescale`).** `scripts/main.gd` used to always rescale the
  jump sprite so its bounding-box height matched idle's, to correct a real
  DPI mismatch in the original `default`/`pirate_girl` assets (their
  `idle.png` and `jump_sheet.png` came from different-resolution source
  files). But every character this pipeline builds comes from *one* source
  image at *one* consistent scale — there's no mismatch to correct. Rescaling
  anyway actively hurts: a crouched jump pose is legitimately shorter than
  standing (bent knees), so "fixing" its height to match idle inflates the
  whole sprite, making the character visibly balloon mid-jump — this broke
  `바니걸` after body_top_fraction/scale_multiplier were added. The script
  writes `"disable_jump_rescale": true` into `character.json` by default;
  pass `--enable-jump-rescale` only if you're deliberately reusing
  different-resolution idle/jump sources the old way. If you ever touch
  `_prepare_character_regions` in `main.gd`, keep this branch: rescale by the
  tallest jump pose's height (`max(region.size.y for region in
  player_jump_regions)`) only when `disable_jump_rescale` is false for that
  character; otherwise just use `player_base_scale` directly.

## After building

1. Look at `assets/characters/<id>/_source/dark_background_preview.png` —
   confirm no dark holes where fabric should be, and a visible transparent
   gap between legs / under arms.
2. Run the test suite from the project root:
   ```bash
   godot --headless --path . -s tests/rope_logic_test.gd
   ```
   It's fine (expected) if character-count assertions need a small update
   when adding a genuinely new character id — check `tests/rope_logic_test.gd`
   for hardcoded counts if it fails.
3. Rebuild the web preview so the user can check it themselves:
   ```bash
   godot --headless --path . --export-debug "Web" web/index.html
   ```
4. Report back briefly — what changed, test/build pass or fail, and point at
   the preview file rather than pasting a screenshot, per this project's
   preference for lower-token verification. Only take an actual browser
   screenshot if the user asks to see it rendered live.
