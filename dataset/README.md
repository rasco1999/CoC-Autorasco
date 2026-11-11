# CoC-AutoRasco Vision Dataset

This directory defines the dataset intake and annotation standard for the TH15–TH18 village analyzer.

## Status

- Dataset images: **not yet imported**.
- Labels/annotations: **not yet created**.
- Detection model: **not trained or integrated**.
- The app must not present automatic recognition as available until an evaluated model is shipped.

## Two required image types

The dataset deliberately includes both:

### A. Full village / scout screenshots
- Enemy village overview before an attack (war scout, multiplayer scout, or base overview).
- Entire village visible whenever possible.
- Used to detect buildings, defensive layout, walls, compartments, Town Hall, and likely entry routes.

### B. Attack / battle screenshots
- Screenshots captured during an active attack or from a replay.
- Include multiple moments where possible: deployment, early funnel, core engagement, spell/ability timing, and cleanup.
- Used to teach visual robustness under effects, troops, health bars, explosions, shadows, and partial occlusion, and to support later tactical-sequence analysis.
- A battle screenshot is not a substitute for a scout image: units and effects may obscure structures and the layout may be partially destroyed.

Keep the two types explicitly labelled in metadata. Do not mix them without recording the capture type.

## Free labelled pilot sample discovered

A free 30-frame sample is available from the dataset creator:
https://huggingface.co/datasets/nihatxp/clash-of-clans-screen-segmentation-sample

The sample page states that its 30 frames (10 scouting, 10 battle, 10 battle-end) may be downloaded and used for evaluation, research, and model training, and may be shared unchanged with a link to the dataset page. The sample has its own `coc-vision-licence`; retain the source link and do not resell it as standalone files or use it for cheats, bots, or auto-attack. This sample is useful for pipeline validation, but it does **not** establish coverage of TH15, TH16, TH17, and TH18 in balanced quantities. The sample images have not yet been copied into this repository.

Google Images is a discovery tool, not a content licence. Google says to check the Usage Rights filter and then verify each image's licence details with both the licensor and hosting site. Do not place an image in the training set merely because it appears in Google results.

## Public discovery sources

These are discovery/catalogue sources, not blanket permission to download or redistribute their images. Check each site's terms, creator attribution, and applicable Supercell fan-content rules before collecting or training on an image.

| Source | Useful coverage | Notes |
|---|---|---|
| https://huggingface.co/datasets/nihatxp/clash-of-clans-screen-segmentation | 12,799 labelled frames: 7,966 scouting, 4,564 battle, 269 battle-end | Paid access listed as $50; free 30-frame sample. Licence permits training/shipping models but forbids redistributing dataset/model as standalone files and forbids cheats/bots/auto-attack. Verify TH15–TH18 coverage and compatibility with our strictly manual coaching use before purchase/use. |

| https://goofygoblins.gg/bases?need=build | Community-submitted screenshots, TH15–TH18 filters | Candidate for genuine player-submitted screenshots; request permission/retain attribution where required. |
| https://cocbasefinder.com/ | 13,000+ layouts, TH9–TH18 | Layout previews and screenshot matching; confirm image reuse rights. |
| https://clashcompass.com/base | Published layouts including TH15–TH18 | Useful for layout diversity; may be polished layout previews rather than scout screenshots. |
| https://clashofclanslayouts.com/ | Large layout catalogue, TH15–TH18 | Useful for structural variety; verify freshness and image rights. |
| https://cocwarbase.com/ | War-base catalogue, TH8–TH18 | Useful for war layouts; verify image rights. |
| https://github.com/nschmeller/clash-bases | Aggregated base previews; lists TH15–TH18 counts | Inspect upstream source attribution and repository licence before reuse. |
| https://coclayout.com/ar-SA/bases | Arabic catalogue with TH15–TH18 filters | Useful for discovery; check image rights. |

## Collection target

