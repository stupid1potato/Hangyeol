#include "hangyeol_engine.h"

/*
 * Header-only compile unit. Package.swift compiles this instead of
 * hangyeol_engine.c when HangyeolEngine.xcframework is present so live
 * `hg_*` symbols come from the XCFramework (no HG_UNSUPPORTED stubs).
 *
 * This file must not define hg_open / hg_save / … — that would duplicate
 * the XCFramework.
 */
