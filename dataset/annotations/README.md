# Annotation workflow

1. Open the original image in CVAT or Label Studio.
2. Draw a tight bounding box around each clearly visible building.
3. Label the instance using the exact `category_id` from `../classes.json`.
4. Add image-level metadata: Town Hall level, unique village_id, capture type, source URL, and permission status.
5. Export COCO detection annotations and preserve original image dimensions.
6. Keep all images of one village in a single split.

## Quality checks

- No guessed labels for blurry/obscured structures.
- No hidden-trap labels from ordinary scout screenshots.
- Do not annotate decorative/UI elements as buildings.
- Check bounding boxes against the original full-resolution image.
- Have a second annotator review at least 10% of images.
- Record uncertain objects as ignored regions rather than forcing a class.

## Important

The initial class list is a starting point. Before annotation begins, verify class availability and appearance against the current game version for TH15, TH16, TH17, and TH18. New TH18-specific structures must not be incorrectly mapped to older defensive classes.
