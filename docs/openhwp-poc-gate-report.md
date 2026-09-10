# openhwp PoC 게이트 스파이크 보고

- **날짜**: 2026-09-10 (KST)
- **환경**: Linux box, `rustc 1.85.0` (stable)
- **픽스처**: Hangyeol `main` hub-A + PR#4 F14/F16/F21
- **FFI 에러 (동결)**: `UNSUPPORTED_VERSION | ENCRYPTED | CORRUPT | SAVE_REJECTED`
  - F21 `BAD_PACKAGE` → 구현 시 `CORRUPT` 또는 `SAVE_REJECTED`로 매핑 (문서용 라벨)

## 게이트 결과

| 게이트 | 결과 | 증거 / 메모 |
|--------|------|-------------|
| **openhwp 크레이트 빌드** | **FAIL** | `ir` 크레이트: `Vec::len`/`is_empty` not stable as const fn (`const_vec_string_slice`). git dep `openhwp#c605402f`. |
| **치환 → 재추출** | **PASS*** | *ZIP/XML 폴백 스파이크* (openhwp typed API 아님). 저장본 `section0.xml`에 `HGPOC99` 존재. |
| **linesegarray 삭제** | **PASS*** | 저장본에서 `linesegarray` 0건. |
| **mimetype 첫 엔트리·무압축** | **PASS*** | 첫 엔트리 `mimetype`, STORE. |
| **F14 wrong-ext detect** | **PASS** (패키징) | `.pdf`여도 PK ZIP + mimetype STORE → 확장자 무시 시 HWPX 판별 가능. |
| **F16 CORRUPT** | **PASS** (패키징) | 1024B truncate → ZIP 오픈 실패 → FFI `CORRUPT`. |
| **F21 BAD_PACKAGE** | **OBSERVED** | mimetype 비정상 배치; FFI는 CORRUPT/SAVE_REJECTED 매핑. |
| **한/글 개봉** | **BLOCKED** | Linux에 한/글 없음 → Mac 수동 스모크 필요. |
| **ENCRYPTED** | **N/A** | F15 백로그. |

\* = openhwp 라이브러리 경로가 아니라 ZIP+OWPML 직접 조작 폴백.

## 블로커

1. openhwp는 현재 stable rustc 1.85에서 컴파일 실패 → nightly/패치 또는 48h 내 rhwp 코어 서브셋 재평가.
2. 치환 PASS는 폴백 writer 증거이지 openhwp write API 증거 아님.
3. 한/글 round-trip 미검증.

## 권장 다음

- engine 스파이크: toolchain 해결 후 `hg_plain_text` / F14 detect / F16 CORRUPT
- 실패 지속 시 rhwp 코어 서브셋 재평가 (렌더러 금지)

*스파이크 스냅샷. 엔진 PR 없음.*
