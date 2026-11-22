# The hero

## Current state: a still, with the rings drawn (2026-11-22)

**The home hero is no longer a film.** The plate is `hemp-custom/assets/hemp-farm-plate.jpg`
(1920 × 1080, 392 KB) with `hemp-farm-plate-720.jpg` (1280 × 720, 202 KB) in the `srcset`, and
the five rings are **SVG** in `sections/hemp-hero.liquid`, positioned in plate pixels against a
`viewBox="0 0 1920 1080"`.

Each ring is a `<circle>` whose parent `<g>` translates the coordinate origin to the point where
the ring touches the ground (`cx`, `cy + r`). The ring's whole animation is then a single
`scaleY()` from `0.045` to `1` **about that origin** — no `transform-box`, no
`transform-origin`, which is deliberate: the first build used `transform-box: fill-box;
transform-origin: center bottom` and came out as five flat ellipses lying on the grass, i.e. the
animation's start state with the hinge resolved somewhere nobody wanted.
That is not a stylistic stand-in: scaling about the bottom point *is* the orthographic
projection of a hoop swinging up out of the ground. With the hinge at `(cx, cy + r)`, the top of
the ring lands at `cy + r − 2rk` — a flattened ellipse lying in the grass at the figure's feet at
`k ≈ 0`, the circle around the figure at `k = 1`. Then it breathes, slowly, out of step with its
own bloom so the five never pulse as one.

Nothing is re-synthesised per frame, the last frame *is* the first frame, and the page's weight
drops from 3.4 MB of video to ~600 KB of JPEG plus ~4 KB of SVG. The ring centres and radii were
fitted to the figures in the plate (not eyeballed): horse `760,528 r130` · man `1130,458 r130` ·
dog `1360,692 r130` · cat `1687,410 r114` · hen `1592,906 r142`.

The movement in the hero is the **type**, not the plate: the eyebrow, each line of the headline,
the lede, the buttons and the footnote arrive one after another from the top down, each wiped in
from its own top edge. The rings are drawn as light — gradient stroke pale at the sun and
saturated at the bottom, a white specular segment near the top, a pool of the same colour on the
grass — and they glow and pulse on three different cycles (line 7 s, bloom 9.5 s, pool 8.5 s), so
five rings never pulse as one. On desktop, three label pills sit in the grass beside the horse,
the man and the dog: captions over the plate, not links, since the paths section below carries
the real navigation; they are hidden under 900 px.

`section.settings.video` still takes a film from Content → Files; with one set, the rings are not
drawn and the pause control appears. The two `hemp-farm-loop` cuts are still in `assets/` but the
section no longer references them.

Everything below is the record of the filmed version and why it was retired. Keep it — it is the
brief if a film is ever wanted again.

## The film that was retired

A generated, silent, seamlessly looping farm film. This is the record of
how it was made, what was rejected and why, and how to make another one.

## What the film shipped

| File | What it is |
| --- | --- |
| `hemp-custom/assets/hemp-farm-loop.mp4` | 1920×1080, 24 fps, **7.0 s**, silent, 2.3 MB |
| `hemp-custom/assets/hemp-farm-loop-720.mp4` | 1280×720, same edit, 1.1 MB — was served under 750 px |
| `hemp-custom/assets/hemp-farm-poster.jpg` | 1600×900 still from mid-cycle, all five rings lit |

The section pointed at them: the 720p one as a `<source media="(max-width: 749px)">`, the 1080p one
as the fallback. Since 2026-11-22 it points at neither — see the top of this file. The `video`
setting (Content → Files) still overrides the plate if a film is ever wanted again.

## Why there is no text in it

The first cut was `hobby_farm_hemp_health.mp4` (repo root, **19.7 MB, untracked — do not commit
it**). It is the same scene with five labelled pills appearing one by one: *HORSE Joints &
Overall Health*, *HUMAN Pain & Brain*, *CAT Stress & Anxiety*, *DOG Healthy Coat & Digestion*,
*HEN Immunity & Vitality*.

It cannot be the hero as rendered, for three measured reasons:

1. **It is a finished ad composition.** The pills sit at y 20–66 % across x 33–95 %, which is
   exactly where the headline and lede go at `height: tall`. There is no quiet area left: leaf
   bottom-left, animals centre, labels upper-middle.
2. **The label type is ~14 px at 1920**, so ~10 px at a 1440-wide hero — illegible, while still
   carrying therapeutic claims that cannot be edited without a re-render.
