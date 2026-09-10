import Foundation

enum L10n {
    static let appName = String(localized: "app.name", defaultValue: "한결")
    static let appTagline = String(localized: "app.tagline", defaultValue: "한글 문서를 열고 본문과 표를 확인하세요.")
    static let untitled = String(localized: "document.untitled", defaultValue: "제목 없음")

    static let newDocument = String(localized: "action.newDocument", defaultValue: "새 문서")
    static let open = String(localized: "action.open", defaultValue: "열기…")
    static let openPrompt = String(localized: "action.openPrompt", defaultValue: "열기")
    static let openPanelMessage = String(
        localized: "action.openPanelMessage",
        defaultValue: "HWP 또는 HWPX 문서를 선택하세요."
    )
    static let openSample = String(localized: "action.openSample", defaultValue: "샘플 문서 열기")
    static let openDocument = String(localized: "action.openDocument", defaultValue: "문서 열기…")
    static let clearRecents = String(localized: "action.clearRecents", defaultValue: "최근 항목 지우기")
    static let dropToOpen = String(localized: "action.dropToOpen", defaultValue: "놓아서 열기")
    static let exportPDF = String(localized: "action.exportPDF", defaultValue: "PDF로 보내기…")
    static let printDocument = String(localized: "action.print", defaultValue: "인쇄…")
    static let find = String(localized: "action.find", defaultValue: "찾기…")
    static let findPlaceholder = String(localized: "find.query", defaultValue: "찾기")
    static let replacePlaceholder = String(localized: "find.replace", defaultValue: "바꾸기")
    static let findNext = String(localized: "find.next", defaultValue: "다음 찾기")
    static let replace = String(localized: "find.replaceAction", defaultValue: "모두 바꾸기")
    static let close = String(localized: "action.close", defaultValue: "닫기")
    static let ok = String(localized: "action.ok", defaultValue: "확인")
    static let retry = String(localized: "action.retry", defaultValue: "다시 시도")
    static let retrySave = String(localized: "action.retrySave", defaultValue: "다시 저장")
    static let retryOpen = String(localized: "action.retryOpen", defaultValue: "다시 열기")
    static let cancel = String(localized: "action.cancel", defaultValue: "취소")
    static let edited = String(localized: "chrome.edited", defaultValue: "편집됨")

    static let help = String(localized: "menu.help", defaultValue: "한결 도움말")
    static let about = String(localized: "menu.about", defaultValue: "한결 정보")
    static let fileMenuHint = String(localized: "menu.fileHint", defaultValue: "파일")
    static let editMenuHint = String(localized: "menu.editHint", defaultValue: "편집")

    static let errorTitle = String(localized: "sheet.error.title", defaultValue: "작업을 완료하지 못했습니다")
    static let saveFailureTitle = String(localized: "sheet.saveFailure.title", defaultValue: "문서를 저장하지 못했습니다")
    static let exportFailureTitle = String(localized: "sheet.exportFailure.title", defaultValue: "PDF로 보내지 못했습니다")
    static let reopenFailureTitle = String(localized: "sheet.reopenFailure.title", defaultValue: "최근 문서를 다시 열지 못했습니다")
    static let recents = String(localized: "empty.recents", defaultValue: "최근 문서")
    static let recentsEmpty = String(
        localized: "empty.recentsNone",
        defaultValue: "최근에 연 문서가 없습니다. 문서를 열면 여기에 나타납니다."
    )
    static let recentsOpenHint = String(localized: "empty.recentsOpenHint", defaultValue: "이 최근 문서를 엽니다.")
    static let week1Note = String(
        localized: "empty.week1",
        defaultValue: "파일을 열거나 이 창에 놓으면 문서가 열립니다."
    )
    static let saveFailureRetryHint = String(
        localized: "sheet.saveFailure.retryHint",
        defaultValue: "같은 위치에 다시 저장합니다."
    )
    static let reopenRetryHint = String(
        localized: "sheet.reopenFailure.retryHint",
        defaultValue: "최근 문서를 다시 엽니다."
    )
    static let findStubNote = String(
        localized: "find.stub",
        defaultValue: "이 문서에서는 찾기/바꾸기를 쓸 수 없습니다."
    )
    static let findLiveNote = String(
        localized: "find.live",
        defaultValue: "바꾸기는 이 문서의 열린 세션(표 셀 포함)에 적용됩니다. 허브-A 스모크: 1 → HGPOC99 후 HWPX 저장."
    )

    static func replacedCount(_ count: Int) -> String {
        if count == 0 {
            return String(localized: "find.replacedNone", defaultValue: "바꿀 곳이 없습니다.")
        }
        return String(
            format: String(localized: "find.replacedCount", defaultValue: "%d곳을 바꿨습니다."),
            locale: Locale(identifier: "ko_KR"),
            count
        )
    }

    static let helpBody = String(
        localized: "help.body",
        defaultValue: "한결은 macOS에서 HWP/HWPX 문서를 엽니다. 파일 → 열기… 를 누르거나 파일을 창이나 Dock 아이콘에 놓아 문서를 여세요."
    )
    static let printStub = String(localized: "print.stub", defaultValue: "인쇄는 아직 지원하지 않습니다.")
}
