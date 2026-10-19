import Foundation

public enum MascotState: String, CaseIterable, Sendable {
    case idle = "Listo"
    case thinking = "Pensando..."
    case analyzing = "Analizando..."
    case coding = "Escribiendo código..."
    case panicking = "¡Alerta de Tokens!"
    case sleeping = "Durmiendo zZz"
}

public struct ClaudeUsageInfo: Sendable {
    public var sessionPercent: Int = 0
    public var sessionResetText: String = "Resets in --"
    public var weeklyPercent: Int = 0
    public var weeklyResetText: String = "Resets in --"
    public var activeProject: String = "Ninguno"
    public var currentStatus: String = "idle"
    public var mascotState: MascotState = .idle
    public var activeTool: String? = nil
    public var lastUpdated: Date = Date()
    
    public init() {}
}

// Direct Anthropic API structures
struct KeychainOAuthPayload: Codable {
    struct ClaudeAiOauth: Codable {
        let accessToken: String?
    }
    let claudeAiOauth: ClaudeAiOauth?
}

struct AnthropicUsageResponse: Codable {
    struct Window: Codable {
        let utilization: Double?
        let resets_at: String?
    }
    let five_hour: Window?
    let seven_day: Window?
}

// Live usage structure from ~/.claude/live-usage.json
struct LiveUsageFile: Codable {
    let five_hour: LiveWindow?
    let seven_day: LiveWindow?
}

struct LiveWindow: Codable {
    let utilization: Double?
    let resetsAt: Double?
    let resets_at: String?
}

// JSON Structures for ~/.claude.json fallback
struct ClaudeConfig: Codable {
    let cachedUsageUtilization: UsageUtilizationWrapper?
    let oauthAccount: OAuthAccount?
}

struct OAuthAccount: Codable {
    let emailAddress: String?
    let displayName: String?
}

struct UsageUtilizationWrapper: Codable {
    let utilization: UtilizationData?
}

struct UtilizationData: Codable {
    let five_hour: PeriodUtilization?
    let seven_day: PeriodUtilization?
    let limits: [UsageLimit]?
}

struct PeriodUtilization: Codable {
    let utilization: Double?
    let resets_at: String?
}

struct UsageLimit: Codable {
    let kind: String?
    let group: String?
    let percent: Double?
    let resets_at: String?
    let is_active: Bool?
}

// Session JSON structure from ~/.claude/sessions/*.json
struct SessionInfo: Codable {
    let pid: Int?
    let sessionId: String?
    let cwd: String?
    let name: String?
    let status: String?
    let statusUpdatedAt: Double?
    let updatedAt: Double?
}