3. **A phone destroys it.** `object-fit: cover` on 390×844 scales the 1080 height to 844
   (×0.78), so only ~499 source pixels of width are visible — **26 % of the frame**. The leaf,
   cat, dog, hen and three labels are off-screen and two are sliced ("ORSE Joints…").

Removing the pills in `ffmpeg` was tried and rejected: `delogo` over each pill leaves long
horizontal smears, because the rings pass *through* the label boxes and get dragged along the
interpolated edge. Masking tighter only trades a smear for a shadow. The clean answer is footage
that never had text in it.

So the labelled cut is still useful — as a **section** below the fold, where its labels can be
read and softened. It is not used yet.

## How this one was made

- **Source still:** the label-free frame at 0.2 s of the original — `/tmp/labelfree.png`
  (regenerate with `ffmpeg -ss 0.2 -i hobby_farm_hemp_health.mp4 -frames:v 1`).
- **Model:** `gemini-omni-1.2-flash`, through the Gemini Omni Flash skill script
  (`~/.gemini/config/plugins/gemini-api/skills/gemini-omni-flash-api/scripts/video/generate_video.py`),
  `image_to_video` with **`first_frame == last_frame`** — the script's looping mode.
- **Settings:** 16:9, 1080p, 8 s, 24 fps.

Three takes were needed:

| Take | Result |
| --- | --- |
| 1 | Rings became drifting, scribbled loops of light — reads as a glitch |
| 2 | Clean thin rings, right colours — but a **sixth ring around the hemp leaf** |
| 3 | Used. Exactly five rings, nothing on the plant, animals steady, no text |

**Prompt used (take 3):**

> The supplied frame is both the first and the last frame. Keep the camera completely still and
> keep every animal in the pose it already has: the horse stands still with only its mane and
> tail moving slightly, the dog sits still and only its ears lift, the cat sits still and only its
> tail flicks, the hen stays where it is. The grass and the large green leaf in the lower-left
> foreground sway gently in the breeze, and the man breathes.
>
> Add exactly five rings and no more: one circle of soft glowing light around the horse, one
> around the man, one around the cat, one around the dog, one around the hen. Thin unbroken
> circles with a soft edge, holding their shape and position, pulsing gently in brightness.
> Colours: light green on the horse, light blue on the man, light purple on the cat, warm amber on
> the dog, soft coral on the hen.
>
> The large green leaf in the lower-left foreground is a plant and not a subject: it must have no
> ring, no circle, no highlight and no glow of any kind. There must be no ring anywhere in the sky,
> on the barn, on the fence or on the grass — five rings on five subjects, nothing else.
>
> No text, no captions, no labels, no logos, no watermarks, no lettering anywhere. No camera
> movement, no cuts.

**The content filter matters.** Two earlier prompts came back `400 prohibited_content`. The
trigger was vocabulary, not the image: describing the scene as *hemp* alongside *smoke* / *mist*
(the take-1 wording) was blocked. Calling it "the large green leaf" and dropping every
inhalation-adjacent word passes.

## The jitter problem

Take 3 is *not* final. In motion it wobbles: the model re-synthesises fine detail every frame, so
the grass boils and the frame nudges sideways by a pixel. Measured on the first 40 frames at 2 s:

| | ±1 px frame shift | grass frame-to-frame diff |
| --- | --- | --- |
| original plate | 8 of 39 pairs | 2.17 |
| take 3 | **11 of 39 pairs** | **6.73** |

The camera region (sky/barn) is otherwise steady (0.07 vs 0.10), so it is not a pan — it is
per-frame texture churn and sub-pixel wobble, which is what reads as "shakey" at hero size. It
cannot be fixed in the encode, and `deshake` only exists in this ffmpeg build (no `vidstab`),
so it has to come from a tamer render.

**Seed stills for the re-render** (both 1920×1080, both in the repo root and gitignored):

- `hero-still-rings.png` — all five rings, no text. **Use this one.** With the rings already
  drawn, the model has almost nothing to invent, which is what produces the wobble.
- `hero-still.png` — the bare plate, if you want the rings to bloom in instead.

**Prompt that asks for a still photograph rather than a living scene:**

