import Foundation

enum HangyeolError: LocalizedError, Identifiable, Equatable {
    case emptyFile
    case sampleNotFound
    case engineFailed(String)
    case saveFailed(String)
    case bookmarkFailed(String)
    case unsupportedType(String)
    case notYetImplemented(String)
    /// HWP write (`hg_save(..., HG_FILE_HWP)` freeze `SAVE_REJECTED`).
    case saveRejected

    var id: String {
        switch self {
        case .emptyFile:
            return "emptyFile"
        case .sampleNotFound:
            return "sampleNotFound"
        case .engineFailed(let message):
            return "engineFailed:\(message)"
        case .saveFailed(let message):
            return "saveFailed:\(message)"
        case .bookmarkFailed(let message):
            return "bookmarkFailed:\(message)"
        case .unsupportedType(let name):
            return "unsupportedType:\(name)"
        case .notYetImplemented(let feature):
            return "notYetImplemented:\(feature)"
        case .saveRejected:
            return "saveRejected"
        }
    }

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return String(localized: "error.emptyFile", defaultValue: "파일 내용이 비어 있습니다.")
        case .sampleNotFound:
            return String(localized: "error.sampleNotFound", defaultValue: "샘플 문서를 찾을 수 없습니다.")
        case .engineFailed(let message):
            return String(
                format: String(
                    localized: "error.engineFailed",
                    defaultValue: "문서를 열지 못했습니다. %@"
                ),
                message
            )
        case .saveFailed(let message):
            return String(
                format: String(
                    localized: "error.saveFailed",
                    defaultValue: "저장하지 못했습니다. %@"
                ),
                message
            )
        case .bookmarkFailed(let message):
            return String(
                format: String(
                    localized: "error.bookmarkFailed",
                    defaultValue: "파일 접근 권한을 유지하지 못했습니다. %@"
                ),
                message
            )
        case .unsupportedType(let name):
            return String(
                format: String(
                    localized: "error.unsupportedType",
                    defaultValue: "‘%@’은(는) 열 수 없는 형식입니다."
                ),
                name
            )
        case .notYetImplemented(let feature):
            return String(
                format: String(
                    localized: "error.notYetImplemented",
                    defaultValue: "%@은(는) 아직 지원하지 않습니다."
                ),
                feature
            )
        case .saveRejected:
            return String(
                localized: "error.saveRejected",
                defaultValue: "HWP로는 저장할 수 없습니다. (SAVE_REJECTED)"
            )
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyFile:
            return String(localized: "error.emptyFile.recovery", defaultValue: "다른 파일을 선택해 보세요.")
        case .sampleNotFound:
            return String(localized: "error.sampleNotFound.recovery", defaultValue: "앱을 다시 설치하거나 새 문서로 시작하세요.")
        case .engineFailed:
            return String(localized: "error.engineFailed.recovery", defaultValue: "파일이 손상되지 않았는지 확인하세요.")
        case .saveFailed:
            return String(localized: "error.saveFailed.recovery", defaultValue: "저장 위치를 바꾸거나 권한을 확인하세요.")
        case .bookmarkFailed:
            return String(localized: "error.bookmarkFailed.recovery", defaultValue: "파일을 다시 열어 주세요.")
        case .unsupportedType:
            return String(localized: "error.unsupportedType.recovery", defaultValue: "HWP 또는 HWPX 파일을 선택해 주세요.")
        case .notYetImplemented:
            return String(localized: "error.notYetImplemented.recovery", defaultValue: "이후 주 차에 제공될 예정입니다.")
        case .saveRejected:
            return String(
                localized: "error.saveRejected.recovery",
                defaultValue: "HWPX로 저장하세요."
            )
        }
    }

    /// Map engine/kit failures from open. `saveRejected` is unusual on open.
    static func mapOpenFailure(_ error: Error) -> HangyeolError {
        if let hangyeol = error as? HangyeolError {
            return hangyeol
        }
        return KitRealEngine.mapError(error)
    }

    /// Map engine/kit failures from save. `engineFailed` becomes `saveFailed`.
    static func mapSaveFailure(_ error: Error) -> HangyeolError {
        let hangyeol: HangyeolError
        if let typed = error as? HangyeolError {
            hangyeol = typed
        } else {
            hangyeol = KitRealEngine.mapError(error)
        }
        switch hangyeol {
        case .saveRejected, .saveFailed, .notYetImplemented:
            return hangyeol
        case .engineFailed(let message):
            return .saveFailed(message)
        default:
            return .saveFailed(hangyeol.localizedDescription)
        }
    }
}
