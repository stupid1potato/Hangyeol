# rhwp 코어 서브셋 게이트 표

- **날짜**: 2026-09-10 (KST)
- **스파이크**: edwardkim/rhwp 0.8.6 — `DocumentCore` / `detect_format` / `replace_all_native` / `export_hwpx_native`
- **금지 유지**: 렌더러·조판·WASM UI 임베드 없음. ZIP/XML 폴백 제품화 없음.

## 게이트 표

| 게이트 | PASS/FAIL/BLOCKED | 증거 |
|--------|-------------------|------|
| hub-A 치환→재추출 | **PASS** | `1`→`HGPOC99`; 저장 후 reextract 토큰 유지 |
| linesegarray 삭제 | **FAIL** (기본 export) | 저장 XML에 `hp:linesegarray` 14건 잔존. clear API 존재 → Hangyeol wrapper 저장 전 clear로 회복 가능 |
| mimetype 첫·STORE | **PASS** | 첫 엔트리 `mimetype`, STORE, `application/hwp+zip` |
| F14 detect | **PASS** | `.pdf`여도 `detect_format=Hwpx` |
| F16→CORRUPT | **PASS*** | 열기 실패·패닉 없음; `UNSUPPORTED_FILE_FORMAT` → FFI에서 `CORRUPT` 매핑 |
| hg_* C ABI 초안 가능 | **PASS** (가능) | `bindings/Native` cdylib 선례; `hg_open`/`hg_plain_text`/`hg_replace_text`/`hg_save_hwpx`/`hg_close` thin 추가 현실적 |
| rustc 요구사항 | **1.85 FAIL / 1.88 OK** | zip@8.6 needs 1.88; rhwp lib Finished OK on 1.88 |
| 한/글 개봉 | **BLOCKED** | Mac 수동 큐 |

\* = Hangyeol 에러 매핑 전제.

## 채택 권고

**rhwp `DocumentCore` 코어 서브셋을 엔진 1순위로 확정**하되, 제품 핀은 **rustc ≥ 1.88**, 저장 전 **linesegarray clear를 Hangyeol wrapper 필수 게이트**로 두고, 렌더러/조판/WASM은 제외한 thin cdylib만 채택한다.

## 다음

1. `engine/` thin FFI + save 전 line_segs clear + F14/F16 매핑 테스트
2. Mac 한/글 스모크 (치환본 / clear 후 본)
