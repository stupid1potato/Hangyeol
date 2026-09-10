# Hangyeol Week1 — 엔진 비교 초안 + 샘플 목록

- **날짜**: 2026-09-10 (KST)
- **범위**: 비교표 + 1안 추천 + 픽스처 목록만 (프로덕션/PoC 코드 없음)
- **제품**: Hangyeol (한결) macOS HWP document engine
- **조사 기준일**: 2026-09-10 UTC+9 (GitHub / crates.io / PyPI / README 스냅샷)

---

### A. 엔진 비교표

| 후보 | 언어 | 라이선스 | .hwp 읽기 | .hwpx 읽기 | 텍스트추출 | 편집/치환 | HWPX저장 | Swift FFI 적합성 | 활성도 | 메모 |
|------|------|----------|-----------|------------|------------|-----------|----------|------------------|--------|------|
| **openhwp/openhwp** | Rust | MIT | ✅ (HWP5) | ✅ | ✅ (`extract_text`) | 부분 (document/IR 크레이트; API 성숙도 UNKNOWN) | ✅ (README: HWPX write O; .hwp write ❌) | **높음** (Rust → `cdylib`/C ABI 현실적) | 중 (last push **2025-12-12**; crates.io 미게시, git dep) | 팀장3 지정 **1순위 PoC**. 크레이트 분리(`hwp`/`hwpx`/`ir`/`document`). 자체 바이너리 파서 신규 작성 회피용 베이스. |
| **edwardkim/rhwp** | Rust (+WASM/TS studio) | MIT | ✅ | ✅ | ✅ | ✅ (insert/delete/undo, hwpctl Actions) | ✅ (README: HWP 편집저장 + HWPX 의미보존 저장 주장) | 중~높음 (Rust 코어는 FFI 가능하나 **렌더러/조판 덩어리**가 큼) | **매우 높음** (pushed **2026-09-09**, ~3.8k★, npm `@rhwp/core` 활발) | 기능 최강. 단 tech-lead **커스텀 레이아웃 엔진 금지**와 충돌 위험 — 코어 파서/세리얼만 분리 임베드가 전제. Week2 FFI 동결에 면적이 큼. |
| **airmang/python-hwpx** | Python | Apache-2.0 | ❌ (명시: HWP v5 미지원) | ✅ | ✅ | ✅ (문단/표/이미지/헤더푸터 등) | ✅ (Hancom open 측정 주장; patch/rebuild receipt) | **앱 런타임 불가** (Python 금지) | 매우 높음 (pushed **2026-09-09**) | **폐기용 프로토타입/골든 비교**에만. HWPX 편집·저장 행동 명세 학습용. |
| **psychofict/hwpkit** | Python | MIT | ✅ (HWP5 + OLE rewrite 주장) | ✅ (extra) | ✅ | ✅ (폼 채움/셀 치환 주장) | ✅ 주장 (한컴 수락률은 공개 수치 약함) | **앱 런타임 불가** | 중 (pushed **2026-09-02**, ★ 적음, 신생) | **폐기용 프로토타입**. .hwp 길이 변경 시 컨테이너 재작성 아이디어 참고. 성숙도 낮음. |
| **hahnlee/hwp-rs** (`hwp` crate 0.2.0) | Rust | Apache-2.0 | ✅ | ❌ | ✅ (libhwp/Python 바인딩 중심) | ❌ | ❌ | 높음(이론) / 실사용은 읽기만 | **정체** (last push **2022-11-11**) | **레퍼런스 파서**. 쓰기/HWPX 없음. |
| **hahnlee/hwp.js** | TypeScript | Apache-2.0 | ✅ (뷰어/파서) | ❌ (주력 아님) | 부분 | ❌ (뷰어) | ❌ | 낮음 (JS/브라우저) | 낮음~중 (pushed **2025-01-10**, ★1.3k) | 포맷 이해·레퍼런스. Swift FFI 비적합. |
| **neolord0/hwpxlib** | Java | Apache-2.0 | ❌ | ✅ | ✅ (`TextExtractor`) | 부분 (`ObjectFinder` 등; 고수준 replace API는 샘플 의존) | ✅ | 낮음 (JVM → Swift 부담) | 높음 (pushed **2026-08-31**, Maven 1.0.9) | HWPX **오라클/레퍼런스**. 암호화는 `hwpxlib_ext`. |
| **neolord0/hwplib** | Java | Apache-2.0 | ✅ | ❌ | ✅ | ✅ (필드/표/이미지 샘플) | ❌ (별도 `hwp2hwpx`) | 낮음 (JVM) | 매우 높음 (pushed **2026-09-09**) | .hwp 편집 레퍼런스. macOS 앱 임베드 비추천. |
| **iyulab/unhwp** | Rust | MIT | ✅ | ✅ | ✅ (MD/TXT/JSON + assets) | ❌ | ❌ | **높음** (`ffi` feature, C-ABI 문서화) | 높음 (pushed **2026-09-09**, crates.io 활발) | **추출 전용**. 편집/저장 Own 범위 미충족. detect/extract 스파이크에만. |
| **ai-screams/HwpForge** (`hwpforge`) | Rust | UNKNOWN (crates.io license 필드 비움; 저장소 확인 필요) | ❌/부분 (HWPX 중심) | ✅ | 부분 | 부분 (프로그램적 Document 빌드) | ✅ (encoder) | 높음(이론) | 중 (crates.io **0.16.4**, upd **2026-08-28**) | HWPX 생성/인코드 참고. 기존 문서 in-place 치환은 UNKNOWN. |
| **teammilestone/hwarang** | Rust | UNKNOWN (crates 필드 비움) | ✅ (+HWP3) | ✅ | ✅ (배치/병렬) | ❌ | ❌ | 중 | 중 (0.4.0, **2026-08-14**) | 추출 특화. DRM/배포문서 복호화 언급 — Hangyeol은 **decrypt/DRM bypass 금지**이므로 해당 경로 사용 금지. |
| **Indosaram/hwpers** | Rust | UNKNOWN | ✅ | ❌ | 부분 | ❌ | ❌ | 중 | 낮~중 (0.5.0, **2026-01**) | 파싱+레이아웃/SVG — 레이아웃 엔진 Own 범위 밖. |
| **sboh1214/hwp-swift** | Swift | **LGPL-2.1** | ✅ 주장 | UNKNOWN | UNKNOWN | UNKNOWN (R/W 표기) | UNKNOWN | 네이티브 Swift (FFI 불필요) | 최근 (pushed **2026-09-10**) | LGPL 링크 의무/바이럴 리스크. 자체 파서 유지비. 1안 비추천. |

