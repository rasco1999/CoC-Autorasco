# Vision model pipeline

This folder contains reproducible dataset checks and the planned training/export workflow for the TH15–TH18 analyzer.

## Current status

- No training images are bundled in this repository.
- No COCO annotations have been supplied.
- No detector weights or Core ML model are present.
- The iOS app must continue to use its clearly labelled manual-marking fallback until a real model passes evaluation.

## 1. Dataset layout

Recommended layout:

```
dataset/
  images/
    scout/
    battle_live/
    battle_replay/
  annotations/
    instances.json
  manifest.csv
  classes.json
```

Only images with permission_status equal to `owned`, `permission_granted`, or `license_allows` may enter training. Keep pending items out of every training and evaluation run.

## 2. Validate before training

From the repository root:

```bash
python3 ml/validate_dataset.py
```

When images and COCO annotations are available:

```bash
python3 ml/validate_dataset.py \
  --manifest dataset/manifest.csv \
  --images dataset/images \
  --classes dataset/classes.json \
  --coco dataset/annotations/instances.json
```

The validator checks required metadata, duplicate IDs/files, TH15–TH18 values, image existence, permission status, COCO category consistency, and village/session split leakage.

## 3. Annotation and split rules

- Use CVAT or Label Studio and export COCO detection annotations.
- Label visible objects only; never invent hidden traps.
- Keep wall segments as individual segments or a separate segmentation task.
- Keep every image of one village and every frame from one attack session in a single split.
- Maintain separate scorecards for scout, live-battle, and replay images.
- Do not treat battle frames as equivalent to intact scout images.

## 4. Training protocol

After the dataset is populated and validated:
1. Audit class balance and image quality by TH and capture type.
2. Train a compact detector with a fixed, recorded training configuration.
3. Evaluate on held-out villages/sessions, reporting per-class precision, recall, mAP@0.5, mAP@0.5:0.95, and per-TH/capture-type results.
4. Inspect false positives and false negatives manually.
5. Export to Core ML only after the model meets agreed acceptance thresholds.
6. Test latency, memory, thermal behavior, and detection quality on supported iPhones.

A detector identifies visible structures; it does not by itself infer pathing, defensive coverage, army suitability, or a reliable three-star plan. Those require separate geometry and strategy logic.

## 5. iOS integration gate

The app may expose automatic detections only when a versioned Core ML model is bundled and the app can report:
- model version and supported classes;
- confidence for each detection;
- user confirmation for uncertain detections;
- whether the input is scout, live battle, or replay;
- an explicit fallback when no compatible model is available.

Never silently present manual markers or heuristic sector scores as AI detections.
