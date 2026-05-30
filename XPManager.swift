import Foundation
import Combine

// MARK: - Player Level

struct PlayerLevel {
    let level: Int
    let title: String
    let icon: String
    let xpRequired: Int
    let xpToNext: Int
    let color: String

    static func forLevel(_ level: Int) -> PlayerLevel {
        switch level {
        //  Lv  xpToNext   Toplam XP
        case 1:  return PlayerLevel(level: 1,  title: "Novice",       icon: "⚪️", xpRequired: 0,      xpToNext: 500,   color: "9CA3AF")  //    500
        case 2:  return PlayerLevel(level: 2,  title: "Apprentice",   icon: "🟢", xpRequired: 500,    xpToNext: 570,   color: "34D399")  //  1 070  +14%
        case 3:  return PlayerLevel(level: 3,  title: "Explorer",     icon: "🔵", xpRequired: 1070,   xpToNext: 650,   color: "60A5FA")  //  1 720  +14%
        case 4:  return PlayerLevel(level: 4,  title: "Thinker",      icon: "🟣", xpRequired: 1720,   xpToNext: 740,   color: "A78BFA")  //  2 460  +14%
        case 5:  return PlayerLevel(level: 5,  title: "Solver",       icon: "🟡", xpRequired: 2460,   xpToNext: 840,   color: "FBBF24")  //  3 300  +14%
        case 6:  return PlayerLevel(level: 6,  title: "Analyst",      icon: "🟠", xpRequired: 3300,   xpToNext: 960,   color: "F97316")  //  4 260  +14%
        case 7:  return PlayerLevel(level: 7,  title: "Strategist",   icon: "🔴", xpRequired: 4260,   xpToNext: 1100,  color: "F87171")  //  5 360  +15%
        case 8:  return PlayerLevel(level: 8,  title: "Tactician",    icon: "💎", xpRequired: 5360,   xpToNext: 1260,  color: "67E8F9")  //  6 620  +15%
        case 9:  return PlayerLevel(level: 9,  title: "Virtuoso",     icon: "🌟", xpRequired: 6620,   xpToNext: 1450,  color: "FDE68A")  //  8 070  +15%
        case 10: return PlayerLevel(level: 10, title: "Expert",       icon: "🏅", xpRequired: 8070,   xpToNext: 1670,  color: "FCD34D")  //  9 740  +15%
        case 11: return PlayerLevel(level: 11, title: "Prodigy",      icon: "🔮", xpRequired: 9740,   xpToNext: 1920,  color: "C084FC")  // 11 660  +15%
        case 12: return PlayerLevel(level: 12, title: "Mastermind",   icon: "🧠", xpRequired: 11660,  xpToNext: 2210,  color: "86EFAC")  // 13 870  +15%
        case 13: return PlayerLevel(level: 13, title: "Champion",     icon: "⚡️", xpRequired: 13870,  xpToNext: 2540,  color: "7C6EF5")  // 16 410  +15%
        case 14: return PlayerLevel(level: 14, title: "Sage",         icon: "🌙", xpRequired: 16410,  xpToNext: 2920,  color: "93C5FD")  // 19 330  +15%
        case 15: return PlayerLevel(level: 15, title: "Oracle",       icon: "🌊", xpRequired: 19330,  xpToNext: 3360,  color: "5EEAD4")  // 22 690  +15%
        case 16: return PlayerLevel(level: 16, title: "Illusionist",  icon: "🎭", xpRequired: 22690,  xpToNext: 3870,  color: "F9A8D4")  // 26 560  +15%
        case 17: return PlayerLevel(level: 17, title: "Warlord",      icon: "🛡️", xpRequired: 26560,  xpToNext: 4450,  color: "FCA5A5")  // 31 010  +15%
        case 18: return PlayerLevel(level: 18, title: "Architect",    icon: "🔷", xpRequired: 31010,  xpToNext: 5120,  color: "A5B4FC")  // 36 130  +15%
        case 19: return PlayerLevel(level: 19, title: "Master",       icon: "👑", xpRequired: 36130,  xpToNext: 5890,  color: "FCD34D")  // 42 020  +15%
        case 20: return PlayerLevel(level: 20, title: "Grandmaster",  icon: "🏆", xpRequired: 42020,  xpToNext: 99999, color: "F472B6")
        default:
            if level > 20 {
                return PlayerLevel(level: level, title: "Legend", icon: "⚡️", xpRequired: 54800 + (level - 20) * 10000, xpToNext: 10000, color: "7C6EF5")
            }
            return PlayerLevel(level: 1, title: "Novice", icon: "⚪️", xpRequired: 0, xpToNext: 200, color: "9CA3AF")
        }
    }
}

