#!/bin/bash
# === README ===
# Script: reorg-meta.sh
#
# Purpose:
#   Fixes EXIF metadata and renames image files in a given year-based folder (e.g., 2015/).
#
# What it does:
#   - Requires the current directory to be named as a 4-digit year (e.g., 2008).
#   - Removes macOS metadata files (._*).
#   - Replaces spaces in filenames with dashes.
#   - Extracts EXIF date from image files (DateTimeOriginal or DateTimeDigitized).
#   - If missing or inconsistent with folder year, sets or corrects the EXIF date.
#   - Renames files to include suffix: `_MM_YYYY` (e.g., IMG1234_05_2015.jpg).
#   - Logs any EXIF update or rename errors to `reorg-errors.log`.
#
# Supported image formats:
#   JPG, JPEG, PNG, TIF(F), HEIC, BMP, GIF, WEBP, and various RAW formats (CR2, CR3, NEF, ARW, DNG, ORF, RW2).
#
# Requirements:
#   - Bash shell
#   - `exiftool` installed and available in PATH
#
# Usage:
#   Run inside a folder named by year:
#     $ cd /path/to/2013 && bash /path/to/reorg-meta.sh
#
# Notes:
#   - This script is non-destructive with renames (`mv -n`) but will overwrite EXIF metadata.
#   - Run with `bash`, not `sh`, due to Bash process substitution.


YEAR=$(basename "$PWD")

if ! [[ "$YEAR" =~ ^[12][0-9]{3}$ ]]; then
  echo "Error: Must run in a year folder (e.g., 2005). Found: $YEAR"
  exit 1
fi

echo "=== Fixing EXIF and renaming in: $PWD ==="
echo "=== Removing macOS metadata files (._*) ==="
find . -type f -name '._*' -print0 | xargs -0 -r rm -v

# Init error tracking
error_count=0
: > reorg-errors.log

while IFS= read -r -d '' file; do
  clean_path="${file#./}"

  # Replace spaces in filename with dashes
  dir=$(dirname "$file")
  base=$(basename "$file")
  if [[ "$base" =~ [[:space:]] ]]; then
    new_base="${base// /-}"
    new_file="$dir/$new_base"
    if [[ "$file" != "$new_file" ]]; then
      echo "[SPACE FIX] $clean_path → ${clean_path// /-}"
      mv -n "$file" "$new_file"
      file="$new_file"
      clean_path="${file#./}"
      base="$new_base"
    fi
  fi

  # Get DateTimeOriginal or DateTimeDigitized (source of truth)
  exif_date=$(exiftool -s3 -DateTimeOriginal "$file")
  if [[ -z "$exif_date" ]]; then
    exif_date=$(exiftool -s3 -DateTimeDigitized "$file")
  fi

  if [[ -z "$exif_date" ]]; then
    # No date found, set default Jan 1
    new_date="${YEAR}:01:01 00:00:00"
    echo "[SET DEFAULT] $clean_path"
  else
    exif_year="${exif_date:0:4}"
    month="${exif_date:5:2}"
    # If month is 00 or invalid, fallback to 01
    if ! [[ "$month" =~ ^(0[1-9]|1[0-2])$ ]]; then
      month="01"
    fi

    if [[ "$exif_year" != "$YEAR" ]]; then
      # Replace year with folder year but keep month/day/time
      new_date="${YEAR}${exif_date:4}"
      echo "[FIX YEAR] $clean_path (was: $exif_date → $new_date)"
    else
      echo "[OK] $clean_path (EXIF year: $exif_year)"
      new_date=""
    fi
  fi

  # Update EXIF dates only if needed
  if [[ -n "$new_date" ]]; then
    exiftool -overwrite_original \
      -MakerNotes:all= \
      "-DateTimeOriginal=$new_date" \
      "-DateTimeDigitized=$new_date" \
      "-CreateDate=$new_date" \
      "-ModifyDate=$new_date" \
      "$file"
    if [[ $? -ne 0 ]]; then
      echo "[ERROR] Failed to update EXIF: $clean_path" | tee -a reorg-errors.log
      ((error_count++))
    fi
  fi

  # Prepare rename suffix _MM_YYYY
  ext="${base##*.}"
  name="${base%.*}"

  if [[ ! "$name" =~ _[0-1][0-9]_[12][0-9]{3}$ ]]; then
    new_name="${name}_${month}_${YEAR}.${ext}"
    new_path="$dir/$new_name"
    if [[ "$file" != "$new_path" ]]; then
      echo "[RENAME] $clean_path → ${new_path#./}"
      mv -n "$file" "$new_path"
      if [[ $? -ne 0 ]]; then
        echo "[ERROR] Failed to rename: $clean_path" | tee -a reorg-errors.log
        ((error_count++))
      fi
    fi
  else
    echo "[SKIP RENAME] $clean_path (already renamed)"
  fi

done < <(find . -type f \( \
  -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
  -iname '*.tif' -o -iname '*.tiff' -o -iname '*.heic' -o \
  -iname '*.bmp' -o -iname '*.gif' -o -iname '*.webp' -o \
  -iname '*.cr2' -o -iname '*.cr3' -o -iname '*.nef' -o \
  -iname '*.arw' -o -iname '*.dng' -o -iname '*.orf' -o \
  -iname '*.rw2' \
\) ! -name '._*' -print0)

echo "=== Finished. Files with errors: $error_count ==="
[[ $error_count -gt 0 ]] && echo "See details in: reorg-errors.log"
