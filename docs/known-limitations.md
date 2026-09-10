# Known limitations (week-6 draft)

손실·미지원 메모. **Not** a product freeze. Week-6 may revise.

## Engine

- **HWP write**: `hg_save(..., HG_FILE_HWP)` is `SAVE_REJECTED` / `HG_UNSUPPORTED`. HWPX-only save.
- **Encrypted / DRM / HWP 3.x / HML**: not opened for edit (`ENCRYPTED` or `UNSUPPORTED_VERSION`). Decrypt / DRM bypass forbidden.
- **Corrupt / truncated**: `CORRUPT` (F16). No silent unsupported passthrough.
- **Clear-before-save**: `hp:linesegarray` is forced to 0. Default rhwp export is not the Hangyeol path.
- **Images**: `hg_list_images` is list/meta only. **Keep-on-save of image binaries is not a product gate.** Week-5 measurement on hub-B (open → plain_text → `hg_save_hwpx` clear-before-save → reopen): ZIP `BinData/` **binary/count preserved = YES**. Productizing that path needs week-6 approval ([engine/image-meta.md](engine/image-meta.md)).
- **Headers / footers / equations / shapes**: not in the freeze edit surface beyond body + table-cell text.
- **Renderer / layout / WASM / ZIP-fallback writer / Hangyeol-owned binary parser**: out of scope.