Initial pilot: 400 distinct villages, balanced by Town Hall:
- TH15: 100
- TH16: 100
- TH17: 100
- TH18: 100

For each village, target at least:
- One full village/scout screenshot.
- Two to five battle/replay screenshots from the same village/attack where available.

These are different image samples, not different villages. Keep all images of the same village in the same train/validation/test split. Also group replay frames from the same attack session together to prevent leakage.

Recommended expansion after the pilot: at least 1,000–2,000 distinct villages, with multiple visual conditions and balanced classes.

## Image intake requirements

Prefer screenshots captured directly from Clash of Clans:
- Full village/scout images: full base visible, not clipped, normal in-game perspective.
- Battle images: record whether live attack or replay, and capture phase/frame index when known.
- Include different zoom levels, screen sizes, brightness, and overlays.
- Include dense and spread-out layouts, symmetric and asymmetric layouts.
- Record Town Hall level only when known; mark uncertain levels as unknown.
- Avoid duplicates and images with large UI overlays obscuring all useful content.

Store only images that the project is permitted to use. Keep a source/permission record for each image. Do not scrape or redistribute images in violation of site terms or creator rights. The Hugging Face dataset above is a potential licensed shortcut, not yet purchased or imported; inspect the full licence and confirm TH15–TH18 coverage before use. Its stated licence explicitly excludes cheats, bots, auto-attack, and standalone redistribution.

## Annotation standard

Use COCO object-detection JSON. Bounding boxes use pixel coordinates in the original image: [x, y, width, height].

Annotate visible instances only. Do not label hidden traps or buildings that cannot be seen. Use an occlusion attribute when an object is partly hidden but its identity is still clear. If identity is uncertain, use an ignore region rather than guessing.

For battle screenshots, annotate visible buildings and units separately only after the class schema is expanded and validated. Record destroyed/partially destroyed structures separately from intact structures. Do not infer a hidden building from its later appearance unless frames are linked by attack_session_id and the inference is explicitly stored as a temporal relation, not as a direct visual label.

Initial building classes are listed in classes.json. Add unit/effect classes in a separate schema after the building detector is stable.

## Split policy

Split by **village/base identity and attack session**, not by image file:
- Train: 70%
- Validation: 15%
- Test: 15%

Never put different screenshots/crops/frames of the same village or same attack session in more than one split. Keep TH15–TH18 and both capture types represented in every split. Report per-class precision, recall, mAP@0.5 and mAP@0.5:0.95, plus per-TH and per-capture-type metrics.

## Model acceptance gates

Do not enable automatic strategy recommendations until:
1. Town Hall and key defensive structures are detected reliably on held-out scout images.
2. Detection confidence is calibrated; uncertain detections are shown for user confirmation.
3. Wall/compartment reasoning is evaluated separately from object detection.
4. Battle-image robustness is measured separately from scout-image accuracy.
5. The strategy engine accounts for army composition, hero/pet/equipment availability where relevant, defensive geometry, and current game balance.
6. The app clearly distinguishes detected facts from inferred tactical suggestions.

## Suggested pipeline

1. Obtain permitted scout and battle/replay images and register metadata in manifest.csv.
2. Annotate building bounding boxes in CVAT or Label Studio.
3. Export COCO annotations.
4. Train a detector (e.g. YOLO-family model), evaluate by Town Hall and capture type.
5. Convert a compatible model to Core ML and test on supported iPhones.
6. Integrate Vision/Core ML inference into the iOS app.
7. Keep a human-confirmation step for low-confidence or ambiguous detections.

## Manifest fields

`image_id, file_name, town_hall, village_id, attack_session_id, source_url, creator, permission_status, capture_type, battle_phase, frame_index, split, notes`

Allowed capture_type values:
- `scout`
- `battle_live`
- `battle_replay`

Use permission_status values such as `owned`, `permission_granted`, `license_allows`, or `pending`. Do not train on `pending` images.
