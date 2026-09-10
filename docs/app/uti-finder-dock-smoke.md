# UTI / Finder / Dock smoke (week-5)

역할: **개발자2** — app shell / UTI / sandbox / Info.plist.  
Views · Sheets · L10n 카피 재디자인, known-limitations, XCFramework, engine 은 **이 문서 범위 밖**.

기준 브랜치: `main` (PR **#31** 머지 이후). Linux CI / Cloud Agent는 Finder·Dock를 돌릴 수 없다. 아래 **Mac 수동** 칸은 개발자2 머신 연결 시 수행.

소스:

| 항목 | 경로 |
|------|------|
| 선언 | `Apps/Hangyeol/Hangyeol/Resources/Info.plist` |
| Swift UTI | `Apps/Hangyeol/Hangyeol/System/UTTypes.swift` |
| 열기·드롭 | `Apps/Hangyeol/Hangyeol/System/FileOpening.swift` |
| 문서 모델 | `HangyeolDocument` (`DocumentGroup` / `FileDocument`) |
| 샌드박스 | `Hangyeol.entitlements` + `SecurityScopedBookmarks.swift` + `RecentDocuments.swift` |
| 단위 테스트 | `HangyeolTests/FileOpeningTests.swift`, `HangyeolOpenFailureTests.swift` |

---

## 정적 계약 (리포에서 확인 · Mac 불필요)

한결이 **소유**하는 UTI만 쓴다. 한컴 UTI를 `UTImportedTypeDeclarations`로 가져오지 않는다.

| UTI | 확장자 | Swift | `DocumentFileType.typeIdentifier` |
|-----|--------|-------|-----------------------------------|
| `org.hangyeol.hwpx` | `hwpx` | `UTType.hangyeolHwpx` (`exportedAs:`) | `hwpx` |
| `org.hangyeol.hwp` | `hwp` | `UTType.hangyeolHwp` (`exportedAs:`) | `hwp` |

`UTType.hangyeolReadableTypes` == `[.hangyeolHwpx, .hangyeolHwp]` == `HangyeolDocument.readableContentTypes`.  
쓰기 타입은 HWPX만 (`writableContentTypes` == `[.hangyeolHwpx]`). HWP 디스크 저장은 엔진 `SAVE_REJECTED` → `HangyeolError.saveRejected` (PR #31). 그래도 Finder 핸들러는 **Owner + Editor** 로 둔다 (열기·기본 앱 순위).

### Info.plist 키 (둘 다 문서 타입에 동일)

- `CFBundleTypeRole` = **Editor**
- `LSHandlerRank` = **Owner**
- `LSItemContentTypes` = 해당 `org.hangyeol.*` (확장자 배열은 폴백)
- `UTExportedTypeDeclarations` 에 같은 식별자 + `public.filename-extension` + `public.data` / `public.content`
- 루트 `LSSupportsOpeningDocumentsInPlace` = **true** (샌드박스 제자리 열기)
- `UTImportedTypeDeclarations` **없음**

엔타이틀먼트: `com.apple.security.app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`, `files.bookmarks.document-scope`.

`xcodeproj` 는 `GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_FILE = Hangyeol/Resources/Info.plist` 로 병합한다. 문서 타입·UTI·제자리 열기는 **소스 Info.plist** 가 단일 출처다.

리뷰 (PR #31 기준): 선언·역할·드롭 경로에 공백 없음. **Info.plist diff 없음.**

---

## 코드 경로 (어디가 무엇을 여나)

Finder 더블클릭 / Dock 아이콘 드롭은 **DocumentGroup + Info.plist** 가 연다. `AppDelegate` 에 `application(_:open:)` 을 넣지 않는다. Week-2에서 `NSDocumentController` 를 기동 직후 건드리면 `PlatformDocumentController.createDocumentClassIfNeeded` SIGSEGV 가 났다.

창 드롭 · 커스텀 **문서 열기…** 패널 · 최근 문서 재열기는 `FileOpening` → `UTType.hangyeolSupports` 가드 → `OpenDocumentAction` / `NSDocumentController.openDocument`.

| 동작 | 진입 | 성공 | 실패 |
|------|------|------|------|
| Finder 더블클릭 `.hwpx` / `.hwp` | Launch Services → `DocumentGroup` / `HangyeolDocument.init(configuration:)` | 문서 창 | 엔진 freeze → `lastOpenError` → ErrorSheet (`.corrupt` / `.encrypted` / `.unsupported` …) |
| Dock 아이콘 · Finder에서 앱 아이콘으로 드롭 (선언된 타입) | 위와 동일 | 문서 창 | 위와 동일 |
| 문서 **창** 위에 드롭 | `onDrop(of: [.fileURL])` → `FileOpening.handleDrop` → `open(url:)` | 위와 동일 | 확장자 가드 실패 시 **즉시** `.unsupportedType` (무음 금지) |
| 파일 → 문서 열기… | `FileOpening.makeOpenPanel` (`allowedContentTypes` = 한결 UTI, `allowsOtherFileTypes` = false) | `FileOpening.open` | 패널에 `.pdf` 안 보임. 우회 드롭은 ErrorSheet |
| 최근 문서 | `RecentDocuments.open` → 북마크 `resolve` + `startAccessing` → `FileOpening.openResolved` | 재열기 | `.bookmarkFailed` / 열기 freeze |

`UTType.hangyeolSupports` 는 **경로 확장자만** 본다 (`hwpx` / `hwp`, 대소문자 무시). 바이트 매직은 쓰지 않는다. F14는 내용이 HWPX여도 `.pdf` 이면 false.

---

## Mac 수동 스모크 (개발자2)

전제: macOS 14+ / Apple Silicon, `Apps/Hangyeol/Hangyeol.xcodeproj` 서명 후 Run. XCFramework 없어도 Mock으로 열기 UX는 확인 가능. Real freeze(`.corrupt`) 매핑은 Vendor XCFramework가 있을 때 한 번 더.

픽스처는 저장소 `fixtures/` (라이선스: `docs/fixtures-intake-list.md`). 샌드박스 밖 경로가 편하면 Desktop에 복사.

| # | 단계 | 기대 | 통과 |
|---|------|------|------|
| 1 | UTI 정합 | Xcode Organizer 또는 `defaults read` / 빌드된 `Hangyeol.app/Contents/Info.plist` 에서 `org.hangyeol.hwpx` / `org.hangyeol.hwp`, `LSHandlerRank=Owner`, `LSSupportsOpeningDocumentsInPlace=true` | ☐ |
| 2 | Finder에서 `fixtures/hub_hwpxlib_SimpleTable.hwpx` (hub-A) **더블클릭** | 한결이 기동·전면, DocumentGroup 창에 표 본문. Preview/한컴으로 가면 기본 앱 확인 | ☐ |
| 3 | `.hwp` 더블클릭 | COMMIT_OK `.hwp` 가 없으면 번들 `Hangyeol/Resources/Sample/welcome.hwp` 를 Desktop에 복사해 사용. 한결 창이 열린다. F11 등 HOLD 바이너리 쓰지 말 것 | ☐ |
| 4 | hub-A를 **실행 중** 한결 **Dock 아이콘**에 드롭 | 새 문서 창 (또는 기존 창에 열림). FileOpening 가드는 이 경로에 없음 — Info.plist 타입이 맞아야 함 | ☐ |
| 5 | 한결이 **꺼진** 상태에서 같은 파일을 Dock / 앱 아이콘에 드롭 | 기동 + 해당 문서 창. 제자리 열기(in-place) — iCloud 아님, 샌드박스 user-selected | ☐ |
| 6 | hub-A를 **문서 창** 위로 드롭 | 점선 오버레이(`L10n.dropToOpen`) 후 열림. `AppDelegate` `registerForDraggedTypes(.fileURL)` + SwiftUI `onDrop` | ☐ |
| 7 | **F14** `fixtures/14_wrong_ext_hwpx.pdf` 를 **문서 창**에 드롭 | ErrorSheet **`.unsupportedType`** (`unsupportedType:14_wrong_ext_hwpx.pdf`). 무음 무시 금지. 내용이 HWPX여도 `.corrupt` 가 아님 | ☐ |
| 8 | F14를 Finder에서 더블클릭 | 한결이 `.pdf` Owner가 아님 → Preview 등이 연다. **실패가 아님.** 한결 ErrorSheet를 보려면 7번(창 드롭) | ☐ |
| 9 | F14를 Dock 아이콘에 드롭 | Launch Services가 선언되지 않은 타입을 거절(바운스)할 수 있음. ErrorSheet 보장은 **창 드롭** | ☐ |
| 10 | **F16** `fixtures/16_corrupt_truncated.hwpx` 더블클릭 또는 창 드롭 | 확장자는 `.hwpx` 이므로 가드 통과. ErrorSheet **`.corrupt`**. Mock도 삼키지 않음 (`HangyeolOpenBytes` / PR #31) | ☐ |
| 11 | hub-A를 연 뒤 종료 → 파일 → 최근 문서에서 재열기 | 샌드박스 북마크(`withSecurityScope`)로 다시 열림. 권한 시트 없이 본문 복구 | ☐ |
| 12 | 최근 문서 항목의 파일을 Finder에서 옮긴 뒤 재열기 | `.bookmarkFailed` 또는 열기 실패 시트. 무음 금지 | ☐ |

`AppDelegate.applicationShouldOpenUntitledFile` 가 true 라서, 파일로 기동해도 **빈 문서 창이 하나 더** 생길 수 있다. 스모크 실패로 보지 않는다 (EmptyState UX).

---

## 단위 테스트 (Mac `HangyeolTests`)

Linux에서는 `xcodebuild` 불가. 개발자2:

```text
Apps/Hangyeol/Hangyeol.xcodeproj → HangyeolTests
```

관련 케이스:

- `FileOpeningTests.testHangyeolSupportsHwpxAndHwpOnly`
- `testInfoPlistExportedUTIsMatchSwiftAndLaunchServicesKeys` — 소스 Info.plist ↔ `UTType` / Owner / in-place
- `testHangyeolSupportsUsesPathExtensionNotBytes` — F14 false, F16/hub-A true
- `testHandleDropReturnsFalseWhenNoFileURLProviders`
- `HangyeolOpenFailureTests.testWrongExtPdfFilenameIsUnsupportedType`
- `testMockOpenCorruptTruncatedFixtureDoesNotSwallow` / `testHangyeolDocumentOpenCorruptThrowsCorrupt`

---

## 범위 밖 (다음 PR)

- ErrorSheet 카피·도움말 알려진 한계 (PR #30 등 UI 트랙)
- XCFramework 커밋 / engine ABI
- WYSIWYG, Quick Look, 한컴 UTI import, 기본 앱 강제 (`lsregister` 자동화)
- F13 `.dat` (COMMIT_OK HWP 없음, detect 게이트는 F14)
