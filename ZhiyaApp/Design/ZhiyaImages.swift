import SwiftUI

/// Typed access to all Zhiya image assets bundled with the app.
enum ZhiyaImages {

    // MARK: - Character

    static var avatar: Image { bundleImage("zhiya_avatar") }
    static var expressions: Image { bundleImage("zhiya_expressions") }
    static var growthStages: Image { bundleImage("zhiya_growth_stages") }
    static var signature: Image { bundleImage("zhiya_signature") }

    // MARK: - Seed Moments

    static var seedMoment1: Image { bundleImage("seed_moment_1") }
    static var seedMoment2: Image { bundleImage("seed_moment_2") }
    static var seedMoment3: Image { bundleImage("seed_moment_3") }

    // MARK: - Backgrounds — Seasonal

    static var bgSpring: Image { bundleImage("bg_spring") }
    static var bgSummer: Image { bundleImage("bg_summer") }
    static var bgAutumn: Image { bundleImage("bg_autumn") }
    static var bgWinter: Image { bundleImage("bg_winter") }
    static var bgCelebration: Image { bundleImage("bg_celebration") }

    // MARK: - Subjects

    static var subjectMath: Image { bundleImage("subject_math") }
    static var subjectBiology: Image { bundleImage("subject_biology") }
    static var subjectPsychology: Image { bundleImage("subject_psychology") }

    // MARK: - Empty States

    static var emptyMemories: Image { bundleImage("empty_memories") }
    static var emptyNoData: Image { bundleImage("empty_no_data") }
    static var emptyNoLetters: Image { bundleImage("empty_no_letters") }
    static var emptyNoWrong: Image { bundleImage("empty_no_wrong") }

    // MARK: - Special Events

    static var birthday: Image { bundleImage("zhiya_birthday") }
    static var chineseNewYear: Image { bundleImage("zhiya_cny") }
    static var annualReview: Image { bundleImage("annual_review") }

    // MARK: - Stationery

    static var letterPaperBg: Image { bundleImage("letter_paper_bg") }

    // MARK: - UIImage Access

    enum ImageKey: String, CaseIterable {
        case avatar = "zhiya_avatar"
        case expressions = "zhiya_expressions"
        case growthStages = "zhiya_growth_stages"
        case signature = "zhiya_signature"
        case seedMoment1 = "seed_moment_1"
        case seedMoment2 = "seed_moment_2"
        case seedMoment3 = "seed_moment_3"
        case bgSpring = "bg_spring"
        case bgSummer = "bg_summer"
        case bgAutumn = "bg_autumn"
        case bgWinter = "bg_winter"
        case bgCelebration = "bg_celebration"
        case subjectMath = "subject_math"
        case subjectBiology = "subject_biology"
        case subjectPsychology = "subject_psychology"
        case emptyMemories = "empty_memories"
        case emptyNoData = "empty_no_data"
        case emptyNoLetters = "empty_no_letters"
        case emptyNoWrong = "empty_no_wrong"
        case birthday = "zhiya_birthday"
        case chineseNewYear = "zhiya_cny"
        case annualReview = "annual_review"
        case letterPaperBg = "letter_paper_bg"
    }

    static func uiImage(_ key: ImageKey) -> UIImage? {
        loadUIImage(key.rawValue)
    }

    // MARK: - Private

    private static func bundleImage(_ name: String) -> Image {
        if let uiImage = loadUIImage(name) {
            return Image(uiImage: uiImage)
        }
        return Image(name)
    }

    private static func loadUIImage(_ name: String) -> UIImage? {
        // Try asset catalog first
        if let img = UIImage(named: name) {
            return img
        }
        // Try bundle resource as JPEG
        if let path = Bundle.main.path(forResource: name, ofType: "jpeg") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}
