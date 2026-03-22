import SwiftUI

struct SubjectInfo: Identifiable {
    let id: String
    let name: String
    let nameCn: String
    let code: String
    let icon: String
    let color: Color
    let gradientColors: [Color]
    let papers: [PaperInfo]
}

struct PaperInfo: Identifiable {
    let id: String
    let name: String
    let nameCn: String
    let subjectId: String
    let jsonFile: String
    let chapterCount: Int
    let kpCount: Int
    let questionCount: Int
    let available: Bool
}

enum SubjectData {
    static let subjects: [SubjectInfo] = [
        SubjectInfo(
            id: "math", name: "Mathematics", nameCn: "数学", code: "9709",
            icon: "📐", color: ZhiyaTheme.mathColor,
            gradientColors: [Color(hex: "4E6EF2"), Color(hex: "7B68EE")],
            papers: [
                PaperInfo(id: "math_p1", name: "P1 Pure Mathematics 1", nameCn: "纯数学 1", subjectId: "math", jsonFile: "math_p1.json", chapterCount: 8, kpCount: 37, questionCount: 296, available: true),
                PaperInfo(id: "math_p2", name: "P2 Pure Mathematics 2", nameCn: "纯数学 2", subjectId: "math", jsonFile: "math_p2.json", chapterCount: 6, kpCount: 6, questionCount: 30, available: true),
                PaperInfo(id: "math_p3", name: "P3 Pure Mathematics 3", nameCn: "纯数学 3", subjectId: "math", jsonFile: "math_p3.json", chapterCount: 9, kpCount: 9, questionCount: 45, available: true),
                PaperInfo(id: "math_m1", name: "M1 Mechanics", nameCn: "力学", subjectId: "math", jsonFile: "math_m1.json", chapterCount: 5, kpCount: 5, questionCount: 25, available: true),
                PaperInfo(id: "math_s1", name: "S1 Statistics 1", nameCn: "统计学 1", subjectId: "math", jsonFile: "math_s1.json", chapterCount: 5, kpCount: 5, questionCount: 25, available: true),
                PaperInfo(id: "math_s2", name: "S2 Statistics 2", nameCn: "统计学 2", subjectId: "math", jsonFile: "math_s2.json", chapterCount: 5, kpCount: 5, questionCount: 25, available: true),
            ]
        ),
        SubjectInfo(
            id: "bio", name: "Biology", nameCn: "生物", code: "9700",
            icon: "🧬", color: ZhiyaTheme.bioColor,
            gradientColors: [Color(hex: "4CAF50"), Color(hex: "66BB6A")],
            papers: [
                PaperInfo(id: "bio_as", name: "AS (Papers 1 & 2)", nameCn: "AS 级别", subjectId: "bio", jsonFile: "bio_as.json", chapterCount: 11, kpCount: 11, questionCount: 55, available: true),
                PaperInfo(id: "bio_a2", name: "A2 (Papers 4 & 5)", nameCn: "A2 级别", subjectId: "bio", jsonFile: "bio_a2.json", chapterCount: 8, kpCount: 8, questionCount: 40, available: true),
            ]
        ),
        SubjectInfo(
            id: "psych", name: "Psychology", nameCn: "心理学", code: "9990",
            icon: "🧠", color: ZhiyaTheme.psychColor,
            gradientColors: [Color(hex: "9C27B0"), Color(hex: "BA68C8")],
            papers: [
                PaperInfo(id: "psych_p1", name: "P1 AS Approaches", nameCn: "AS 心理学方法", subjectId: "psych", jsonFile: "psych_p1.json", chapterCount: 4, kpCount: 4, questionCount: 20, available: true),
                PaperInfo(id: "psych_p2", name: "P2 AS Research Methods", nameCn: "AS 研究方法", subjectId: "psych", jsonFile: "psych_p2.json", chapterCount: 3, kpCount: 3, questionCount: 15, available: true),
                PaperInfo(id: "psych_p3", name: "P3 A2 Specialist Options", nameCn: "A2 专业选项", subjectId: "psych", jsonFile: "psych_p3.json", chapterCount: 4, kpCount: 4, questionCount: 20, available: true),
                PaperInfo(id: "psych_p4", name: "P4 A2 Research Methods", nameCn: "A2 研究方法", subjectId: "psych", jsonFile: "psych_p4.json", chapterCount: 3, kpCount: 3, questionCount: 15, available: true),
            ]
        ),
    ]

    static func getSubject(_ id: String) -> SubjectInfo? {
        subjects.first { $0.id == id }
    }

    static func getPaper(_ id: String) -> PaperInfo? {
        subjects.flatMap(\.papers).first { $0.id == id }
    }

    static func getSubjectForPaper(_ paperId: String) -> SubjectInfo? {
        subjects.first { $0.papers.contains { $0.id == paperId } }
    }
}
