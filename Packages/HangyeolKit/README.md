# HangyeolKit

Header + Swift stub + comments only. **No XCFramework yet.** The thin `hg_*` cdylib lives in `engine/` (PR #9) but this package **does not link it**. `RealEngine` waits for an XCFramework path.

`Apps/Hangyeol` must **not** import this package, must **not** add `RealEngine`, and must **not** call `hg_*`. The live engine stays `MockEngine`. Do not add this product to the Xcode project.

Week-3 order: **header sync (this package) → wait XCFramework → RealEngine → app link.** See [week-3 FFI checklist](../../docs/week3-ffi-checklist.md). XCFramework procedure (not linked yet): [`docs/engine/xcframework.md`](../../docs/engine/xcframework.md) (rustc **≥ 1.89**).

## Engine (팀장3 확정)

- **1순위:** rhwp **DocumentCore** 코어 서브셋 (parser / serial / edit only; renderer · layout · WASM 금지)
- **Toolchain:** rustc **≥ 1.88** (Hangyeol product pin; rhwp cargo graph may need ≥ 1.89; CI uses 1.93.1)
- **Save:** `hg_save(HWPX)` and freeze `hg_save_hwpx` **must** clear `line_segs` on body + table-cell paragraphs **before** serialize (`hp:linesegarray` count 0). This package does not implement that — header/README contract only.

## What this package is

A compile-able SwiftPM sketch of the FFI boundary. C ABI is **synced from** `engine/include/hangyeol_engine.h` (source of truth):

| Piece | Path | Role |
|-------|------|------|
| C ABI (synced) | `Sources/CHangyeolEngine/include/hangyeol_engine.h` | Kit: `hg_open` / `hg_save` / `hg_free_buffer` / `hg_close`. Freeze: `hg_plain_text` / `hg_replace_text` / `hg_save_hwpx` / `hg_insert_text` / `hg_delete_range` / `hg_last_error` |
| C stub | `Sources/CHangyeolEngine/hangyeol_engine.c` | Returns `HG_UNSUPPORTED` / `NULL` only (no parser, no `engine/` cdylib) |
| Swift stub | `Sources/HangyeolKit/` | Kit-local `HangyeolEngine` + `HangyeolEngineFFI` that throws `notLinked` |

SPM does not mix Swift and C in one target, so the header lives in a clang target (`CHangyeolEngine`) rather than under `Sources/HangyeolKit/include/`. There is **no** SPM `binaryTarget` for `engine/`.

## Status kinds (exactly four)

Defined as `hg_status` / `HangyeolStatus`:

| Name | Meaning | Freeze |
|------|---------|--------|
| `HG_OK` / `.ok` | Success | — |
| `HG_UNSUPPORTED` / `.unsupported` | Format, version, or operation out of scope | `UNSUPPORTED_VERSION`, `SAVE_REJECTED` |
| `HG_CORRUPT` / `.corrupt` | Truncated or malformed document (F16 truncated/unknown) | `CORRUPT` |
| `HG_PASSWORD` / `.password` | Encrypted / password-protected (decrypt forbidden) | `ENCRYPTED` |

`hg_last_error` on the real engine returns those freeze strings (or NULL after success). The C stub returns NULL.

## What this package is not

- Not linked from `Apps/Hangyeol` (no import, no xcodeproj product)
- Not a `RealEngine` implementation and not a live engine call path
- Not an XCFramework / not a binary link of `engine/` (`RealEngine` waits)
- Mock stays until XCFramework + RealEngine + app link, in that order