// MARK: - Badge / Achievement

struct Badge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: String
    var isUnlocked: Bool
    var unlockedDate: Date?

    static let all: [Badge] = [
        Badge(id: "first_win",     title: "First Steps",     description: "Complete your first puzzle",             icon: "star.fill",                color: "FBBF24", isUnlocked: false),
        Badge(id: "no_hints",      title: "Pure Mind",       description: "Finish without using any hints",         icon: "lightbulb.slash.fill",     color: "60A5FA", isUnlocked: false),
        Badge(id: "no_mistakes",   title: "Flawless",        description: "Finish without any mistakes",            icon: "checkmark.seal.fill",      color: "34D399", isUnlocked: false),
        Badge(id: "speed_3min",    title: "Speed Demon",     description: "Finish a puzzle in under 3 minutes",     icon: "bolt.fill",                color: "F97316", isUnlocked: false),
        Badge(id: "speed_5min",    title: "Quick Thinker",   description: "Finish a puzzle in under 5 minutes",     icon: "hare.fill",                color: "A78BFA", isUnlocked: false),
        Badge(id: "master_win",    title: "Master Class",    description: "Complete a Master difficulty puzzle",     icon: "crown.fill",               color: "F472B6", isUnlocked: false),
        Badge(id: "streak_3",      title: "On a Roll",       description: "Play 3 days in a row",                   icon: "flame.fill",               color: "FB923C", isUnlocked: false),
        Badge(id: "streak_7",      title: "Week Warrior",    description: "Play 7 days in a row",                   icon: "calendar.badge.checkmark", color: "F87171", isUnlocked: false),
        Badge(id: "streak_30",     title: "Dedicated",       description: "Play 30 days in a row",                  icon: "medal.fill",               color: "FCD34D", isUnlocked: false),
        Badge(id: "games_10",      title: "Getting Serious", description: "Complete 10 puzzles",                    icon: "10.circle.fill",           color: "60A5FA", isUnlocked: false),
        Badge(id: "games_50",      title: "Veteran",         description: "Complete 50 puzzles",                    icon: "50.circle.fill",           color: "A78BFA", isUnlocked: false),
        Badge(id: "games_100",     title: "Centurion",       description: "Complete 100 puzzles",                   icon: "100.circle.fill",          color: "F472B6", isUnlocked: false),
        Badge(id: "daily_first",   title: "Daily Devotee",   description: "Complete your first Daily Challenge",    icon: "calendar.circle.fill",     color: "34D399", isUnlocked: false),
        Badge(id: "daily_7",       title: "Daily Hero",      description: "Complete 7 Daily Challenges",            icon: "calendar.badge.plus",      color: "FBBF24", isUnlocked: false),
        Badge(id: "perfect_score", title: "Perfectionist",   description: "Score over 8000 points in one game",     icon: "rosette",                  color: "7C6EF5", isUnlocked: false),
        Badge(id: "level_5",       title: "Rising Star",     description: "Reach Level 5",                          icon: "5.circle.fill",            color: "FB923C", isUnlocked: false),
        Badge(id: "level_10",      title: "Expert",          description: "Reach Level 10",                         icon: "10.circle.fill",           color: "FCD34D", isUnlocked: false),
        Badge(id: "level_15",      title: "Veteran",         description: "Reach Level 15",                         icon: "15.circle.fill",           color: "C084FC", isUnlocked: false),
        Badge(id: "level_20",      title: "Grandmaster",     description: "Reach Level 20",                         icon: "trophy.fill",              color: "F472B6", isUnlocked: false),
    ]
}

