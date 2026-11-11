# Annotation workflow

1. Open the original image in CVAT or Label Studio.
2. Draw a tight bounding box around each clearly visible building.
3. Label the instance using the exact `category_id` from `../classes.json`.
4. Add image-level metadata: Town Hall level, unique village_id, capture type, source URL, and permission status.
5. For battle/replay images, also record attack_session_id, battle_phase, and frame_index when known.
6. Export COCO detection annotations and preserve original image dimensions.
7. Keep all images of one village and all frames of one attack session in a single split.

## Capture-specific guidance

### Scout / full-village images
- Annotate every clearly visible building.
- Mark walls as segments or use a dedicated segmentation mask.
- Do not label hidden traps.
- Record the village's Town Hall level only when known.

### Live battle / replay images
- Annotate only structures still visually identifiable in that frame.
- Record partial destruction and occlusion as attributes; do not guess the original structure when identity is unclear.
- Do not label troop effects, spell effects, health bars, or UI controls as buildings.
- If the same village is shown across several frames, use one village_id and one attack_session_id for the entire sequence.
- Do not treat adjacent replay frames as independent examples when splitting train/validation/test.

## Quality checks

- No guessed labels for blurry/obscured structures.
- No hidden-trap labels from ordinary scout screenshots.
- Do not annotate decorative/UI elements as buildings.
- Check bounding boxes against the original full-resolution image.
- Have a second annotator review at least 10% of images.
- Record uncertain objects as ignored regions rather than forcing a class.

## Important

The initial class list is a starting point. Before annotation begins, verify class availability and appearance against the current game version for TH15, TH16, TH17, and TH18. New TH18-specific structures must not be incorrectly mapped to older defensive classes.
