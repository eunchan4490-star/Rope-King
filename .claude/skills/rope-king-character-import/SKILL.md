---
name: rope-king-character-import
description: Turn a 3-pose transparent PNG character sheet (idle/air/mid) into a playable 줄넘킹(Rope King) character — pose splitting (pure crop, no pixel retouching), idle.png + jump_sheet.png + character.json, and a rebuild+test pass. Use this whenever the user drops a new character image into the "julnumking asset" folder (or anywhere else) and wants it added, replaced, or fixed in this project — including requests like "이 캐릭터 추가해줘", "새 캐릭터 넣어줘", or "에셋 다시 넣어줘" after re-exporting a PNG.
---

# Rope King character import

This packages the workflow we iterated on manually: taking a hand-made or
AI-generated character sheet and turning it into the two files the game
actually loads (`idle.png`, `jump_sheet.png`) plus its `character.json`,
without reintroducing the mistakes that caused real regressions along the
way — an invisible hole punched through the shirt, a bite eaten out of a
character's own light-colored fur, a growing-on-jump bug, and images that
looked transparent but weren't.

The pipeline is now **pure crop-and-split — it never repaints or erases any
pixel of the source art**. Every earlier version of this script that tried
to "clean up" the art automatically (shadow-color removal, enclosed-hole
filling, matte-edge erosion) ended up eating real character art on some
character sooner or later, because a heuristic that recognizes "background
residue" by color/brightness/shape can't reliably tell that apart from a
character's own light fur, white shirt, or baked-in shading. The sources for
this project are always already-clean transparent PNGs the user cuts out
themselves, so there's nothing for a cleanup pass to legitimately fix — only
things for it to accidentally break. Do not reintroduce any pixel-level
cleanup step; if a source genuinely has background residue, a baked-in
shadow, or a soft-alpha halo, that's a re-export problem to fix at the
source, not something to paper over with a heuristic that also eats real
art.

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

- **No shadow removal, no enclosed-hole removal, no matte-edge erosion —
  all three were tried and all three were removed for the same reason.**
  Shadow removal matched a baked-in drop-shadow color, but on gray/tan/stone
  characters (`moai_human`) it also matched real body shading and punched
  speckled holes through it. Enclosed-hole removal treated any near-white
  enclosed blob as background residue, but that's also what a white shirt
  front, an eye highlight, or a light character belly looks like — it ate
  those on multiple characters even with a width cap meant to prevent it.
  Matte-edge erosion trimmed a couple pixels of "anti-aliasing halo" at the
  silhouette boundary, but on `kungfu_koala`'s pale gray-white ears that
  criteria matched the character's own real fur and ate a visible bite out
  of the top of its head. Three different heuristics, three different
  characters broken, same root cause: there is no reliable way to tell "this
  pixel is background residue" from "this pixel is legitimately
  light-colored art" by color/brightness/shape alone. **Do not add any new
  pixel-level cleanup step to this pipeline.** If a source genuinely has
  background residue, a baked-in shadow, or a soft-alpha halo, that's a
  re-export problem — ask the user to fix it at the source.
- **Verify against a dark background anyway, even with no cleanup step to
  break things.** A transparent hole and white fabric still render
  identically against a white or light-checkered backdrop, so this is still
  the fastest way to catch a source PNG that itself has a real problem (e.g.
  a translucent instead of fully-transparent background). The script writes
  `_source/dark_background_preview.png` — always look at that file (or
  composite the poses over a dark color yourself) before telling the user
  it's done.
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
- **A fifth knob, `jump_pose_scale_multiplier`, scales both jump frames (mid
  and air) uniformly** — distinct from `air_pose_scale_multiplier`, which
  only touches the apex frame. Wired into `_prepare_character_regions`,
  multiplying `player_jump_scale` directly. Use when the whole jump sequence
  (not just the apex) reads as bigger than idle — this is exactly the
  `default` character's situation: its idle/jump_sheet come from very
  different source resolutions, so `disable_jump_rescale` is off and the
  old height-matching rescale is active, which correctly caps jump height at
  idle's height but doesn't correct width, and in practice the whole jump
  sequence still reads as oversized. `"jump_pose_scale_multiplier": 0.95` for
  5% smaller on both frames. Edit `character.json` and rebuild the web
  export.
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
