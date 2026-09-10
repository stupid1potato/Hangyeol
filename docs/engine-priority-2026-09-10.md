# 엔진 우선순위 (2026-09-10)

**CONFIRMED** (팀장). 스파이크 증거: [rhwp 코어 서브셋 게이트 표](rhwp-core-subset-gate.md) · [openhwp PoC 게이트 보고](openhwp-poc-gate-report.md).

## 확정

- **1순위**: rhwp `DocumentCore` 코어 서브셋 (parser / serial / edit only).
- **제품 핀**: rustc **≥ 1.88**.
- **저장 전 필수**: Hangyeol wrapper에서 **linesegarray clear REQUIRED** (기본 export는 `hp:linesegarray` 잔존 → FAIL; clear API로 회복).
- **F16**: 열기 실패·패닉 없음. rhwp `UNSUPPORTED_FILE_FORMAT` → Hangyeol FFI **`CORRUPT`** 매핑.
- **openhwp**: **백업 전용**. stable rustc 1.85 크레이트 빌드 **FAIL** (`const_vec_string_slice`).

## 금지

- 렌더러 · 조판 · WASM UI 임베드 없음.
- ZIP/XML 폴백 **제품화 금지** (스파이크 증거일 뿐 제품 엔진이 되면 안 됨).

## Mac 한/글 큐

한/글 개봉 스모크는 **Mac 수동 큐**, 엔진 스파이크 착수 전까지 **pending**.

clear-before-save 이후 개봉할 아티팩트 경로 (생산되면):

- `engine/` 스파이크 출력, 또는
- `poc-notes/rhwp/SimpleTable-rhwp-replaced-cleared.hwpx`

엔진 스파이크가 해당 파일을 만들기 전에는 경로만 예약한다. 치환본 / clear 후 본 둘 다 큐에 올린다.
