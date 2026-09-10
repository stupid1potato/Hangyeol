# Notarization prep checklist (week-6 draft)

역할: **개발자2** — 앱 셸 / 서명·공증 **준비 초안**.  
Views · Sheets · L10n 카피, XCFramework, engine, **실제 공증 실행**은 이 문서 범위 밖.

상태: **초안 · 확정 대기**. Apple Developer 팀/계정·ASC `.p8` / Team ID는 **owner**. 자격 전까지 공증은 **문서만** — 실행하지 않는다.  
week-7/8 내부 배포·Mac 회귀·빌드 안정: [week7-internal-regression.md](week7-internal-regression.md) (이 초안을 복제하지 않음).  
시크릿·`.p8`·Team ID·인증서를 리포에 넣지 않는다. `notarytool submit` / staple도 **하지 않는다**.

한계 메모: [known-limitations.md](../known-limitations.md) — MVP에 공증 없음.

---

## 이미 리포에 있는 값

| 항목 | 값 | 출처 |
|------|-----|------|
| Bundle ID | `app.hangyeol.mac` | `PRODUCT_BUNDLE_IDENTIFIER` |
| Hardened Runtime | **YES** | `ENABLE_HARDENED_RUNTIME` (Debug/Release) |
| App Sandbox | **YES** (이미 켜짐) | `ENABLE_APP_SANDBOX` + `Hangyeol.entitlements` |
| 현재 서명 | Automatic (로컬 개발) | `CODE_SIGN_STYLE = Automatic` |
| 배포 인증서 | Developer ID Application — **아직 없음** | owner, week-7 |

엔타이틀먼트 (`Apps/Hangyeol/Hangyeol/Resources/Hangyeol.entitlements`):

- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-write`
- `com.apple.security.files.bookmarks.app-scope`
- `com.apple.security.files.bookmarks.document-scope`
- `com.apple.security.print`

공증용으로 네트워크·키체인·카메라 등을 **추가하지 않는다**. Sparkle가 없으므로 updater 관련 엔타이틀먼트도 넣지 않는다.

Hardened Runtime은 켜져 있다. week-7에 Developer ID로 아카이브할 때 예외 엔타이틀먼트(`com.apple.security.cs.*`)가 필요하면 그때 검토한다. 지금은 JIT/unsigned-executable-memory 예외가 **없다**.

---

## 누가 무엇을

| | **개발자2 (week-6 준비)** | **owner (week-7)** |
|--|---------------------------|---------------------|
| 한다 | Bundle ID / Hardened Runtime / sandbox 엔타이틀먼트 확인. 아래 archive→notarize→staple **개요**만 유지. | Apple Developer **Team ID**. App Store Connect **API 키** (Issuer ID, Key ID, `.p8`). Developer ID Application 인증서. |
| 하지 않는다 | 팀/계정 요청, `notarytool` 제출, 자격 증명 커밋. | — |

week-6에 owner에게 팀/계정을 요청하지 않는다.

---

## Archive → notarize → staple (개요만)

Linux CI / Cloud Agent에서는 돌리지 않는다. Mac + Xcode CLT, **week-7**에 owner 자격이 있을 때.

1. **Archive** — `Apps/Hangyeol/Hangyeol.xcodeproj`, scheme `Hangyeol`, `generic/platform=macOS`, Developer ID Application.
2. **Export / zip** — 배포용 `.app`을 zip. (App Store 업로드가 아님. Direct / Developer ID.)
3. **Notarize** — `xcrun notarytool submit … --wait`. 키는 owner ASC API (`--key` / `--key-id` / `--issuer`). 플레이스홀더만:

   ```text
   xcrun notarytool submit Hangyeol.zip \
     --key <ASC_API_KEY.p8> \
     --key-id <ASC_KEY_ID> \
     --issuer <ASC_ISSUER_ID> \
     --wait
   ```

4. **Staple** — `xcrun stapler staple Hangyeol.app` 후 `spctl --assess --type execute` 로 Gatekeeper 확인.

`<ASC_*>` 는 owner가 week-7에 준다. 이 리포·이슈·PR에 값을 붙이지 않는다.

현재 `CODE_SIGN_STYLE = Automatic` 은 로컬 개발용이다. Developer ID 배포 시 Manual + 해당 identity로 바꿀지, 팀이 연결된 Automatic으로 둘지는 week-7에 owner 팀과 맞춘다. **pbxproj는 이 초안에서 바꾸지 않는다.**

---

## Sparkle / 자동 업데이트

**MVP 밖.** 도움말 카피는 「자동 업데이트와 미리보기는 이 버전에 없습니다」만 말한다 (`L10n.helpLimitMvpOut`). Sparkle 의존성·피드 URL·updater 엔타이틀먼트를 넣지 않는다.

---

## 체크 (개발자2, 리포만)

| # | 항목 | 통과 |
|---|------|------|
| 1 | Bundle ID가 `app.hangyeol.mac` | ☐ |
| 2 | Hardened Runtime YES, sandbox 엔타이틀먼트 유지 | ☐ |
| 3 | Developer ID / Team ID / ASC 키가 소스에 없음 | ☐ |
| 4 | Sparkle·공증 스크립트·자격 증명 없음 | ☐ |

---

## 범위 밖

week-7/8 셸 회귀·내부 배포 구분은 [week7-internal-regression.md](week7-internal-regression.md). 자격 없이 공증을 시도하지 않는다.

- Apple Developer 팀 가입 요청, 인증서 발급, `notarytool` 실제출, staple 산출물
- XCFramework 커밋, Views/Sheets/L10n 변경
- Sparkle, Quick Look, App Store Connect 앱 레코드
