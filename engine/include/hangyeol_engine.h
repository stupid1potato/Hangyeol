#ifndef HANGYEOL_ENGINE_H
#define HANGYEOL_ENGINE_H

/*
 * Hangyeol engine C ABI — rhwp DocumentCore thin cdylib.
 *
 * Two layers, one naming scheme (no third set of symbols):
 *
 *   1) HangyeolKit draft (Packages/HangyeolKit/.../hangyeol_engine.h)
 *      hg_open / hg_save / hg_free_buffer / hg_close
 *      hg_status: HG_OK | HG_UNSUPPORTED | HG_CORRUPT | HG_PASSWORD
 *
 *   2) Kickoff freeze edit API
 *      hg_plain_text / hg_replace_text / hg_save_hwpx
 *      plus optional hg_insert_text / hg_delete_range
 *      plus table: hg_list_tables / hg_set_cell_text
 *
 * Kit mapping (tables):
 *   hg_list_tables     → TableBlock addressing. `hg_table_info.index` is the
 *                        `table` argument to hg_set_cell_text. `rows`/`cols`
 *                        size the grid. `section`/`paragraph`/`control` locate
 *                        the DocumentCore table control for top-level tables.
 *   hg_set_cell_text   → cell plain-text write at (table, row, col). Merged
 *                        cells are addressed at any covered grid coordinate
 *                        (anchor via DocumentCore `cell_grid`).
 *
 * Freeze string codes ↔ Kit hg_status (1:1):
 *   ENCRYPTED            ↔ HG_PASSWORD
 *   UNSUPPORTED_VERSION  ↔ HG_UNSUPPORTED   (HWP 3.x, DRM, HML, out-of-scope format)
 *   SAVE_REJECTED        ↔ HG_UNSUPPORTED   (e.g. hg_save(..., HG_FILE_HWP) — HWPX-only write)
 *   CORRUPT              ↔ HG_CORRUPT       (truncated / unknown / malformed; F16)
 *
 * Engine: rhwp DocumentCore only (parser / serial / edit).
 * rustc ≥ 1.88. No renderer / layout / WASM UI is exported.
 *
 * Save contract: hg_save (HWPX) and hg_save_hwpx MUST clear every paragraph
 * and table-cell `line_segs` before serialize so the ZIP XML contains 0
 * `hp:linesegarray` nodes. Kit `hg_save` is that same HWPX clear-before-save
 * path (not a second writer).
 */

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Exactly four status kinds (HangyeolKit draft).
 *
 * HG_OK          — Success. The call completed; out-params are valid.
 * HG_UNSUPPORTED — Format, version, or operation is out of scope
 *                  (freeze: UNSUPPORTED_VERSION | SAVE_REJECTED).
 * HG_CORRUPT     — Truncated or malformed container (OLE2/ZIP/OWPML).
 *                  Freeze: CORRUPT. F16 truncated/unknown is CORRUPT, not a
 *                  vague unsupported passthrough.
 * HG_PASSWORD    — Encrypted / password-protected. Decrypt and DRM bypass
 *                  are forbidden. Freeze: ENCRYPTED.
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
 * One table in document order (body, then nested cell tables).
 *
 * Kit: map to a TableBlock. Pass `index` as `table` to hg_set_cell_text.
 * `rows` / `cols` are DocumentCore `row_count` / `col_count`.
 */
typedef struct hg_table_info {
    uint32_t index;      /* 0-based document order; hg_set_cell_text `table` */
    uint32_t section;    /* DocumentCore section index */
    uint32_t paragraph;  /* body paragraph that owns the (outer) table */
    uint32_t control;    /* control index in that paragraph (or cell para) */
    uint32_t rows;
    uint32_t cols;
} hg_table_info;

/* -------------------------------------------------------------------------- */
/* HangyeolKit layer (signatures match Packages/HangyeolKit header)           */
/* -------------------------------------------------------------------------- */

