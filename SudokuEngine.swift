import Foundation
import Combine

enum Difficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"
    case master = "Master"
    
    var clueCount: Int {
        switch self {
        case .easy: return 46
        case .medium: return 36
        case .hard: return 28
        case .expert: return 24
        case .master: return 20
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        case .expert: return "4.circle.fill"
        case .master: return "5.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "34D399"
        case .medium: return "60A5FA"
        case .hard: return "FBBF24"
        case .expert: return "F97316"
        case .master: return "F87171"
        }
    }

    var timeAttackSeconds: Int {
        switch self {
        case .easy:   return 600
        case .medium: return 480
        case .hard:   return 360
        case .expert: return 300
        case .master: return 240
        }
    }
}

struct SudokuCell: Identifiable, Codable, Equatable {
    let id: Int
    var value: Int
    var isGiven: Bool
    var isError: Bool
    var notes: Set<Int>
    var isAnimating: Bool = false
    
    var row: Int { id / 9 }
    var col: Int { id % 9 }
    var box: Int { (row / 3) * 3 + (col / 3) }
    
    init(id: Int, value: Int = 0, isGiven: Bool = false) {
        self.id = id
        self.value = value
        self.isGiven = isGiven
        self.isError = false
        self.notes = []
    }
}

struct GameStats: Codable {
    var hintsUsed: Int = 0
    var mistakesMade: Int = 0
    var elapsedSeconds: Int = 0
    var difficulty: Difficulty
    var startDate: Date = Date()
    var completedDate: Date?
    var score: Int = 0
    var isTimeAttack: Bool = false
}

class SudokuEngine: ObservableObject {
    @Published var cells: [SudokuCell] = []
    @Published var selectedCellId: Int? = nil
    @Published var isNoteMode: Bool = false
    @Published var gameState: GameState = .idle
    @Published var stats: GameStats = GameStats(difficulty: .medium)
    @Published var currentDifficulty: Difficulty = .medium
    @Published var hintsRemaining: Int = 1
    @Published var isDaily: Bool = false

    // Standart: 3 hata → oyun biter (4. hatada can düşer)
    // Daily: 5 hata → oyun biter
    var mistakeLimit: Int { isDaily ? 5 : 3 }
    var hintLimit:    Int { isDaily ? 2 : 1 }

    // 4. hatada can düşürülsün diye dışarıdan dinlenir
    var onLifeLost: (() -> Void)?
    @Published var lastCompletedScore: Int = 0
    @Published var completionProgress: Double = 0.0
    @Published var gameResults: [GameStats] = []

    // Time Attack
    @Published var isTimeAttack: Bool = false
    @Published var countdownSeconds: Int = 0
    @Published var countdownTotal: Int = 0

    private var solution: [Int] = Array(repeating: 0, count: 81)
    private var timer: AnyCancellable?
    private var undoStack: [[SudokuCell]] = []
    private let maxUndo = 50

    enum GameState {
        case idle, playing, paused, completed, failed
    }

    // MARK: - Init

    init() {
        self.gameResults = Self.loadResultsFromDisk()
    }

    // MARK: - Game Lifecycle

    func newGame(difficulty: Difficulty, timeAttack: Bool = false) {
        currentDifficulty = difficulty
        isTimeAttack = timeAttack
        stopTimer()
        undoStack = []

        let (puzzle, sol) = generatePuzzle(difficulty: difficulty)
        solution = sol

        cells = (0..<81).map { index in
            SudokuCell(id: index, value: puzzle[index], isGiven: puzzle[index] != 0)
        }

        isDaily = false
        stats = GameStats(difficulty: difficulty, isTimeAttack: timeAttack)
        hintsRemaining = timeAttack ? 1 : hintLimit
        selectedCellId = nil
        isNoteMode = false
        gameState = .playing
        completionProgress = 0.0

        if timeAttack {
            countdownTotal = difficulty.timeAttackSeconds
            countdownSeconds = countdownTotal
        }

        startTimer()
    }

