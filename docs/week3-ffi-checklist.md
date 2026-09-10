# Week-3 FFI integration checklist

HangyeolKit tracks the engine C ABI. Kit **RealEngine** is implemented; the app is **not** linked yet.

`engine/include/hangyeol_engine.h` is the source of truth. Kit copy:
`Packages/HangyeolKit/Sources/CHangyeolEngine/include/hangyeol_engine.h`.

## This week

- [x] **Header sync** — Kit header matches `engine/include/hangyeol_engine.h` on main (symbols, comments, freeze mapping, edit API).
- [x] Swift FFI stub declarations cover the synced ABI (`hg_plain_text` / `hg_replace_text` / `hg_save_hwpx` / `hg_insert_text` / `hg_delete_range` / `hg_last_error`). Methods still throw `notLinked`; C stubs return `HG_UNSUPPORTED` / `NULL`.
- [x] C target still compiles with no-op stubs for the new freeze symbols.
- [x] **Mock stays.** `Apps/Hangyeol` does not import HangyeolKit. No RealEngine in the **app**, no xcodeproj product, no EngineClient swap.

## Kit RealEngine (this package — XCFramework not committed)

- [x] Vendor path for a **local** XCFramework (`Packages/HangyeolKit/Vendor/HangyeolEngine.xcframework` or env `HANGYEOL_ENGINE_XCFRAMEWORK`). Gitignored. Mac **재현 절차** is [docs/engine/xcframework.md — 로컬 재현 (2026-09-10)](engine/xcframework.md#로컬-재현-2026-09-10) (PR #14). Linux CI keeps the C stub.
- [x] HangyeolKit **`RealEngine`**: owns `hg_engine*`; live `hg_*` when the XCFramework is present (`HANGYEOL_ENGINE_LINKED`); `notLinked` fallback when absent. Freeze ↔ Kit mapping in Kit. **App still unlinked.**

## Next (app — do not skip ahead)

- [ ] **Then** link HangyeolKit from `Apps/Hangyeol` (xcodeproj product).
- [ ] Replace `MockEngine` with `RealEngine` in the app only after the step above.

Mac XCFramework 재현(`.a` / `nm hg_*`)은 PR #14 문서에 있다. Kit live-`hg_*` 검증은 이후 단계 (Linux cannot run the Apple binary). 이 PR에 앱 링크·Mock 교체는 넣지 않는다.

## Contracts that must survive the later link

- **Clear-before-save.** `hg_save(..., HG_FILE_HWPX, ...)` and `hg_save_hwpx` walk DocumentCore sections / body paragraphs / table-cell paragraphs, `line_segs.clear()`, then `export_hwpx_native`. Result: `hp:linesegarray` count **0**. Kit `hg_save` is that same HWPX path, not a second writer. `.hwp` write is `SAVE_REJECTED` / `HG_UNSUPPORTED`.
- **Freeze ↔ Kit.** `ENCRYPTED` → `HG_PASSWORD`; `UNSUPPORTED_VERSION` / `SAVE_REJECTED` → `HG_UNSUPPORTED`; `CORRUPT` → `HG_CORRUPT`. F16 truncated/unknown → **CORRUPT**, not unsupported passthrough.
- **Toolchain.** rustc **≥ 1.89** (Hangyeol product pin).
- **Scope.** DocumentCore parser / serial / edit only. No renderer / layout / WASM UI, no Hangyeol-owned binary parser, no ZIP/XML product writer.

## Forbidden until the app-link PR

- `Apps/Hangyeol` `import HangyeolKit`
- `RealEngine` in the app / `EngineClient` swap
- xcodeproj product wiring
- Committing `.xcframework` / `.a` / `.dylib`
