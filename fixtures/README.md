# Fixtures

샘플 코퍼스 · 왕복 기대값.

**COMMIT_OK** Apache-2.0 허브 샘플(hub-A/B/C)과 그 허브에서 파생한 합성 픽스처(F14/F16/F21)만 바이너리로 커밋한다. **HOLD_LICENSE** 바이너리(MOJ / KOGL Type 2, SafeDocs LICENSE_UNKNOWN, msit per-article)는 커밋하지 않는다. 입수 판단은 [`docs/fixtures-intake-list.md`](../docs/fixtures-intake-list.md). 제3자 고지·SHA-256은 [`NOTICE`](NOTICE).

전체 F01–F21 검증 포인트는 [`docs/week1-engine-comparison.md`](../docs/week1-engine-comparison.md) §C와 동일하다.

## 명명 · 매니페스트

- 파일: `fixtures/{id}_{slug}.{hwp|hwpx|bin}`
  - 예: `01_plain_ko.hwp`
  - 잘못된 확장자 네거티브는 예외: F13 `13_wrong_ext_hwp.dat` (백로그), F14 `14_wrong_ext_hwpx.pdf`
  - 공개 허브 extras: `hub_hwpxlib_{upstreamName}.hwpx`
- 메타: [`manifest.json`](manifest.json) (스키마: [`manifest.schema.json`](manifest.schema.json))
- 합성 재생성: [`scripts/gen_synthetic_hwpx_fixtures.py`](../scripts/gen_synthetic_hwpx_fixtures.py) (hub-A → F14/F16/F21)

계획 필드:

| 필드 | 설명 |
|------|------|
| `id` | `F01` … `F21` 또는 `hub-A` … |
| `path` | 저장소 상대 경로 |
| `format` | `hwp5` \| `hwpx` \| `corrupt` \| `encrypted` (wrong-ext는 실제 바이트 포맷을 유지하고 역할은 `notes`) |
| `expects` | `plainText?`, `sectionCount?`, `encrypted?`, `errorCode?` |
| `notes` | 역할·파생 설명 (optional) |
| `license` | 재배포 라이선스 |
| `sourceUrl?` | 공개 입수 URL 또는 파생 원본 경로 |
| `owner` | `dev1` \| `hangul_owner` |

## Dev1 — COMMIT_OK (committed)

neolord0/hwpxlib `testFile/reader_writer/` 사본. Apache-2.0. SHA-256은 [`NOTICE`](NOTICE).

| id | path | format | status |
|----|------|--------|--------|
| hub-A | `hub_hwpxlib_SimpleTable.hwpx` | HWPX | **committed** |
| hub-B | `hub_hwpxlib_SimplePicture.hwpx` | HWPX | **committed** |
| hub-C | `hub_hwpxlib_sample1.hwpx` | HWPX | **committed** |

합성 픽스처는 모두 hub-A에서 파생 (`derived-from Apache-2.0 hub-A`). HOLD HWP/MOJ/SafeDocs를 쓰지 않는다.

| id | path | format | status |
|----|------|--------|--------|
| F14 | `14_wrong_ext_hwpx.pdf` | HWPX bytes / 잘못된 확장자 | **committed** — hub-A와 바이트 동일, 파일명만 `.pdf`. Week-1 **detect gate는 F14**. |
| F16 | `16_corrupt_truncated.hwpx` | corrupt (truncated ZIP) | **committed** — hub-A 앞 1024바이트. Week1 파일명은 `.hwp`였으나 COMMIT_OK 베이스가 HWPX라 `.hwpx`로 착지. |
| F21 | `21_prettyprinted_bad.hwpx` | HWPX 네거티브 패키징 | **committed** — XML pretty-print + mimetype이 마지막·DEFLATE. |

## Owner (Hangul) — 생성 스펙

Hangul에서 생성. 한 줄 스펙. **OWNER_HANGUL**.

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

## Dev1 — HOLD / backlog (not committed)

라이선스 HOLD 또는 게이트 밖 백로그. 바이너리를 커밋하지 않는다. **F13은 week-1 detect 게이트에서 제외** (백로그만). COMMIT_OK `.hwp`가 아직 없고, HOLD MOJ/SafeDocs HWP로 합성하지 않는다.

| id | pattern | format | 검증 | 입수 방법 | status |
|----|---------|--------|------|-----------|--------|
| F11 | `11_gov_sample.hwp` | HWP5 | 실사용 HWP5 복합 문서 | 공공: 법무부 표준임대차 영문 HWP 등 (MOJ / KOGL 확인 후) | **HOLD_LICENSE** (KOGL Type 2) |
| F12 | `12_gov_sample.hwpx` | HWPX | 실사용 HWPX | FreeHWP/msit-dl 또는 동 출처 | **HOLD_LICENSE** |
| F13 | `13_wrong_ext_hwp.dat` | HWP5 bytes / 잘못된 확장자 | magic/OLE2로 `.hwp` 판별 | F01 또는 cleared-gov COMMIT_OK HWP 복사 후 확장자만 변경 | **DEFERRED / backlog** — COMMIT_OK HWP 없음. Week-1 게이트 OUT. Detect는 **F14**. |
| F18 | `18_table_image_mix.hwp` | HWP5 | 표+이미지+본문 | safedocs / team create | **HOLD_LICENSE** |

**공개 샘플 허브**: safedocs HWP test pages; https://github.com/FreeHWP/msit-dl — 라이선스 확인 필수. SafeDocs / msit는 **HOLD_LICENSE**.
