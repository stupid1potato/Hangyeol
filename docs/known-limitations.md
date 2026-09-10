# Known limitations (week-6 draft)

손실·미지원 메모. **Not** a product freeze. Week-6 may revise.
앱 UX 카피는 Views / L10n이 담당한다. 아래 **앱**은 셸 범위, **Engine**은 코어 범위다.

## 앱

- **조판**: 한/글(Hangul)과 픽셀 단위로 같지 않다. WYSIWYG가 아니다. 화면은 본문·표 블록을 구조화해 보여 준다.
- **`.hwp` 저장**: 거절한다. 엔진 freeze `SAVE_REJECTED` → `HangyeolError.saveRejected`. HWPX로 저장하도록 안내한다. `.hwp` 읽기는 가능하다.
- **암호화/암호 문서**: 복호화하지 않는다. freeze `ENCRYPTED` → `HangyeolError.encrypted`.
- **손상·미지원 열기**: freeze `CORRUPT` / `UNSUPPORTED_VERSION`과 앱 `unsupportedType`이 ErrorSheet로 올라온다 (`HangyeolError.corrupt` / `.unsupported` / `.unsupportedType` / `.emptyFile`).
- **표·셀·문단**: 엔진이 받치는 서브셋만 편집한다 (`listTables` / `setCellText` / `insertText` / `deleteRange`). 이미지·메타는 앱에서 렌더하지 않으며, 엔진 목록 API는 [engine/image-meta.md](engine/image-meta.md)를 본다.
- **Mock vs Real**: XCFramework가 있으면 `KitRealEngine`(Real)이 기본. 롤백: `EngineClient.resetToMock()`, 실행 환경 `HANGYEOL_USE_MOCK=1` (`true` / `YES`), UserDefaults `HANGYEOL_USE_MOCK`. 절차: [week3-ffi-checklist.md](week3-ffi-checklist.md).
- **PDF/인쇄**: 문단+표 셀 `plainText`(구조화 텍스트)다. 한/글 조판 인쇄가 아니다.
- **공증 / Sparkle / Quick Look**: MVP 밖. week-6: 공증 준비 체크리스트 초안만 ([app/notarization-prep.md](app/notarization-prep.md), 확정 대기). Apple Developer 팀/계정 요청과 실제 공증은 week-7.

## Engine

- **HWP write**: `hg_save(..., HG_FILE_HWP)` is `SAVE_REJECTED` / `HG_UNSUPPORTED`. HWPX-only save.
- **Encrypted / DRM / HWP 3.x / HML**: not opened for edit (`ENCRYPTED` or `UNSUPPORTED_VERSION`). Decrypt / DRM bypass forbidden.
- **Corrupt / truncated**: `CORRUPT` (F16). No silent unsupported passthrough.
- **Clear-before-save**: `hp:linesegarray` is forced to 0. Default rhwp export is not the Hangyeol path.
- **Images**: `hg_list_images` is list/meta only. **Keep-on-save of image binaries is not a product gate.** Week-5 measurement on hub-B (open → plain_text → `hg_save_hwpx` clear-before-save → reopen): ZIP `BinData/` **binary/count preserved = YES**. Productizing that path needs week-6 approval ([engine/image-meta.md](engine/image-meta.md)).
- **Headers / footers / equations / shapes**: not in the freeze edit surface beyond body + table-cell text.
- **Renderer / layout / WASM / ZIP-fallback writer / Hangyeol-owned binary parser**: out of scope.
