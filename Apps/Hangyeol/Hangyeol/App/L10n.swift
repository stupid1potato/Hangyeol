import Foundation

enum L10n {
    static let appName = String(localized: "app.name", defaultValue: "한결")
    static let appTagline = String(localized: "app.tagline", defaultValue: "한글 문서를 열고 본문과 표를 확인하세요.")
    static let untitled = String(localized: "document.untitled", defaultValue: "제목 없음")

    static let openSample = String(localized: "action.openSample", defaultValue: "샘플 문서 열기")
    static let openDocument = String(localized: "action.openDocument", defaultValue: "문서 열기…")
    static let exportPDF = String(localized: "action.exportPDF", defaultValue: "PDF로 보내기…")
    static let printDocument = String(localized: "action.print", defaultValue: "인쇄…")
    static let find = String(localized: "action.find", defaultValue: "찾기…")
    static let findPlaceholder = String(localized: "find.query", defaultValue: "찾기")
    static let replacePlaceholder = String(localized: "find.replace", defaultValue: "바꾸기")
    static let findNext = String(localized: "find.next", defaultValue: "다음")
    static let replace = String(localized: "find.replaceAction", defaultValue: "바꾸기")
    static let close = String(localized: "action.close", defaultValue: "닫기")
    static let ok = String(localized: "action.ok", defaultValue: "확인")
    static let retry = String(localized: "action.retry", defaultValue: "다시 시도")
    static let cancel = String(localized: "action.cancel", defaultValue: "취소")

    static let help = String(localized: "menu.help", defaultValue: "한결 도움말")
    static let about = String(localized: "menu.about", defaultValue: "한결 정보")
    static let fileMenuHint = String(localized: "menu.fileHint", defaultValue: "파일")
    static let editMenuHint = String(localized: "menu.editHint", defaultValue: "편집")

    static let errorTitle = String(localized: "sheet.error.title", defaultValue: "오류")
    static let saveFailureTitle = String(localized: "sheet.saveFailure.title", defaultValue: "저장에 실패했습니다")
    static let recents = String(localized: "empty.recents", defaultValue: "최근 문서")
    static let recentsEmpty = String(localized: "empty.recentsNone", defaultValue: "최근 문서가 없습니다.")
    static let week1Note = String(localized: "empty.week1", defaultValue: "1주차 미리보기 · 실제 HWP 엔진은 아직 연결되지 않았습니다.")
    static let findStubNote = String(localized: "find.stub", defaultValue: "찾기/바꾸기는 아직 동작하지 않습니다.")
    static let helpBody = String(
        localized: "help.body",
        defaultValue: "한결은 macOS에서 HWP/HWPX 문서를 열기 위한 앱입니다. 1주차 스켈레톤에서는 모의 엔진이 한국어 본문과 표 예시를 보여 줍니다."
    )
    static let printStub = String(localized: "print.stub", defaultValue: "인쇄는 아직 지원하지 않습니다.")
}
