#!/usr/bin/env python3
"""Validate CoC-AutoRasco image manifest and COCO annotations.

Run from the repository root:
    python ml/validate_dataset.py --manifest dataset/manifest.csv --images dataset/images --coco dataset/annotations/instances.json

The validator intentionally excludes permission_status=pending from usable data.
It also prevents leakage by requiring each village/attack session to belong to one split.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

ALLOWED_SPLITS = {"train", "val", "test"}
ALLOWED_TYPES = {"scout", "battle_live", "battle_replay"}
ALLOWED_PERMISSIONS = {"owned", "permission_granted", "license_allows", "pending"}
REQUIRED_COLUMNS = {
    "image_id", "file_name", "town_hall", "village_id",
    "attack_session_id", "source_url", "creator", "permission_status",
    "capture_type", "battle_phase", "frame_index", "split", "notes",
}


def fail(message: str, errors: list[str]) -> None:
    errors.append(message)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=Path("dataset/manifest.csv"))
    parser.add_argument("--images", type=Path, default=Path("dataset/images"))
    parser.add_argument("--classes", type=Path, default=Path("dataset/classes.json"))
    parser.add_argument("--coco", type=Path, help="Optional COCO instances JSON")
    args = parser.parse_args()

    errors: list[str] = []
    warnings: list[str] = []

    if not args.manifest.exists():
        print(f"ERROR: manifest not found: {args.manifest}")
        return 2

    with args.manifest.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        columns = set(reader.fieldnames or [])
        missing = REQUIRED_COLUMNS - columns
        if missing:
            fail("Manifest missing columns: " + ", ".join(sorted(missing)), errors)
        rows = list(reader)

    if not rows:
        warnings.append("Manifest is empty; no training data can be used.")

    image_ids: set[str] = set()
    file_names: set[str] = set()
    village_splits: dict[str, str] = {}
    session_splits: dict[str, str] = {}
    usable = []
    type_counts = Counter()
    th_counts = Counter()
    split_counts = Counter()

    for line, row in enumerate(rows, start=2):
        image_id = row.get("image_id", "").strip()
        filename = row.get("file_name", "").strip()
        village = row.get("village_id", "").strip()
        session = row.get("attack_session_id", "").strip()
        permission = row.get("permission_status", "").strip()
        capture = row.get("capture_type", "").strip()
        split = row.get("split", "").strip()
        th = row.get("town_hall", "").strip()

        if not image_id:
            fail(f"Line {line}: image_id is empty", errors)
        elif image_id in image_ids:
            fail(f"Line {line}: duplicate image_id {image_id}", errors)
        image_ids.add(image_id)

        if not filename:
            fail(f"Line {line}: file_name is empty", errors)
        elif filename in file_names:
            fail(f"Line {line}: duplicate file_name {filename}", errors)
        file_names.add(filename)

        if permission not in ALLOWED_PERMISSIONS:
            fail(f"Line {line}: invalid permission_status '{permission}'", errors)
        if capture not in ALLOWED_TYPES:
            fail(f"Line {line}: invalid capture_type '{capture}'", errors)
        if split not in ALLOWED_SPLITS:
            fail(f"Line {line}: invalid split '{split}'", errors)
        if th and th not in {"15", "16", "17", "18"}:
            fail(f"Line {line}: unsupported Town Hall '{th}'", errors)

        if village and split in ALLOWED_SPLITS:
            old = village_splits.setdefault(village, split)
            if old != split:
                fail(f"Village leakage: {village} appears in {old} and {split}", errors)
        if session and split in ALLOWED_SPLITS:
            old = session_splits.setdefault(session, split)
            if old != split:
                fail(f"Attack-session leakage: {session} appears in {old} and {split}", errors)

        if permission == "pending":
            warnings.append(f"Line {line}: pending permission; excluded from training.")
            continue
        if permission in ALLOWED_PERMISSIONS and capture in ALLOWED_TYPES and split in ALLOWED_SPLITS:
            usable.append(row)
            type_counts[capture] += 1
            th_counts[th or "unknown"] += 1
            split_counts[split] += 1
            if filename and not (args.images / filename).is_file():
                fail(f"Line {line}: image file missing: {args.images / filename}", errors)

    try:
        classes_data = json.loads(args.classes.read_text(encoding="utf-8"))
        class_ids = {int(item["id"]) for item in classes_data["classes"]}
        if len(class_ids) != len(classes_data["classes"]):
            fail("classes.json contains duplicate class IDs", errors)
    except Exception as exc:
        class_ids = set()
        fail(f"Could not parse classes file: {exc}", errors)

    if args.coco:
        if not args.coco.exists():
            fail(f"COCO file not found: {args.coco}", errors)
        else:
            try:
                coco = json.loads(args.coco.read_text(encoding="utf-8"))
                coco_ids = {int(c["id"]) for c in coco.get("categories", [])}
                if coco_ids != class_ids:
                    fail(f"COCO category IDs {sorted(coco_ids)} do not match classes.json {sorted(class_ids)}", errors)
                coco_image_ids = {str(i["id"]) for i in coco.get("images", [])}
                manifest_usable_ids = {r["image_id"].strip() for r in usable}
                missing_coco = manifest_usable_ids - coco_image_ids
                if missing_coco:
                    fail(f"{len(missing_coco)} usable manifest images are missing from COCO annotations", errors)
                unknown_image_refs = {
                    str(a.get("image_id")) for a in coco.get("annotations", [])
                } - coco_image_ids
                if unknown_image_refs:
                    fail("COCO annotations reference unknown image IDs", errors)
                unknown_categories = {
                    int(a.get("category_id")) for a in coco.get("annotations", [])
                    if "category_id" in a
                } - class_ids
                if unknown_categories:
                    fail(f"COCO annotations use unknown category IDs: {sorted(unknown_categories)}", errors)
            except Exception as exc:
                fail(f"Could not validate COCO JSON: {exc}", errors)

    print("CoC-AutoRasco dataset validation")
    print(f"Manifest rows: {len(rows)}")
    print(f"Usable rows (permission-cleared): {len(usable)}")
    print(f"Capture types: {dict(type_counts)}")
    print(f"Town Hall counts: {dict(th_counts)}")
    print(f"Split counts: {dict(split_counts)}")
    print(f"Distinct villages: {len(village_splits)}")
    print(f"Distinct attack sessions: {len(session_splits)}")
    for warning in warnings:
        print("WARNING:", warning)
    for error in errors:
        print("ERROR:", error)
    if errors:
        print(f"FAILED: {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    print(f"PASSED: {len(warnings)} warning(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
