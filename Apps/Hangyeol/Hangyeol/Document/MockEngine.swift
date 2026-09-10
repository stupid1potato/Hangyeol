import Foundation

/// 실제 HWP/HWPX 파서 대신 한국어 본문과 표 예시를 돌려 주는 1주차 엔진.
struct MockEngine: HangyeolEngine {
    static let failureMarker = Data("HANGYEOL_FAIL".utf8)

    func open(data: Data, type: DocumentFileType) throws -> DocumentModel {
        if data.isEmpty {
            return .empty
        }
        if data.starts(with: Self.failureMarker) {
            throw HangyeolError.engineFailed(String(
                localized: "error.engine.mockFail",
                defaultValue: "모의 엔진이 문서를 열 수 없습니다."
            ))
        }
        if let decoded = try? JSONDecoder().decode(DocumentModel.self, from: data),
           !decoded.blocks.isEmpty {
            return decoded
        }
        return Self.sampleDocument(type: type)
    }

    func save(_ model: DocumentModel, as type: DocumentFileType) throws -> Data {
        var snapshot = model
        snapshot.metadata.sourceType = type
        return try JSONEncoder().encode(snapshot)
    }

    static func sampleDocument(type: DocumentFileType = .hwpx) -> DocumentModel {
        DocumentModel(
            metadata: DocumentMetadata(
                title: String(localized: "sample.title", defaultValue: "한결 샘플 문서"),
                sourceType: type
            ),
            blocks: [
                .paragraph(ParagraphBlock(text: "한결에 오신 것을 환영합니다.")),
                .paragraph(ParagraphBlock(text: "이 화면은 실제 HWP 파서 없이 표시되는 1주차 미리보기입니다.")),
                .paragraph(ParagraphBlock(runs: [
                    TextRun(text: "아래에서 ", isBold: false),
                    TextRun(text: "간단한 표", isBold: true),
                    TextRun(text: "를 확인할 수 있습니다.", isBold: false)
                ])),
                .table(TableBlock(
                    headers: ["항목", "내용"],
                    body: [
                        ["형식", type == .hwp ? "HWP" : "HWPX"],
                        ["엔진", "MockEngine (1주차)"],
                        ["언어", "한국어"]
                    ]
                )),
                .paragraph(ParagraphBlock(text: "파일 메뉴에서 문서를 열거나 샘플을 다시 불러올 수 있습니다."))
            ]
        )
    }

    static func loadBundledSample() throws -> DocumentModel {
        if let url = Bundle.main.url(
            forResource: "welcome",
            withExtension: "hwpx",
            subdirectory: "Sample"
        ) {
            let data = try Data(contentsOf: url)
            return try MockEngine().open(data: data, type: .hwpx)
        }
        return sampleDocument()
    }
}
