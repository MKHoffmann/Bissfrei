import SwiftUI

// MARK: - Farben

enum Palette {
    static let bite = Color(red: 1.00, green: 0.47, blue: 0.35)
    static let biteDeep = Color(red: 0.92, green: 0.29, blue: 0.38)
    static let resist = Color(red: 0.15, green: 0.73, blue: 0.53)
    static let resistDeep = Color(red: 0.05, green: 0.55, blue: 0.58)
    static let practice = Color(red: 0.36, green: 0.42, blue: 0.98)
    static let practiceDeep = Color(red: 0.55, green: 0.33, blue: 0.95)
}

// MARK: - Art des Eintrags

enum EventKind: String, CaseIterable, Identifiable {
    case bitten
    case resisted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bitten: return "Gekaut"
        case .resisted: return "Widerstanden"
        }
    }

    var symbol: String {
        switch self {
        case .bitten: return "hand.raised.fingers.spread.fill"
        case .resisted: return "hand.thumbsup.fill"
        }
    }

    var color: Color {
        switch self {
        case .bitten: return Palette.bite
        case .resisted: return Palette.resist
        }
    }
}

// MARK: - Hand

enum Hand: String, CaseIterable, Identifiable {
    case left
    case right
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .left: return "Links"
        case .right: return "Rechts"
        case .both: return "Beide"
        }
    }
}

// MARK: - Finger

enum Finger: String, CaseIterable, Identifiable {
    case thumb
    case index
    case middle
    case ring
    case little

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thumb: return "Daumen"
        case .index: return "Zeigefinger"
        case .middle: return "Mittelfinger"
        case .ring: return "Ringfinger"
        case .little: return "Kleiner Finger"
        }
    }
}

// MARK: - Situation

enum Situation: String, CaseIterable, Identifiable {
    case work
    case screen
    case tv
    case reading
    case commute
    case conversation
    case waiting
    case bed
    case thinking
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: return "Arbeit/Lernen"
        case .screen: return "Handy/PC"
        case .tv: return "Fernsehen"
        case .reading: return "Lesen"
        case .commute: return "Unterwegs/Auto"
        case .conversation: return "Gespräch/Telefon"
        case .waiting: return "Warten"
        case .bed: return "Im Bett"
        case .thinking: return "Nachdenken/Grübeln"
        case .other: return "Sonstiges"
        }
    }

    var symbol: String {
        switch self {
        case .work: return "briefcase.fill"
        case .screen: return "iphone"
        case .tv: return "tv.fill"
        case .reading: return "book.fill"
        case .commute: return "car.fill"
        case .conversation: return "bubble.left.and.bubble.right.fill"
        case .waiting: return "hourglass"
        case .bed: return "bed.double.fill"
        case .thinking: return "brain.head.profile"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Gefühl

enum Emotion: String, CaseIterable, Identifiable {
    case stressed
    case nervous
    case bored
    case focused
    case tired
    case frustrated
    case sad
    case relaxed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stressed: return "Gestresst"
        case .nervous: return "Nervös/ängstlich"
        case .bored: return "Gelangweilt"
        case .focused: return "Konzentriert"
        case .tired: return "Müde"
        case .frustrated: return "Frustriert/wütend"
        case .sad: return "Traurig"
        case .relaxed: return "Entspannt"
        }
    }
}

// MARK: - Bewusstheit (in Gedanken vs. bewusst)

enum Awareness: String, CaseIterable, Identifiable {
    case automatic
    case focused

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "In Gedanken"
        case .focused: return "Bewusst"
        }
    }

    var detail: String {
        switch self {
        case .automatic: return "Unbeabsichtigt – erst bemerkt, als es schon passiert war."
        case .focused: return "Beabsichtigt – z. B. wegen einer unebenen Kante oder eines Niednagels."
        }
    }

    var symbol: String {
        switch self {
        case .automatic: return "moon.zzz.fill"
        case .focused: return "scope"
        }
    }
}