    func newGameWithPuzzle(puzzle: [Int], solution: [Int]) {
        self.solution = solution
        currentDifficulty = .hard
        isTimeAttack = false
        stopTimer()
        undoStack = []

        cells = (0..<81).map { index in
            SudokuCell(id: index, value: puzzle[index], isGiven: puzzle[index] != 0)
        }

        isDaily = true
        stats = GameStats(difficulty: .hard)
        hintsRemaining = hintLimit
        selectedCellId = nil
        isNoteMode = false
        gameState = .playing
        completionProgress = 0.0
        countdownSeconds = 0
        startTimer()
    }

    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        stopTimer()
    }

    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        startTimer()
    }

    // MARK: - Time Attack Helpers

    var countdownFraction: Double {
        guard countdownTotal > 0 else { return 1.0 }
        return Double(countdownSeconds) / Double(countdownTotal)
    }

    var countdownColor: String {
        if countdownFraction > 0.5 { return "34D399" }
        if countdownFraction > 0.25 { return "FBBF24" }
        return "F87171"
    }

    var formattedCountdown: String {
        let m = countdownSeconds / 60
        let s = countdownSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Input

    func selectCell(_ id: Int) {
        guard gameState == .playing else { return }
        selectedCellId = (selectedCellId == id) ? nil : id
    }

    func inputNumber(_ number: Int) {
        guard gameState == .playing,
              let id = selectedCellId,
              !cells[id].isGiven else { return }

        saveUndo()

        if isNoteMode && number != 0 {
            if cells[id].value == 0 {
                if cells[id].notes.contains(number) {
                    cells[id].notes.remove(number)
                } else {
                    cells[id].notes.insert(number)
                }
                SoundManager.shared.playNoteToggle()
                HapticManager.shared.cellTap()
            }
        } else {
            cells[id].notes = []
            cells[id].value = number
            cells[id].isError = false

            if number != 0 {
                validateCell(id)

                if cells[id].isError {
                    SoundManager.shared.playError()
                    HapticManager.shared.error()
                } else {
                    SoundManager.shared.playNumberInput()
                    HapticManager.shared.numberInput()
                    clearRelatedNotes(for: id, number: number)
                }

                updateProgress()
                checkCompletion()
            } else {
                updateProgress()
            }
        }
    }

    func eraseCell() {
        guard gameState == .playing,
              let id = selectedCellId,
              !cells[id].isGiven else { return }

        saveUndo()
        cells[id].value = 0
        cells[id].isError = false
        cells[id].notes = []
        updateProgress()
        SoundManager.shared.playErase()
        HapticManager.shared.erase()
    }

    func useHint() {
        guard gameState == .playing,
              hintsRemaining > 0,
              let id = selectedCellId else { return }

        let cell = cells[id]
        guard !cell.isGiven, cell.value != solution[id] else { return }

        saveUndo()
        hintsRemaining -= 1
        stats.hintsUsed += 1
        cells[id].value = solution[id]
        cells[id].notes = []
        cells[id].isError = false
        cells[id].isAnimating = true
        clearRelatedNotes(for: id, number: solution[id])
        updateProgress()
        checkCompletion()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.cells[id].isAnimating = false
        }
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        cells = undoStack.removeLast()
        updateProgress()
        SoundManager.shared.playUndo()
        HapticManager.shared.undo()
    }

    // MARK: - Validation

    private func validateCell(_ id: Int) {
        guard cells[id].value != 0 else { return }
        let correct = cells[id].value == solution[id]
        cells[id].isError = !correct
        if !correct {
            stats.mistakesMade += 1
            // Standart oyun: 3. hata → oyun biter; 4. hata can düşürür
            if !isDaily && stats.mistakesMade == mistakeLimit {
                stopTimer()
                gameState = .failed
                // Can düşür
                onLifeLost?()
            } else if isDaily && stats.mistakesMade >= mistakeLimit {
                stopTimer()
                gameState = .failed
            }
        }
    }

    private func clearRelatedNotes(for id: Int, number: Int) {
        let row = cells[id].row
        let col = cells[id].col
        let box = cells[id].box

        for i in 0..<81 {
            if !cells[i].isGiven && cells[i].value == 0 {
                if cells[i].row == row || cells[i].col == col || cells[i].box == box {
                    cells[i].notes.remove(number)
                }
            }
        }
    }

    func getCellHighlightType(for cellId: Int) -> CellHighlightType {
        guard let selectedId = selectedCellId else { return .none }
        let selected = cells[selectedId]
        let cell = cells[cellId]
        if cellId == selectedId { return .selected }
        if cell.row == selected.row || cell.col == selected.col || cell.box == selected.box {
            return .related
        }
        if selected.value != 0 && cell.value == selected.value { return .sameNumber }
        return .none
    }

    enum CellHighlightType {
        case none, selected, related, sameNumber
    }

    // MARK: - Progress & Completion

    private func updateProgress() {
        let filled = cells.filter { $0.value != 0 && !$0.isError }.count
        let given = cells.filter { $0.isGiven }.count
        let total = 81 - given
        completionProgress = total > 0 ? Double(filled - given) / Double(total) : 0
    }

    private func checkCompletion() {
        let allFilled = cells.allSatisfy { $0.value != 0 }
        let noErrors = cells.allSatisfy { !$0.isError }

        if allFilled && noErrors {
            stopTimer()
            gameState = .completed
            stats.completedDate = Date()
            stats.score = calculateScore()
            lastCompletedScore = stats.score
            saveGameResult()
        }
    }

    private func calculateScore() -> Int {
        let base = 10000

        let diffMult: Double
        switch currentDifficulty {
        case .easy:   diffMult = 1.0
        case .medium: diffMult = 1.5
        case .hard:   diffMult = 2.0
        case .expert: diffMult = 3.0
        case .master: diffMult = 5.0
        }

        let timePenalty = max(0, stats.elapsedSeconds - 60)
        let hintPenalty = stats.hintsUsed * 500
        let mistakePenalty = stats.mistakesMade * 200
        let timeAttackBonus = isTimeAttack ? countdownSeconds * 10 : 0

        let score = max(0, Int(Double(base) * diffMult) - timePenalty - hintPenalty - mistakePenalty + timeAttackBonus)
        return score
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isTimeAttack {
                    if self.countdownSeconds > 0 {
                        self.countdownSeconds -= 1
                        self.stats.elapsedSeconds += 1
                        if self.countdownSeconds <= 10 {
                            HapticManager.shared.error()
                        }
                    } else {
                        self.stopTimer()
                        self.gameState = .failed
                        SoundManager.shared.playError()
                        HapticManager.shared.error()
                    }
                } else {
                    self.stats.elapsedSeconds += 1
                }
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Undo

    private func saveUndo() {
        undoStack.append(cells)
        if undoStack.count > maxUndo { undoStack.removeFirst() }
    }

    // MARK: - Persistence

    func saveGame() {
        guard gameState == .playing || gameState == .paused else { return }
        if let data = try? JSONEncoder().encode(cells) {
            UserDefaults.standard.set(data, forKey: "savedCells")
        }
        if let data = try? JSONEncoder().encode(solution) {
            UserDefaults.standard.set(data, forKey: "savedSolution")
        }
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "savedStats")
        }
        UserDefaults.standard.set(currentDifficulty.rawValue, forKey: "savedDifficulty")
        UserDefaults.standard.set(hintsRemaining, forKey: "savedHints")
        UserDefaults.standard.set(gameState == .paused, forKey: "savedPaused")
        UserDefaults.standard.set(isTimeAttack, forKey: "savedTimeAttack")
        UserDefaults.standard.set(countdownSeconds, forKey: "savedCountdown")
        UserDefaults.standard.set(countdownTotal, forKey: "savedCountdownTotal")
    }

    func loadGame() -> Bool {
        guard
            let cellData = UserDefaults.standard.data(forKey: "savedCells"),
            let solData = UserDefaults.standard.data(forKey: "savedSolution"),
            let statsData = UserDefaults.standard.data(forKey: "savedStats"),
            let cells = try? JSONDecoder().decode([SudokuCell].self, from: cellData),
            let sol = try? JSONDecoder().decode([Int].self, from: solData),
            let savedStats = try? JSONDecoder().decode(GameStats.self, from: statsData)
        else { return false }

        self.cells = cells
        self.solution = sol
        self.stats = savedStats
        self.hintsRemaining = UserDefaults.standard.integer(forKey: "savedHints")
        self.isTimeAttack = UserDefaults.standard.bool(forKey: "savedTimeAttack")
        self.countdownSeconds = UserDefaults.standard.integer(forKey: "savedCountdown")
        self.countdownTotal = UserDefaults.standard.integer(forKey: "savedCountdownTotal")

        let diffRaw = UserDefaults.standard.string(forKey: "savedDifficulty") ?? Difficulty.medium.rawValue
        self.currentDifficulty = Difficulty(rawValue: diffRaw) ?? .medium

        let wasPaused = UserDefaults.standard.bool(forKey: "savedPaused")
        self.gameState = wasPaused ? .paused : .playing

        if gameState == .playing { startTimer() }
        updateProgress()
        return true
    }

    private func saveGameResult() {
        var results = gameResults
        results.append(stats)
        if results.count > 100 { results = Array(results.suffix(100)) }
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: "gameResults")
        }
        gameResults = results  // ← @Published, UI otomatik güncellenir
    }

    // Disk'ten yükle — init'te kullanılır
    private static func loadResultsFromDisk() -> [GameStats] {
        guard let data = UserDefaults.standard.data(forKey: "gameResults"),
              let results = try? JSONDecoder().decode([GameStats].self, from: data) else { return [] }
        return results
    }

    // Geriye dönük uyumluluk
    func loadGameResults() -> [GameStats] {
        return gameResults
    }

    // MARK: - Puzzle Generation

    private func generatePuzzle(difficulty: Difficulty) -> ([Int], [Int]) {
        var board = Array(repeating: 0, count: 81)
        for box in 0..<3 { fillBox(&board, box: box * 3, boxRow: box * 3) }
        _ = solveSudoku(&board)
        let solution = board
        var puzzle = board
        let positions = Array(0..<81).shuffled()
        var removed = 0
        let target = 81 - difficulty.clueCount

        for pos in positions {
            if removed >= target { break }
            let backup = puzzle[pos]
            puzzle[pos] = 0
            var test = puzzle
            if countSolutions(&test) == 1 { removed += 1 } else { puzzle[pos] = backup }
        }
        return (puzzle, solution)
    }

    private func fillBox(_ board: inout [Int], box: Int, boxRow: Int) {
        let nums = Array(1...9).shuffled()
        var idx = 0
        for r in 0..<3 {
            for c in 0..<3 {
                board[(boxRow + r) * 9 + (box + c)] = nums[idx]
                idx += 1
            }
        }
    }

    private func solveSudoku(_ board: inout [Int]) -> Bool {
        guard let empty = findEmpty(board) else { return true }
        let row = empty / 9, col = empty % 9
        let nums = Array(1...9).shuffled()
        for num in nums {
            if isValid(board, row: row, col: col, num: num) {
                board[empty] = num
                if solveSudoku(&board) { return true }
                board[empty] = 0
            }
        }
        return false
    }

    private func countSolutions(_ board: inout [Int], limit: Int = 2) -> Int {
        guard let empty = findEmpty(board) else { return 1 }
        let row = empty / 9, col = empty % 9
        var count = 0
        for num in 1...9 {
            if isValid(board, row: row, col: col, num: num) {
                board[empty] = num
                count += countSolutions(&board, limit: limit)
                board[empty] = 0
                if count >= limit { return count }
            }
        }
        return count
    }

    private func findEmpty(_ board: [Int]) -> Int? { board.firstIndex(of: 0) }

    private func isValid(_ board: [Int], row: Int, col: Int, num: Int) -> Bool {
        for c in 0..<9 { if board[row * 9 + c] == num { return false } }
        for r in 0..<9 { if board[r * 9 + col] == num { return false } }
        let br = (row / 3) * 3, bc = (col / 3) * 3
        for r in 0..<3 { for c in 0..<3 { if board[(br + r) * 9 + (bc + c)] == num { return false } } }
        return true
    }

    // MARK: - Helpers

    var formattedTime: String {
        let h = stats.elapsedSeconds / 3600
        let m = (stats.elapsedSeconds % 3600) / 60
        let s = stats.elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var isCompleted: Bool { gameState == .completed }

    func numberCount(for num: Int) -> Int { cells.filter { $0.value == num }.count }
    func isNumberComplete(_ num: Int) -> Bool { numberCount(for: num) >= 9 }

    func autoFillNotes() {
        guard gameState == .playing else { return }
        saveUndo()
        for i in 0..<81 {
            guard !cells[i].isGiven && cells[i].value == 0 else { continue }
            var possibles = Set<Int>()
            for num in 1...9 {
                let tempBoard = cells.map { $0.value }
                if isValid(tempBoard, row: cells[i].row, col: cells[i].col, num: num) {
                    possibles.insert(num)
                }
            }
            cells[i].notes = possibles
        }
    }
}

