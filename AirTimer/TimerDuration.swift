enum TimerDuration: CaseIterable, Identifiable {
    case fiveSeconds
    case fiveMinutes
    case tenMinutes
    case fifteenMinutes
    case endOfChapter
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .fiveSeconds: return "5 sec"
        case .fiveMinutes: return "5 min"
        case .tenMinutes: return "10 min"
        case .fifteenMinutes: return "15 min"
        case .endOfChapter: return "End of chapter"
        }
    }

    var shortLabel: String {
        switch self {
        case .fiveSeconds: return "5 sec"
        case .fiveMinutes: return "5 min"
        case .tenMinutes: return "10 min"
        case .fifteenMinutes: return "15 min"
        case .endOfChapter: return "End"
        }
    }
    
    var backtrackLabel: String {
        switch self {
        case .fiveSeconds: return label
        case .fiveMinutes: return label
        case .tenMinutes: return label
        case .fifteenMinutes: return label
        case .endOfChapter: return "Start"
        }
    }
}