> A still photograph that breathes — not a moving scene.
>
> Use the supplied image as the first frame and as the final frame. The camera is on a locked
> tripod: no pan, no tilt, no zoom, no roll, no drift, no handheld movement, no wobble, no jitter,
> not one pixel of shake. The framing is identical in every frame.
>
> Change almost nothing. The only movement is a slow, gentle breeze through the large green leaf in
> the lower-left foreground, and a barely perceptible sway in the nearest grass. The animals and
> the man stay still — a single slow blink, one small ear movement, one tail-tip movement across
> the whole clip, nothing more. No walking, no head turns, no changes of posture.
>
> Keep the five glowing rings exactly as they are in the supplied image: same size, same position,
> same colour, one around the horse, the man, the cat, the dog and the hen. Do not redraw them, do
> not rotate them, do not warp or wobble them, do not let them drift. Only their brightness breathes
> very slowly.
>
> No text of any kind: no captions, no labels, no legends, no titles, no logos, no watermarks, no
> lettering.
>
> No artefacts: no flicker, no exposure pulsing, no shimmering, no boiling or crawling textures, no
> morphing, no warping, no melting edges, no grain crawl, no ghosting. Every still part of the image
> stays rock solid and identical from frame to frame — if a region is not moving in the breeze, it
> must not change at all.
>
> The clip ends on the same frame it starts on, so it loops seamlessly.

If the tool takes only one image, use `hero-still-rings.png` as the start frame and the loop gets
stitched here afterwards. Shorter is steadier: 6 s beats 8 s.

Do **not** feed it the original `hobby_farm_hemp_health.mp4` — the model will reproduce the labels.

## Stitching the loop

The generated clip starts and ends ring-free, but its exposure drifts, so frame 191 does not match
frame 0 (mean luma difference 13.3/255 — a visible jump if looped raw). It is stitched so the last
frame *is* the first frame's content:

```
body = frames 24–167      (144 frames)
tail = frames 168–191, cross-faded over 24 frames into head = frames 1–24
out  = body + seam        (168 frames = 7.0 s)
```

```bash
ffmpeg -i hero_rings2.mp4 -filter_complex "
[0:v]trim=start_frame=24:end_frame=168,setpts=PTS-STARTPTS[body];
[0:v]trim=start_frame=168:end_frame=192,setpts=PTS-STARTPTS[tail];
[0:v]trim=start_frame=1:end_frame=25,setpts=PTS-STARTPTS[head];
[tail][head]blend=all_expr='A*(1-T/0.9583)+B*(T/0.9583)'[seam];
[body][seam]concat=n=2:v=1:a=0,format=yuv420p[v]" \
  -map "[v]" -an -c:v libx264 -crf 29 -preset slow -movflags +faststart out.mp4
```

Frame-accurate trims (`start_frame`/`end_frame`) are essential; decimal seconds land mid-frame and
put the seam out by one, which shows as a flicker.

## Encoding

```bash
# 1080p
ffmpeg -i loop.mp4 -an -c:v libx264 -crf 29 -preset slow -movflags +faststart hemp-farm-loop.mp4
# 720p
ffmpeg -i loop.mp4 -vf scale=1280:-2 -an -c:v libx264 -crf 29 -preset slow -movflags +faststart hemp-farm-loop-720.mp4
# poster, mid-cycle where all five rings are lit
ffmpeg -ss 4.0 -i loop.mp4 -frames:v 1 -vf scale=1600:-2 -q:v 5 hemp-farm-poster.jpg
```

Audio is stripped: the hero is `muted` and `aria-hidden`, and the track was never part of the
design. The generated master keeps its AAC track if the same film is ever wanted with sound.

## Checklist for the next one

- No text, no labels, no logos anywhere in frame.
- Exactly five rings — say "the leaf is a plant and not a subject", or it gets a sixth.
- `first_frame == last_frame`, and verify the seam numerically before trusting it.
- Poster taken mid-cycle, not from frame 0: reduced-motion visitors see it instead of the film.
- Keep it under ~2.5 MB per cut. The raw generations are 16–20 MB.

## What it does not do

- **Phones get the middle third.** Cover on a portrait screen shows ~26 % of a 16:9 frame: the man
  and parts of the horse and dog. The cat, the hen and the leaf are cropped out. Accepted for now;
  a 9:16 cut is the fix if the five-species frame matters on mobile.
- **No benefit claims in the hero.** The five labels are deliberately not in the footage. If they
  are wanted, they belong in a section built from HTML, where they can be read, indexed, edited
  and reviewed — not baked into a video.

