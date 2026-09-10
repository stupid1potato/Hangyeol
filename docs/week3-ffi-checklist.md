# Week-3 FFI integration checklist

HangyeolKit tracks the engine C ABI **without** linking the app or the Rust cdylib.

`engine/include/hangyeol_engine.h` is the source of truth. Kit copy:
`Packages/HangyeolKit/Sources/CHangyeolEngine/include/hangyeol_engine.h`.

## This week

- [x] **Header sync** — Kit header matches `engine/include/hangyeol_engine.h` on main (symbols, comments, freeze mapping, edit API).
- [x] Swift FFI stub declarations cover the synced ABI (`hg_plain_text` / `hg_replace_text` / `hg_save_hwpx` / `hg_insert_text` / `hg_delete_range` / `hg_last_error`). Methods still throw `notLinked`; C stubs return `HG_UNSUPPORTED` / `NULL`.
- [x] C target still compiles with no-op stubs for the new freeze symbols.
- [x] **Mock stays.** `Apps/Hangyeol` does not import HangyeolKit. No RealEngine, no xcodeproj / XCFramework wiring, no SPM binary link of `engine/`.

## Next (blocked on XCFramework — do not skip ahead)

- [ ] Wait for / vendor an **XCFramework** built from `engine/` — procedure: [`docs/engine/xcframework.md`](engine/xcframework.md) (rustc **≥ 1.89** product pin; CI 1.93.1).
- [ ] Implement HangyeolKit **`RealEngine`** over that XCFramework (live `hg_*` calls).
- [ ] **Then** link HangyeolKit from `Apps/Hangyeol` (xcodeproj product).
- [ ] Replace `MockEngine` with `RealEngine` in the app only after the steps above.

## Contracts that must survive the later link

- **Clear-before-save.** `hg_save(..., HG_FILE_HWPX, ...)` and `hg_save_hwpx` walk DocumentCore sections / body paragraphs / table-cell paragraphs, `line_segs.clear()`, then `export_hwpx_native`. Result: `hp:linesegarray` count **0**. Kit `hg_save` is that same HWPX path, not a second writer. `.hwp` write is `SAVE_REJECTED` / `HG_UNSUPPORTED`.
- **Freeze ↔ Kit.** `ENCRYPTED` → `HG_PASSWORD`; `UNSUPPORTED_VERSION` / `SAVE_REJECTED` → `HG_UNSUPPORTED`; `CORRUPT` → `HG_CORRUPT`. F16 truncated/unknown → **CORRUPT**, not unsupported passthrough.
- **Toolchain.** rustc **≥ 1.88** (Hangyeol product pin).
- **Scope.** DocumentCore parser / serial / edit only. No renderer / layout / WASM UI, no Hangyeol-owned binary parser, no ZIP/XML product writer.

## Forbidden until XCFramework exists

- `Apps/Hangyeol` `import HangyeolKit`
- `RealEngine` in the app
- xcodeproj / XCFramework wiring
- Calling the real engine cdylib from the HangyeolKit package build
