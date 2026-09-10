# Hangyeol fixtures intake checklist (PUBLIC candidates)

- **Owner scope**: developer1 — F11, F12, F13, F14, F16, F18, F21 (+ useful public hub extras)
- **Date**: 2026-09-10 (KST)
- **Deadline context**: Fri 12:00 KST (2026-09-12 12:00 Asia/Seoul)
- **Rule**: listing + license judgment. **COMMIT_OK** binaries may be ingested with attribution. **Do NOT** download or commit **HOLD_LICENSE** binaries (MOJ / KOGL Type 2, SafeDocs LICENSE_UNKNOWN, msit per-article).
- **Hangul-owned (out of intake critical path)**: F01–F10, F15, F17, F19–F20 → `OWNER_HANGUL` / wait-if-arrives only (not blocking this list).

Path convention: `fixtures/{id}_{slug}.{ext}` + `fixtures/manifest.json`.

## Intake table

| F-id | proposed filename | source | license status | action |
|------|-------------------|--------|----------------|--------|
| F11 | `fixtures/11_gov_sample.hwp` | MOJ artclView 604194 / markitdown#2230 download.do | **KOGL Type 2** (상업적 이용금지) | **HOLD_LICENSE** |
| F12 | `fixtures/12_gov_sample.hwpx` | Same MOJ page / MSIT via msit-dl (per-article) | KOGL Type 2 / per-article HOLD | **HOLD_LICENSE** |
| F13 | `fixtures/13_wrong_ext_hwp.dat` | Synthetic rename from COMMIT_OK HWP | inherits base | **DEFERRED / backlog** — no COMMIT_OK `.hwp` on main (only HWPX hubs). Do **not** invent HWP bytes or use HOLD MOJ/SafeDocs. Out of week-1 gate; detect uses **F14**. Unblock later via Hangul F01 or cleared-gov HWP. |
| F14 | `fixtures/14_wrong_ext_hwpx.pdf` | Synthetic rename from hub-A HWPX | derived-from Apache-2.0 hub-A | **COMMIT_OK** (committed) — week-1 detect gate |
| F16 | `fixtures/16_corrupt_truncated.hwpx` | Synthetic truncate of hub-A (not SafeDocs) | derived-from Apache-2.0 hub-A | **COMMIT_OK** (committed). Week1 id was `16_corrupt_truncated.hwp`; path is `.hwpx` because the base is HWPX. |
| F18 | `fixtures/18_table_image_mix.hwp` | SafeDocs example_with_table.hwp | LICENSE_UNKNOWN | **HOLD_LICENSE** |
| F21 | `fixtures/21_prettyprinted_bad.hwpx` | Synthetic prettyprint-bad from hub-A | derived-from Apache-2.0 hub-A | **COMMIT_OK** (committed) |
| F22 | `fixtures/22_encrypted_synthetic.bin` | Synthetic Mock/app `HANGYEOL_ENCRYPTED` marker (not Hangul F15) | CC0 marker bytes | **COMMIT_OK** (committed) — app `HangyeolError.encrypted`. Real unknown-magic is CORRUPT. |
| hub-A | `fixtures/hub_hwpxlib_SimpleTable.hwpx` | neolord0/hwpxlib testFile/reader_writer/SimpleTable.hwpx | **Apache-2.0** | **COMMIT_OK** (committed) |
| hub-B | `fixtures/hub_hwpxlib_SimplePicture.hwpx` | hwpxlib SimplePicture.hwpx | **Apache-2.0** | **COMMIT_OK** (committed) |
| hub-C | `fixtures/hub_hwpxlib_sample1.hwpx` | hwpxlib sample1.hwpx | **Apache-2.0** | **COMMIT_OK** (committed) |
| hub-D/E/F | safedocs example/sample/mixed | SafeDocs hub | LICENSE_UNKNOWN | **HOLD_LICENSE** |
| hub-G | msit_* | FreeHWP/msit-dl (tool GPL; docs separate) | per-article KOGL unknown | **HOLD_LICENSE** |
| — | F01–F10, F15, F17, F19–F20 | Hangul authoring | team-owned | **OWNER_HANGUL** |

## Friday path (no Hangul block)

1. COMMIT_OK: hub-A/B/C + NOTICE/attribution in `fixtures/NOTICE` and `fixtures/manifest.json`. **Done** (binaries + NOTICE in git).
2. Synthetics from COMMIT_OK HWPX: **F14 / F16 / F21 done**. F16 is truncated HWPX (not SafeDocs `example_corrupt.hwp`). **F13 deferred** (no COMMIT_OK HWP; week-1 detect gate = F14 only).
3. F11/F12 quarantine outside git until commercial KOGL clearance.
4. F18 HOLD (SafeDocs LICENSE_UNKNOWN) or Hangul-owned later.

## Risks

1. KOGL Type 2 ≠ free commercial redistribution.
2. SafeDocs LICENSE_UNKNOWN — research URLs only.
3. msit-dl GPL ≠ document copyright.
4. Wrong-ext/prettyprint inherit base license.

*Updated 2026-09-10 KST. COMMIT_OK hub-A/B/C + synthetic F14/F16/F21 in git. F13 backlog. No HOLD_LICENSE binaries.*
