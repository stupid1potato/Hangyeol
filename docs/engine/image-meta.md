# Image-meta list API (`hg_list_images`)

DocumentCore IR walk only. No BinData extract API, no renderer, no ZIP/XML writer, no keep-on-save product path (week-6).

## ABI

`hg_list_images(engine, out_images, capacity, out_count)` — same count-then-fill pattern as `hg_list_tables`.

`hg_image_info` (document-order `Control::Picture`, body then nested cell pictures):

| Field | Role for Kit |
|-------|----------------|
| `index` | 0-based addressing id |
| `section` / `paragraph` / `control` | DocumentCore location |
| `width` / `height` | `img_dim` when set, else common object size |
| `byte_len` | BinData IR length (0 if unknown); **not** an extract API |
| `bin_data_id` | `ImageAttr.bin_data_id` |
| `format[16]` | NUL-terminated `jpg` / `png` / … |
| `href[128]` | `Picture.href`, else `BinData/image{N}.{ext}` or `image{N}` |

Fixture: hub-B (`fixtures/hub_hwpxlib_SimplePicture.hwpx`). Gate: list returns ≥1 image with width/height > 0 and a known format.

## Round-trip measurement (not a product experiment)

Sequence: open hub-B → `hg_plain_text` only (no-op edit) → `hg_save_hwpx` clear-before-save → reopen.

Image keep-on-save stays week-6. This is a measurement of the existing clear-before-save path, not a new writer.

## Measurement result

Recorded by `hub_b_image_clear_before_save_roundtrip_measurement` (`cargo test --manifest-path engine/Cargo.toml`, rustc 1.93.1):

| Check | Result |
|-------|--------|
| Original ZIP `BinData/` entries | 1 |
| Saved ZIP `BinData/` entries | 1 |
| **ZIP image binary/count preserved** | **YES** |
| `hg_list_images` count before / after reopen | 1 / 1 |
| List count preserved | YES |
| `hp:linesegarray` after save | 0 (existing clear-before-save contract) |

Do **not** treat this YES as a productized “image keep on save” feature. Week-6 approval required to expand.
