# Fixtures

샘플 코퍼스 · 왕복 기대값. **바이너리 `.hwp` / `.hwpx` 픽스처는 이 PR에 커밋하지 않는다.**

전체 목록·검증 포인트는 [`docs/week1-engine-comparison.md`](../docs/week1-engine-comparison.md) §C와 동일하다.

## 명명 · 매니페스트

- 파일: `fixtures/{id}_{slug}.{hwp|hwpx|bin}`
  - 예: `01_plain_ko.hwp`
  - 잘못된 확장자 네거티브는 예외: F13 `13_wrong_ext_hwp.dat`, F14 `14_wrong_ext_hwpx.pdf`
- 메타: [`manifest.json`](manifest.json) (스키마: [`manifest.schema.json`](manifest.schema.json))

계획 필드:

| 필드 | 설명 |
|------|------|
| `id` | `F01` … `F21` |
| `path` | 저장소 상대 경로 |
| `format` | `hwp5` \| `hwpx` \| `corrupt` \| `encrypted` |
| `expects` | `plainText?`, `sectionCount?`, `encrypted?`, `errorCode?` |
| `license` | 재배포 라이선스 |
| `sourceUrl?` | 공개 입수 URL |
| `owner` | `dev1` \| `hangul_owner` |

현재 `manifest.json`의 `fixtures` 배열은 비어 있다 (입수 전).

## Owner (Hangul) — 생성 스펙

Hangul에서 생성. 한 줄 스펙.

| id | pattern | format | 검증 | 생성 스펙 |
|----|---------|--------|------|-----------|
| F01 | `01_plain_ko.hwp` | HWP5 OLE2 | 포맷 detect, plain 텍스트 추출, 한글 인코딩 | Hangul에서 짧은 한글 문단 2~3개로 저장 |
| F02 | `02_plain_ko.hwpx` | HWPX | ZIP+mimetype, `Contents/section0.xml` 텍스트 추출 | F01을 Hangul에서 HWPX로 다른 이름 저장 **또는** team create |
| F03 | `03_plain_en_mix.hwpx` | HWPX | 한/영 혼용 추출·치환 경계 | Hangul에서 한/영 혼용 문단 작성 |
| F04 | `04_multi_section.hwpx` | HWPX | section0+section1+, 섹션 순회 추출 | Hangul에서 구역 나누기 2+ |
| F05 | `05_styles_mixed.hwpx` | HWPX | 굵게/크기/글꼴 혼재; 스타일은 `Contents/header.xml` | Hangul에서 굵게/크기/글꼴 혼재 |
| F06 | `06_simple_table.hwpx` | HWPX | 표 메타·셀 텍스트 추출/`hg_set_cell_text` | Hangul에서 2×3 표 |
| F07 | `07_nested_table.hwpx` | HWPX | 중첩 표(해당 시) 또는 병합 셀 | Hangul에서 중첩 표 또는 병합 셀 |
| F08 | `08_image_embed.hwpx` | HWPX | 이미지 바이너리/메타 추출, 텍스트 round-trip 시 이미지 보존 | Hangul에서 PNG 1장 삽입 |
| F09 | `09_header_footer.hwpx` | HWPX | 머리말/꼬리말 텍스트 분리 추출 | Hangul에서 머리말/꼬리말 작성 |
| F10 | `10_long_doc.hwpx` | HWPX | 장문(≥20p) 추출 성능·메모리 | Hangul 장문 작성 또는 공공 장문 공지 |
| F15 | `15_encrypted.hwp` | HWP5 encrypted | **ENCRYPTED 에러** (복호화 금지) | Hangul에서 암호화 저장 |
| F17 | `17_empty.hwpx` | HWPX empty/minimal | 빈 본문 | Hangul 새 문서 즉시 저장 |
| F19 | `19_roundtrip_replace.hwpx` | HWPX | 치환 후 linesegarray 제거·Hangul 재오픈 | Hangul에서 `[[TOKEN]]` 포함 문서 작성 |
| F20 | `20_units_a4_margins.hwpx` | HWPX | HWPUNIT A4 | Hangul에서 A4 여백 문서 작성 |

## Dev1 — 공개 / corrupt / wrong-ext

상태: **pending intake**. 라이선스 확인 전에는 바이너리를 커밋하지 않는다.

| id | pattern | format | 검증 | 입수 방법 | status |
|----|---------|--------|------|-----------|--------|
| F11 | `11_gov_sample.hwp` | HWP5 | 실사용 HWP5 복합 문서 | 공공: 법무부 표준임대차 영문 HWP 등 (MOJ / KOGL 확인 후) | pending intake |
| F12 | `12_gov_sample.hwpx` | HWPX | 실사용 HWPX | FreeHWP/msit-dl 또는 동 출처 | pending intake |
| F13 | `13_wrong_ext_hwp.dat` | HWP5 bytes / 잘못된 확장자 | magic/OLE2로 `.hwp` 판별 | F01 복사 후 확장자만 변경 | pending intake |
| F14 | `14_wrong_ext_hwpx.pdf` | HWPX bytes / 잘못된 확장자 | ZIP+`application/hwp+zip` mimetype 판별 | F02 복사 후 확장자 변경 | pending intake |
| F16 | `16_corrupt_truncated.hwp` | corrupt HWP | 우아한 에러 | safedocs example_corrupt.hwp 또는 truncate | pending intake |
| F18 | `18_table_image_mix.hwp` | HWP5 | 표+이미지+본문 | safedocs / team create | pending intake |
| F21 | `21_prettyprinted_bad.hwpx` | HWPX 네거티브 | pretty-print ZIP 깨짐 | F02 변형 | pending intake |

**공개 샘플 허브**: safedocs HWP test pages; https://github.com/FreeHWP/msit-dl — 라이선스 확인 필수.
