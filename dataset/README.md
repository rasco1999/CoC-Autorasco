# CoC-AutoRasco Vision Dataset

This directory defines the dataset intake and annotation standard for the TH15–TH18 village analyzer.

## Status

- Dataset images: **not yet imported**.
- Labels/annotations: **not yet created**.
- Detection model: **not trained or integrated**.
- The app must not present automatic recognition as available until an evaluated model is shipped.

## Public discovery sources

These are discovery/catalogue sources, not blanket permission to download or redistribute their images. Check each site's terms, creator attribution, and applicable Supercell fan-content rules before collecting or training on an image.

| Source | Useful coverage | Notes |
|---|---|---|
| https://goofygoblins.gg/bases?need=build | Community-submitted screenshots, TH15–TH18 filters | Strong candidate for genuine player-submitted screenshots; request permission/retain attribution where required. |
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

Do not treat multiple crops, zoom levels, or screenshots of the same village as independent villages. Keep all images from one village in the same train/validation/test split.

Recommended expansion after the pilot: at least 1,000–2,000 distinct villages, with multiple visual conditions and balanced classes.

## Image intake requirements

Prefer screenshots captured directly from Clash of Clans:
- War scout / enemy village overview.
- Full village visible, not clipped.
- Normal in-game perspective and UI scale.
- Include different zoom levels, screen sizes, brightness, and overlays.
- Include both dense and spread-out layouts, symmetric and asymmetric layouts.
- Record Town Hall level only when known; mark uncertain levels as unknown.
- Avoid duplicate images and images with large UI overlays obscuring buildings.

Store only images that the project is permitted to use. Keep a source/permission record for each image.

## Annotation standard

Use COCO object-detection JSON (see `annotations/instances.json` schema example when created). Bounding boxes use pixel coordinates in the original image: [x, y, width, height].

Annotate visible instances only. Do not label hidden traps or buildings that cannot be seen. Use `occluded=true` only when the object is partly hidden but its identity is still clear. If identity is uncertain, use an ignore region rather than guessing.

Initial object classes are listed in `classes.json`. Add a class only after confirming the in-game building exists for the relevant Town Hall era and the class can be distinguished reliably.

## Split policy

Split by **village/base identity**, not by image file:
- Train: 70%
- Validation: 15%
- Test: 15%

Never put different screenshots/crops of the same village in more than one split. Keep TH15–TH18 represented in every split. Report per-class precision, recall, mAP@0.5 and mAP@0.5:0.95, plus per-TH metrics.

## Model acceptance gates

Do not enable automatic strategy recommendations until:
1. Town Hall and key defensive structures are detected reliably on held-out villages.
2. Detection confidence is calibrated; uncertain detections are shown for user confirmation.
3. Wall/compartment reasoning is evaluated separately from object detection.
4. The strategy engine accounts for army composition, hero/pet/equipment availability where relevant, defensive geometry, and current game balance.
5. The app clearly distinguishes detected facts from inferred tactical suggestions.

## Suggested pipeline

1. Obtain permitted images and register metadata in `manifest.csv`.
2. Annotate bounding boxes in CVAT or Label Studio.
3. Export COCO annotations.
4. Train a detector (e.g. YOLO-family model), evaluate by Town Hall and class.
5. Convert a compatible model to Core ML and test on supported iPhones.
6. Integrate Vision/Core ML inference into the iOS app.
7. Keep a human-confirmation step for low-confidence or ambiguous detections.

## Manifest fields

`image_id, file_name, town_hall, village_id, source_url, creator, permission_status, capture_type, split, notes`

Use `permission_status` values such as `owned`, `permission_granted`, `license_allows`, or `pending`. Do not train on `pending` images.
