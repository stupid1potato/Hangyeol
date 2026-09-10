# HangyeolKit

Header + Swift stub + comments only. **No XCFramework yet.** 개발자1 thin `hg_*` cdylib가 나오기 전에는 **구현 없음**.

`Apps/Hangyeol` must **not** import this package, must **not** add `RealEngine`, and must **not** call `hg_*`. The live engine stays `MockEngine`. Do not add this product to the Xcode project.

## Engine (팀장3 확정)

- **1순위:** rhwp **DocumentCore** 코어 서브셋 (parser / serial / edit only; renderer · layout · WASM 금지)
- **Toolchain:** rustc **≥ 1.88**
- **Save:** `hg_save` 전 **`hp:linesegarray` / lineseg clear 필수** (한/글 재오픈). 이 패키지는 호출하지 않음 — 헤더·README 계약만.

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

- Not linked from `Apps/Hangyeol` (no import, no xcodeproj product)
- Not a `RealEngine` implementation and not a live engine call path
- Not an XCFramework / rhwp `hg_*` cdylib (개발자1 산출 대기)
- 1주차 README used to say “no sources in week 1”; that is replaced by this header+stub