// MARK: - XP Event

enum XPEvent {
    case completedEasy
    case completedMedium
    case completedHard
    case completedExpert
    case completedMaster
    case noHints
    case noMistakes
    case under3Minutes
    case under5Minutes
    case dailyChallenge
    case dailyStreak(Int)

    var xpValue: Int {
        switch self {
        case .completedEasy:      return 50
        case .completedMedium:    return 100
        case .completedHard:      return 175
        case .completedExpert:    return 275
        case .completedMaster:    return 450
        case .noHints:            return 75
        case .noMistakes:         return 50
        case .under3Minutes:      return 100
        case .under5Minutes:      return 50
        case .dailyChallenge:     return 150
        case .dailyStreak(let d): return min(d * 25, 200)
        }
    }

    var label: String {
        switch self {
        case .completedEasy:      return "Easy Puzzle"
        case .completedMedium:    return "Medium Puzzle"
        case .completedHard:      return "Hard Puzzle"
        case .completedExpert:    return "Expert Puzzle"
        case .completedMaster:    return "Master Puzzle"
        case .noHints:            return "No Hints Bonus"
        case .noMistakes:         return "Flawless Bonus"
        case .under3Minutes:      return "Speed Bonus (<3min)"
        case .under5Minutes:      return "Speed Bonus (<5min)"
        case .dailyChallenge:     return "Daily Challenge"
        case .dailyStreak(let d): return "Streak Bonus (×\(d))"
        }
    }
}

// MARK: - XP Manager

final class XPManager: ObservableObject {

    @Published var totalXP: Int = 0 {
        didSet { UserDefaults.standard.set(totalXP, forKey: "playerTotalXP") }
    }
    @Published var currentLevel: Int = 1
    @Published var badges: [Badge] = []
    @Published var recentXPEvents: [XPEvent] = []
    @Published var pendingLevelUp: Int? = nil
    @Published var pendingBadges: [Badge] = []

    @Published var currentStreak: Int = 0 {
        didSet { UserDefaults.standard.set(currentStreak, forKey: "playerStreak") }
    }
    @Published var lastPlayedDate: Date? {
        didSet {
            if let d = lastPlayedDate {
                UserDefaults.standard.set(d, forKey: "playerLastPlayed")
            }
        }
    }

    init() {
        self.totalXP       = UserDefaults.standard.integer(forKey: "playerTotalXP")
        self.currentStreak = UserDefaults.standard.integer(forKey: "playerStreak")
        self.lastPlayedDate = UserDefaults.standard.object(forKey: "playerLastPlayed") as? Date
        self.badges        = XPManager.loadBadges()
        self.currentLevel  = XPManager.calculateLevel(for: self.totalXP)
    }

    // MARK: - Level Info

    var levelInfo: PlayerLevel { PlayerLevel.forLevel(currentLevel) }

    var xpInCurrentLevel: Int {
        let info = levelInfo
        return totalXP - info.xpRequired
    }

    var xpProgressFraction: Double {
        let info = levelInfo
        guard info.xpToNext > 0 else { return 1.0 }
        return min(1.0, Double(xpInCurrentLevel) / Double(info.xpToNext))
    }

    // MARK: - Award XP

    @discardableResult
    func awardXP(for events: [XPEvent]) -> Int {
        let gained = events.reduce(0) { $0 + $1.xpValue }
        let oldLevel = currentLevel
        totalXP += gained
        currentLevel = XPManager.calculateLevel(for: totalXP)
        recentXPEvents = events

        if currentLevel > oldLevel {
            pendingLevelUp = currentLevel
        }

        updateStreak()
        return gained
    }

