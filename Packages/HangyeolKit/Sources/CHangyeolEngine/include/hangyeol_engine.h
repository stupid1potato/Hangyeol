#ifndef HANGYEOL_ENGINE_H
#define HANGYEOL_ENGINE_H

/*
 * Hangyeol C ABI draft (header + stub only).
 *
 * Engine (팀장3 확정): rhwp DocumentCore 코어 서브셋
 *   — parser / serial / edit only. renderer · layout · WASM 금지.
 * Toolchain: rustc ≥ 1.88 (개발자1 cdylib 빌드 기준).
 *
 * No implementation here until 개발자1 thin `hg_*` cdylib ships.
 * There is no XCFramework yet. Apps/Hangyeol must not import HangyeolKit,
 * must not add RealEngine, and must not call these symbols. MockEngine
 * remains the live engine.
 *
 * Opaque handle + open/save/close only. Edit helpers (hg_replace_text, …)
 * are week-2 freeze candidates and are intentionally omitted here.
 */

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Exactly four status kinds for this draft.
 *
 * HG_OK          — Success. The call completed; out-params are valid.
 * HG_UNSUPPORTED — Format, version, or operation is out of scope
 *                  (e.g. HWP 3.x, DRM, or .hwp write when only HWPX save is offered).
 * HG_CORRUPT     — Truncated or malformed container (OLE2/ZIP/OWPML).
 * HG_PASSWORD    — Encrypted / password-protected. Decrypt and DRM bypass are forbidden;
 *                  surface this error instead of attempting recovery.
 *
 * (Week-2 freeze notes used UNSUPPORTED_VERSION / ENCRYPTED / CORRUPT / SAVE_REJECTED.
 *  This draft keeps a four-kind ABI: ENCRYPTED maps to HG_PASSWORD; SAVE_REJECTED
 *  maps to HG_UNSUPPORTED until that freeze is implemented.)
 */
typedef enum hg_status {
    HG_OK = 0,
    HG_UNSUPPORTED = 1,
    HG_CORRUPT = 2,
    HG_PASSWORD = 3,
} hg_status;

typedef enum hg_file_type {
    HG_FILE_HWPX = 0,
    HG_FILE_HWP = 1,
} hg_file_type;

/** Opaque engine session. Caller owns it and must pass it to hg_close. */
typedef struct hg_engine hg_engine;

/**
 * Open a document from a memory buffer.
 *
 * On HG_OK, *out_engine is non-NULL and the caller must hg_close() it.
 * On any error, *out_engine is NULL (if out_engine itself is non-NULL).
 */
hg_status hg_open(
    const uint8_t *bytes,
    size_t length,
    hg_file_type type,
    hg_engine **out_engine
);

/**
 * Serialize the open session.
 *
 * REQUIRED (제품 엔진, 개발자1 cdylib): clear `hp:linesegarray` / lineseg
 * **before** writing. Hangul re-open after text replace depends on this.
 * This stub does not implement save or lineseg clear.
 *
 * On HG_OK, *out_bytes is a malloc'd buffer of *out_length bytes; free with hg_free_buffer.
 */
hg_status hg_save(
    hg_engine *engine,
    hg_file_type type,
    uint8_t **out_bytes,
    size_t *out_length
);

/** Release a buffer returned by hg_save. NULL is a no-op. */
void hg_free_buffer(uint8_t *bytes);

/** Release an engine session. NULL is a no-op. */
void hg_close(hg_engine *engine);

#ifdef __cplusplus
}
#endif

#endif /* HANGYEOL_ENGINE_H */