**표 읽는 법**: ✅/❌는 README·공개 API·릴리즈 주장 기준. Hangul 실기 수락률·치환 후 `hp:linesegarray` 삭제 규칙 준수는 대부분 **미검증 → UNKNOWN을 테스트로 확인**해야 함.

**Week2 FFI 심볼 후보 (동결 대상, 한 줄)**: `hg_open`, `hg_plain_text`, `hg_replace_text`, `hg_insert_text`, `hg_delete_range`, `hg_list_tables`/`hg_set_cell_text`, `hg_save_hwpx`, `hg_close`.

---

### B. 1안 추천

**Primary path (PoC 1순위): `openhwp/openhwp` (Rust 워크스페이스) → thin C ABI → Swift**

- **왜 1안**: tech-lead 제약(앱 런타임 **No Python**, **Rust/C ABI** 선호, **자체 바이너리 파서 from scratch 금지**, HWPX 저장 Own)과 가장 잘 맞음. README가 `.hwp` 읽기 / `.hwpx` 읽기·쓰기 / IR·document 모델을 명시.
- **Swift FFI**: Rust `cdylib` + cbindgen으로 위 Week2 심볼만 노출. 조판/뷰어 코드를 앱에 넣지 않음(엔진 ↔ Swift UI 분리).
- **저장 전략 정합**: HWPX를 정식 저장 경로로; `.hwp`는 가능하면 단순 치환, 불가 시 **에러 코드 + HWPX 저장 유도** — openhwp도 `.hwp` write는 `-`이므로 제품 정책과 자연스럽게 일치.
- **rhwp를 1안으로 두지 않은 이유**: 편집/저장 성숙도는 최고이나 풀 뷰어·페이지네이션·렌더러를 끌어오면 **커스텀 레이아웃 엔진 금지**·FFI 면적 동결에 불리. (파서/세리얼만 서브셋 추출은 2안/벤치마크 후보로 유지.)
- **Throwaway prototype**: `python-hwpx`(HWPX round-trip·한컴 수락 행동), 필요 시 `hwpkit`(`.hwp` 스트림 길이 변경 실험). CI/노트북에서만, 앱 번들 금지.
- **Reference only**: `hahnlee/hwp-rs`, `hahnlee/hwp.js`, `neolord0/hwpxlib`(+`hwplib`), `hwp2hwpx` — 포맷·오라클·회귀 기대값.
- **추출 스파이크(옵션)**: `unhwp` C-ABI로 `hg_plain_text`/포맷 감지 속도 비교 가능. 편집 경로로는 채택하지 않음.
- **리스크 (정직하게)**: openhwp는 rhwp 대비 **활성도·문서화된 편집 API·한컴 round-trip 공개 증거**가 약함(last meaningful push 2025-12). PoC 게이트: (1) HWPX 텍스트 치환 후 Hangul 오픈 (2) `hp:linesegarray` 삭제 (3) mimetype 첫 엔트리 uncompressed (4) wrong-ext detect. 실패 시 fallback 재평가 대상은 **rhwp 코어 서브셋** 또는 **hwpxlib 오라클 + 자체 thin HWPX writer**(ZIP+XML만, 바이너리 파서 신규 금지 유지).

---

### C. 샘플 목록 (약 20종)

팀 픽스처 디렉터리 관례: `fixtures/{id}_{slug}.{hwp|hwpx|bin}` + 메타 `fixtures/manifest.json` (기대 plain text, 섹션 수, 암호화 여부).

