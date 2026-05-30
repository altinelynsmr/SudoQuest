import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var engine = SudokuEngine()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var xpManager: XPManager
    @EnvironmentObject var dailyManager: DailyChallengeManager
    @EnvironmentObject var livesManager: LivesManager
    @StateObject private var settings = SettingsManager()

    @State private var currentScreen: Screen = .home
    @State private var isDailyGame = false
    @State private var showTutorial: Bool = !UserDefaults.standard.bool(forKey: "tutorialCompleted")

    @State private var showLevelUp: Int?       = nil
    @State private var pendingBadges: [Badge]  = []
    @State private var showXPToast             = false
    @State private var xpEvents: [XPEvent]     = []

    enum Screen {
        case home, game, stats, themes, daily, badges, profile, settings
    }

    var body: some View {
        ZStack {
            themeManager.colors.background.ignoresSafeArea()

            currentScreenView
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentScreen)

            if showXPToast {
                VStack {
                    Spacer()
                    XPGainToast(events: xpEvents) { showXPToast = false }
                        .environmentObject(themeManager)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if let badge = pendingBadges.first {
                VStack {
                    BadgeUnlockToast(badge: badge) { pendingBadges.removeFirst() }
                        .environmentObject(themeManager)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
            }

            if let level = showLevelUp {
                LevelUpOverlay(newLevel: level) { showLevelUp = nil }
                    .environmentObject(themeManager)
                    .transition(.opacity).zIndex(10)
            }

            if showTutorial {
                TutorialView(onComplete: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showTutorial = false }
                }, settings: settings)
                .environmentObject(themeManager)
                .transition(.opacity).zIndex(20)
            }

            if livesManager.showNoLivesPaywall {
                NoLivesPaywallOverlay(
                    livesManager: livesManager,
                    onHome: {
                        withAnimation { livesManager.showNoLivesPaywall = false }
                    }
                )
                .environmentObject(themeManager)
                .environmentObject(settings)
                .transition(.opacity)
                .zIndex(30)
            }
        }
        .onChange(of: engine.gameState) {
            if engine.gameState == .completed { handleGameCompleted() }
        }
        .onChange(of: settings.soundEnabled) { SoundManager.shared.setEnabled(settings.soundEnabled) }
        .onChange(of: settings.hapticEnabled) { HapticManager.shared.setEnabled(settings.hapticEnabled) }
    }

    @ViewBuilder
    private var currentScreenView: some View {
        switch currentScreen {
        case .home:
            HomeView(
                xpManager: xpManager,
                dailyManager: dailyManager,
                settings: settings,
                livesManager: livesManager,
                onStartGame: { difficulty, isTimeAttack in
                    guard livesManager.canStartGame() else { return }
                    isDailyGame = false
                    engine.newGame(difficulty: difficulty, timeAttack: isTimeAttack)
                    engine.onLifeLost = { livesManager.loseLife() }
                    SoundManager.shared.playNumberInput()
                    navigate(to: .game)
                },
                onContinue: {
                    guard livesManager.canStartGame() else { return }
                    if engine.loadGame() {
                        engine.onLifeLost = { livesManager.loseLife() }
                        navigate(to: .game)
                    }
                },
                onDaily: { navigate(to: .daily) },
                onStats: { navigate(to: .stats) },
                onThemes: { navigate(to: .themes) },
                onBadges: { navigate(to: .badges) },
                onProfile: { navigate(to: .profile) },
                hasSavedGame: UserDefaults.standard.data(forKey: "savedCells") != nil
            )
            .environmentObject(engine)

        case .game:
            GameView(
                onHome: { engine.saveGame(); navigate(to: .home) },
                onNewGame: { difficulty in
                    isDailyGame = false
                    engine.newGame(difficulty: difficulty)
                }
            )
            .environmentObject(engine)
            .environmentObject(settings)
            .environmentObject(livesManager)

        case .stats:
            StatsView(engine: engine, settings: settings, onBack: { navigate(to: .home) })

        case .themes:
            ThemeSelectionView(onBack: { navigate(to: .home) }, settings: settings, xpManager: xpManager)

        case .daily:
            DailyChallengeView(
                onStartDaily: {
                    isDailyGame = true
                    let (puzzle, solution) = dailyManager.generateDailyPuzzle()
                    engine.newGameWithPuzzle(puzzle: puzzle, solution: solution)
                    engine.onLifeLost = nil  // Daily'de can düşmez
                    SoundManager.shared.playNumberInput()
                    navigate(to: .game)
                },
                onBack: { navigate(to: .home) },
                dailyManager: dailyManager,
                xpManager: xpManager,
                settings: settings
            )
            .environmentObject(themeManager)

        case .badges:
            BadgeCollectionView(xpManager: xpManager, onBack: { navigate(to: .home) })

        case .profile:
            ProfileView(
                xpManager: xpManager,
                settings: settings,
                engine: engine,
                onBack: { navigate(to: .home) },
                onSettings: { navigate(to: .settings) }
            )

        case .settings:
            SettingsView(settings: settings, onBack: { navigate(to: .profile) })
        }
    }

    private func navigate(to screen: Screen) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentScreen = screen }
    }

    private func handleGameCompleted() {
        let stats = engine.stats
        let events = xpManager.buildXPEvents(for: stats, isDaily: isDailyGame)
        let _ = xpManager.awardXP(for: events)
        xpEvents = events
        withAnimation { showXPToast = true }

        let results = engine.loadGameResults()
        xpManager.checkBadges(stats: stats, isDaily: isDailyGame, totalCompleted: results.count)

        if isDailyGame {
            dailyManager.markCompleted(time: stats.elapsedSeconds, score: stats.score, hints: stats.hintsUsed, mistakes: stats.mistakesMade)
            SoundManager.shared.playDailyComplete()
        } else {
            SoundManager.shared.playCompletion()
        }

        HapticManager.shared.completion()

        if let level = xpManager.pendingLevelUp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showLevelUp = level }
                xpManager.pendingLevelUp = nil
                SoundManager.shared.playLevelUp()
            }
        }

        if !xpManager.pendingBadges.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { pendingBadges = xpManager.pendingBadges }
                xpManager.pendingBadges = []
                SoundManager.shared.playBadgeUnlock()
            }
        }
    }
}


