# HangyeolEngine.xcframework (local, not committed)

Copy or symlink the Mac-built XCFramework here so HangyeolKit links live `hg_*`:

```bash
# from the repo root
mkdir -p Packages/HangyeolKit/Vendor
ln -s /Users/acb/Hangyeol-xcf-build/engine/target/xcframework/HangyeolEngine.xcframework \
  Packages/HangyeolKit/Vendor/HangyeolEngine.xcframework
```

Alternatively set `HANGYEOL_ENGINE_XCFRAMEWORK` to that path.

Do **not** commit `.xcframework`, `.a`, or `.dylib`. This directory is gitignored except this README.

See `Packages/HangyeolKit/README.md`. Mac 재현 절차 (PR #14): `docs/engine/xcframework.md` 절 **로컬 재현 (2026-09-10)**.
