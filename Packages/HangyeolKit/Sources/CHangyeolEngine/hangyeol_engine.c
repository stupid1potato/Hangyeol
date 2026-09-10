#include "hangyeol_engine.h"

/*
 * Stub implementation: always fail. No real parser, no decrypt, no write.
 * Linked only inside this package; Apps/Hangyeol must not depend on HangyeolKit.
 */

hg_status hg_open(
    const uint8_t *bytes,
    size_t length,
    hg_file_type type,
    hg_engine **out_engine
) {
    (void)bytes;
    (void)length;
    (void)type;
    if (out_engine) {
        *out_engine = NULL;
    }
    return HG_UNSUPPORTED;
}

hg_status hg_save(
    hg_engine *engine,
    hg_file_type type,
    uint8_t **out_bytes,
    size_t *out_length
) {
    (void)engine;
    (void)type;
    if (out_bytes) {
        *out_bytes = NULL;
    }
    if (out_length) {
        *out_length = 0;
    }
    return HG_UNSUPPORTED;
}

void hg_free_buffer(uint8_t *bytes) {
    (void)bytes;
}

void hg_close(hg_engine *engine) {
    (void)engine;
}
