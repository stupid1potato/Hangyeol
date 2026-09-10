# Image-meta list API (`hg_list_images`)

DocumentCore IR walk only. No BinData extract API, no renderer, no ZIP/XML writer.

**Keep-on-save** of ZIP `BinData/` through the existing `hg_save_hwpx` clear-before-save path is a **product gate** (week-6, hub-B). Not a measurement-only check.

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

## Product gate: keep-on-save (hub-B)

Sequence: open hub-B → DocumentCore FFI text edit (`hg_insert_text`) → `hg_save_hwpx` clear-before-save → reopen.

Locked by `hub_b_image_keep_on_save_clear_before_save_roundtrip` (`cargo test --manifest-path engine/Cargo.toml`). Same DocumentCore `line_segs.clear()` + `export_hwpx_native` path as hub-A. Not a new writer, extract API, or renderer.

| Check | Gate |
|-------|------|
| ZIP `BinData/` file count | preserved |
| ZIP `BinData/` bytes | preserved (name + content) |
| `hg_list_images` count + size/format meta | still valid after reopen |
| `hp:linesegarray` after save | 0 (existing clear-before-save contract) |
| Edited body token | survives reopen |

## Week-5 measurement (historical)

Recorded by the former `hub_b_image_clear_before_save_roundtrip_measurement` (open → `hg_plain_text` no-op → save → reopen, rustc 1.93.1). Week-6 productizes the **text-edit** path above; do not treat the no-op YES as the gate.

| Check | Result |
|-------|--------|
| Original ZIP `BinData/` entries | 1 |
| Saved ZIP `BinData/` entries | 1 |
| ZIP image binary/count preserved | YES |
| `hg_list_images` count before / after reopen | 1 / 1 |
| List count preserved | YES |
| `hp:linesegarray` after save | 0 |