/**
 * Open a document from a memory buffer.
 *
 * Format is detected from **bytes**, not the path / extension and not `type`.
 * `type` is accepted for Kit ABI compatibility (F14: `.pdf` name, HWPX bytes).
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
 * HWPX (`HG_FILE_HWPX`): clear-before-save, then DocumentCore export.
 * HWP (`HG_FILE_HWP`): HG_UNSUPPORTED / freeze SAVE_REJECTED (HWPX-only write).
 *
 * On HG_OK, *out_bytes is an engine-owned buffer of *out_length bytes;
 * free with hg_free_buffer.
 */
hg_status hg_save(
    hg_engine *engine,
    hg_file_type type,
    uint8_t **out_bytes,
    size_t *out_length
);

/** Release a buffer returned by hg_save / hg_plain_text. NULL is a no-op. */
void hg_free_buffer(uint8_t *bytes);

/** Release an engine session. NULL is a no-op. */
void hg_close(hg_engine *engine);

/* -------------------------------------------------------------------------- */
/* Kickoff freeze edit API                                                    */
/* -------------------------------------------------------------------------- */

/**
 * Concatenate body + table-cell paragraph text (UTF-8).
 * On HG_OK, *out_bytes / *out_length as hg_save; free with hg_free_buffer.
 */
hg_status hg_plain_text(
    hg_engine *engine,
    uint8_t **out_bytes,
    size_t *out_length
);

/**
 * Replace every occurrence of `find` with `replace` (UTF-8, DocumentCore
 * `replace_all_native`, including table cells).
 * On HG_OK, *out_count is the number of replacements (may be 0).
 */
hg_status hg_replace_text(
    hg_engine *engine,
    const char *find,
    const char *replace,
    size_t *out_count
);

/**
 * Write HWPX to `path` (UTF-8 filesystem path). Same clear-before-save
 * as Kit `hg_save(..., HG_FILE_HWPX, ...)`.
 */
hg_status hg_save_hwpx(
    hg_engine *engine,
    const char *path
);

/**
 * Insert UTF-8 `text` at (section, paragraph, char_offset) in the body.
 * Optional freeze helper.
 */
hg_status hg_insert_text(
    hg_engine *engine,
    uint32_t section,
    uint32_t paragraph,
    uint32_t char_offset,
    const char *text
);

/**
 * Delete `count` characters at (section, paragraph, char_offset).
 * Optional freeze helper.
 */
hg_status hg_delete_range(
    hg_engine *engine,
    uint32_t section,
    uint32_t paragraph,
    uint32_t char_offset,
    uint32_t count
);

/**
 * List tables (DocumentCore IR walk — no ZIP/XML parser).
 *
 * Writes min(capacity, table count) entries into `out_tables`.
 * On HG_OK, *out_count is the total table count (may exceed capacity).
 * Pass capacity 0 / out_tables NULL to query the count only.
 *
 * Kit: use `index` + `rows`/`cols` to address cells via hg_set_cell_text.
 */
hg_status hg_list_tables(
    hg_engine *engine,
    hg_table_info *out_tables,
    size_t capacity,
    size_t *out_count
);

/**
 * Set cell plain text at (table, row, col).
 *
 * `table` is `hg_table_info.index` from hg_list_tables.
 * Replaces that cell's plain text (first paragraph; extra cell paragraphs
 * cleared). Merged cells: any covered (row, col) hits the anchor cell.
 *
 * Kit: TableBlock cell edit. Invalid table/row/col → HG_CORRUPT / CORRUPT.
 */
hg_status hg_set_cell_text(
    hg_engine *engine,
    uint32_t table,
    uint32_t row,
    uint32_t col,
    const char *text
);

/**
 * Freeze string code for the last failed call on this thread, or NULL after
 * success: "UNSUPPORTED_VERSION" | "ENCRYPTED" | "CORRUPT" | "SAVE_REJECTED".
 */
const char *hg_last_error(void);

#ifdef __cplusplus
}
#endif

#endif /* HANGYEOL_ENGINE_H */