| id | filename pattern | format | 검증 포인트 | 입수 방법 |
|----|------------------|--------|-------------|-----------|
| F01 | `01_plain_ko.hwp` | HWP5 OLE2 | 포맷 detect, plain 텍스트 추출, 한글 인코딩 | team must create in Hangul (짧은 문단 2~3개) |
| F02 | `02_plain_ko.hwpx` | HWPX | ZIP+mimetype, `Contents/section0.xml` 텍스트 추출 | F01을 Hangul에서 HWPX로 다른 이름 저장 **또는** team create |
| F03 | `03_plain_en_mix.hwpx` | HWPX | 한/영 혼용 추출·치환 경계 | team create in Hangul |
| F04 | `04_multi_section.hwpx` | HWPX | section0+section1+, 섹션 순회 추출 | team create (구역 나누기 2+) |
| F05 | `05_styles_mixed.hwpx` | HWPX | 굵게/크기/글꼴 혼재; 스타일은 `Contents/header.xml` | team create |
| F06 | `06_simple_table.hwpx` | HWPX | 표 메타·셀 텍스트 추출/`hg_set_cell_text` | team create (2×3 표) |
| F07 | `07_nested_table.hwpx` | HWPX | 중첩 표(해당 시) 또는 병합 셀 | team create in Hangul |
| F08 | `08_image_embed.hwpx` | HWPX | 이미지 바이너리/메타 추출, 텍스트 round-trip 시 이미지 보존 | team create (PNG 1장 삽입) |
| F09 | `09_header_footer.hwpx` | HWPX | 머리말/꼬리말 텍스트 분리 추출 | team create |
| F10 | `10_long_doc.hwpx` | HWPX | 장문(≥20p) 추출 성능·메모리 | team create 또는 공공 장문 공지 |
| F11 | `11_gov_sample.hwp` | HWP5 | 실사용 HWP5 복합 문서 | 공공: 법무부 표준임대차 영문 HWP 등 (MOJ / KOGL 확인 후) |
| F12 | `12_gov_sample.hwpx` | HWPX | 실사용 HWPX | FreeHWP/msit-dl 또는 동 출처 |
| F13 | `13_wrong_ext_hwp.dat` | HWP5 bytes / 잘못된 확장자 | magic/OLE2로 `.hwp` 판별 | F01 복사 후 확장자만 변경 |
| F14 | `14_wrong_ext_hwpx.pdf` | HWPX bytes / 잘못된 확장자 | ZIP+`application/hwp+zip` mimetype 판별 | F02 복사 후 확장자 변경 |
| F15 | `15_encrypted.hwp` | HWP5 encrypted | **ENCRYPTED 에러** (복호화 금지) | team create in Hangul |
| F16 | `16_corrupt_truncated.hwp` | corrupt HWP | 우아한 에러 | safedocs example_corrupt.hwp 또는 truncate |
| F17 | `17_empty.hwpx` | HWPX empty/minimal | 빈 본문 | Hangul 새 문서 즉시 저장 |
| F18 | `18_table_image_mix.hwp` | HWP5 | 표+이미지+본문 | safedocs / team create |
| F19 | `19_roundtrip_replace.hwpx` | HWPX | 치환 후 linesegarray 제거·Hangul 재오픈 | team create (`[[TOKEN]]`) |
| F20 | `20_units_a4_margins.hwpx` | HWPX | HWPUNIT A4 | team create |
| F21 (보너스) | `21_prettyprinted_bad.hwpx` | HWPX 네거티브 | pretty-print ZIP 깨짐 | F02 변형 |

**공개 샘플 허브**: safedocs HWP test pages; https://github.com/FreeHWP/msit-dl — 라이선스 확인 필수.

---

### D. 다음 액션 (짧게)

1. **Lead**: openhwp PoC 승인 + Week2 FFI 동결; rhwp 벤치마크만인지.
2. Hangul 생성 픽스처 소유자·마감 (F15, F19, F07 등).
3. Developer2: manifest 스키마 + Hangul 수락 스모크.
4. Legal: 공공 샘플 재배포; hwp-swift LGPL 제외 유지.
5. PoC 게이트: HWPX 치환→Hangul 오픈; wrong-ext; ENCRYPTED; Python 0.

---

### E. Sources

- https://github.com/openhwp/openhwp
- https://github.com/edwardkim/rhwp
- https://github.com/airmang/python-hwpx
- https://github.com/psychofict/hwpkit
- https://github.com/hahnlee/hwp-rs
- https://github.com/hahnlee/hwp.js
- https://github.com/neolord0/hwpxlib
- https://github.com/neolord0/hwplib
- https://github.com/iyulab/unhwp
- https://github.com/FreeHWP/msit-dl
- http://test-pages.d2.menlotest.com/safedocs/hwp/

---

*본 문서는 2026-09-10 조사 스냅샷이며, write/edit 한컴 수락률은 주장≠검증이다. UNKNOWN은 추측으로 채우지 않았다.*
