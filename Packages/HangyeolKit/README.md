# HangyeolKit

Header + Swift stub only. **No XCFramework yet.**

`Apps/Hangyeol` must **not** import this package until week 3 `RealEngine`. The live engine stays `MockEngine`. Do not add this product to the Xcode project.

## What this package is

A compile-able SwiftPM sketch of the future FFI boundary:

| Piece | Path | Role |
|-------|------|------|
| C ABI draft | `Sources/CHangyeolEngine/include/hangyeol_engine.h` | `hg_open` / `hg_save` / `hg_free_buffer` / `hg_close` |
| C stub | `Sources/CHangyeolEngine/hangyeol_engine.c` | Returns error statuses only (no parser) |
| Swift stub | `Sources/HangyeolKit/` | Kit-local `HangyeolEngine` + `HangyeolEngineFFI` that throws `notLinked` |

SPM does not mix Swift and C in one target, so the header lives in a clang target (`CHangyeolEngine`) rather than under `Sources/HangyeolKit/include/`.

## Status kinds (exactly four)

Defined as `hg_status` / `HangyeolStatus`:

| Name | Meaning |
|------|---------|
| `HG_OK` / `.ok` | Success |
| `HG_UNSUPPORTED` / `.unsupported` | Format, version, or operation out of scope (HWP 3.x, DRM, rejected save) |
| `HG_CORRUPT` / `.corrupt` | Truncated or malformed document |
| `HG_PASSWORD` / `.password` | Encrypted / password-protected (decrypt forbidden) |

## What this package is not

- Not linked from `Apps/Hangyeol`
- Not a `RealEngine` implementation
- Not an XCFramework / `cdylib` drop-in
- 1주차 README used to say “no sources in week 1”; that is replaced by this header+stub