    func buildXPEvents(for stats: GameStats, isDaily: Bool) -> [XPEvent] {
        var events: [XPEvent] = []

        switch stats.difficulty {
        case .easy:   events.append(.completedEasy)
        case .medium: events.append(.completedMedium)
        case .hard:   events.append(.completedHard)
        case .expert: events.append(.completedExpert)
        case .master: events.append(.completedMaster)
        }

        if stats.hintsUsed == 0          { events.append(.noHints) }
        if stats.mistakesMade == 0        { events.append(.noMistakes) }
        if stats.elapsedSeconds < 180     { events.append(.under3Minutes) }
        else if stats.elapsedSeconds < 300 { events.append(.under5Minutes) }
        if isDaily { events.append(.dailyChallenge) }

        let streak = currentStreak + 1
        if streak > 1 { events.append(.dailyStreak(streak)) }

        return events
    }

    // MARK: - Streak

    private func updateStreak() {
        let calendar = Calendar.current
        let today = Date()

        if let last = lastPlayedDate {
            if calendar.isDateInToday(last) {
                // Bugün zaten oynandı, değişiklik yok
            } else if calendar.isDateInYesterday(last) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastPlayedDate = today
    }

    // MARK: - Badges

    func checkBadges(stats: GameStats, isDaily: Bool, totalCompleted: Int) {
        var newBadges: [Badge] = []

        func unlock(_ id: String) {
            if let idx = badges.firstIndex(where: { $0.id == id && !$0.isUnlocked }) {
                badges[idx].isUnlocked = true
                badges[idx].unlockedDate = Date()
                newBadges.append(badges[idx])
            }
        }

        if totalCompleted >= 1   { unlock("first_win") }
        if totalCompleted >= 10  { unlock("games_10") }
        if totalCompleted >= 50  { unlock("games_50") }
        if totalCompleted >= 100 { unlock("games_100") }

        if stats.hintsUsed == 0        { unlock("no_hints") }
        if stats.mistakesMade == 0     { unlock("no_mistakes") }
        if stats.elapsedSeconds < 180  { unlock("speed_3min") }
        else if stats.elapsedSeconds < 300 { unlock("speed_5min") }
        if stats.difficulty == .master { unlock("master_win") }
        if stats.score > 8000          { unlock("perfect_score") }

        if isDaily {
            let dailyCount = UserDefaults.standard.integer(forKey: "dailyChallengesCompleted")
            if dailyCount >= 1 { unlock("daily_first") }
            if dailyCount >= 7 { unlock("daily_7") }
        }

        if currentStreak >= 3  { unlock("streak_3") }
        if currentStreak >= 7  { unlock("streak_7") }
        if currentStreak >= 30 { unlock("streak_30") }

        if currentLevel >= 5  { unlock("level_5") }
        if currentLevel >= 10 { unlock("level_10") }
        if currentLevel >= 15 { unlock("level_15") }
        if currentLevel >= 20 { unlock("level_20") }

        saveBadges()
        if !newBadges.isEmpty { pendingBadges = newBadges }
    }

    // MARK: - Persistence

    private func saveBadges() {
        if let data = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(data, forKey: "playerBadges")
        }
    }

    private static func loadBadges() -> [Badge] {
        guard let data = UserDefaults.standard.data(forKey: "playerBadges"),
              let saved = try? JSONDecoder().decode([Badge].self, from: data) else {
            return Badge.all
        }
        var result = saved
        for template in Badge.all {
            if !result.contains(where: { $0.id == template.id }) {
                result.append(template)
            }
        }
        return result
    }

    private static func calculateLevel(for xp: Int) -> Int {
        var level = 1
        while true {
            let nextInfo = PlayerLevel.forLevel(level + 1)
            if xp < nextInfo.xpRequired { break }
            level += 1
            if level >= 100 { break }
        }
        return level
    }

    var unlockedBadges: [Badge] { badges.filter { $0.isUnlocked } }
    var lockedBadges: [Badge]   { badges.filter { !$0.isUnlocked } }
}