// MARK: - Übungsarten

enum PracticeType: String, CaseIterable, Identifiable {
    case competing
    case decoupling

    var id: String { rawValue }

    var title: String {
        switch self {
        case .competing: return "Gegenreaktion"
        case .decoupling: return "Decoupling"
        }
    }

    var symbol: String {
        switch self {
        case .competing: return "hand.raised.square.fill"
        case .decoupling: return "arrow.triangle.turn.up.right.diamond.fill"
        }
    }
}

// MARK: - Einstellungs-Schlüssel

enum Keys {
    static let hasOnboarded = "hasOnboarded"
    static let competingResponse = "competingResponse"
    static let competingDuration = "competingDuration"
    static let decouplingReps = "decouplingReps"
    static let decouplingInterval = "decouplingInterval"
    static let decouplingTarget = "decouplingTarget"
    static let practiceReminderOn = "practiceReminderOn"
    static let practiceReminderMinutes = "practiceReminderMinutes"
    static let checkInOn = "checkInOn"
    static let checkInStartHour = "checkInStartHour"
    static let checkInEndHour = "checkInEndHour"
    static let checkInInterval = "checkInInterval"
    static let riskWarningsOn = "riskWarningsOn"
    static let riskThreshold = "riskThreshold"
    static let riskMaxPerDay = "riskMaxPerDay"
    static let modeStartWarningOn = "modeStartWarningOn"
    static let modeFollowUpMinutes = "modeFollowUpMinutes"
    static let lastModeWarning = "lastModeWarning"
    static let didSeedSituations = "didSeedSituations"
}

enum Defaults {
    static let competingResponse = "Hände zu Fäusten ballen"
    static let competingDuration = 60
    static let decouplingReps = 10
    static let decouplingInterval = 3.0
    static let decouplingTarget = "Ohrläppchen"
    static let practiceReminderMinutes = 19 * 60
    static let checkInStartHour = 9
    static let checkInEndHour = 21
    static let checkInInterval = 3
    static let riskThreshold = 2.0
    static let riskMaxPerDay = 2
    static let modeFollowUpMinutes = 45

    /// Startwerte für die eigenen Situationen (frei änder- und löschbar).
    static let seedSituations: [(name: String, symbol: String)] = [
        ("Coding", "chevron.left.forwardslash.chevron.right"),
        ("Arbeit/Lernen", "briefcase.fill"),
        ("Handy", "iphone"),
        ("Fernsehen", "tv.fill"),
        ("Lesen", "book.fill"),
        ("Unterwegs", "car.fill"),
        ("Gespräch/Telefon", "bubble.left.and.bubble.right.fill"),
        ("Warten", "hourglass"),
        ("Im Bett", "bed.double.fill")
    ]

    /// Auswahl an Symbolen für eigene Situationen.
    static let situationSymbols = [
        "chevron.left.forwardslash.chevron.right", "laptopcomputer", "desktopcomputer", "briefcase.fill",
        "book.fill", "pencil", "iphone", "tv.fill",
        "gamecontroller.fill", "music.note", "headphones", "car.fill",
        "tram.fill", "airplane", "bubble.left.and.bubble.right.fill", "phone.fill",
        "person.2.fill", "hourglass", "bed.double.fill", "sofa.fill",
        "fork.knife", "cup.and.saucer.fill", "figure.walk", "brain.head.profile",
        "graduationcap.fill", "video.fill", "cart.fill", "tag.fill"
    ]

    static let competingResponses = [
        "Hände zu Fäusten ballen",
        "Hände flach auf die Oberschenkel drücken",
        "Finger ineinander verschränken",
        "Stift oder Stressball fest umgreifen",
        "Arme verschränken, Hände unter die Achseln",
        "Hände unter die Oberschenkel legen"
    ]

    static let decouplingTargets = [
        "Ohrläppchen",
        "Hinterkopf",
        "Nacken",
        "Schulter"
    ]
}
