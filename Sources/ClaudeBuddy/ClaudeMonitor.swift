import Foundation
import Combine

@MainActor
public class ClaudeMonitor: ObservableObject {
    @Published public var info: ClaudeUsageInfo = ClaudeUsageInfo()
    
    private var timer: Timer?
    private var apiTimer: Timer?
    private var fileWatcherSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let fileManager = FileManager.default
    private let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    
    // Direct API usage cache
    private var cachedOAuthToken: String?
    private var directUsageSessionPercent: Int?
    private var directUsageSessionReset: String?
    private var directUsageWeeklyPercent: Int?
    private var directUsageWeeklyReset: String?
    private var isFetchingAPI: Bool = false
    private var previousWasBusy: Bool = false
    
    public init() {
        refresh()
        startMonitoring()
        setupLiveFileWatcher()
        fetchDirectUsage()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        // Fast timer (1.5s) for real-time session status & active tool animations
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        
        apiTimer?.invalidate()
        // Direct API poller (every 20s) to keep token limits 100% synchronized with Anthropic
        apiTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchDirectUsage()
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        apiTimer?.invalidate()
        apiTimer = nil
        fileWatcherSource?.cancel()
        fileWatcherSource = nil
    }
    
    // MARK: - Direct Anthropic OAuth Live Usage API
    
    private func getOAuthToken() -> String? {
        if let token = cachedOAuthToken, !token.isEmpty {
            return token
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let jsonData = output.data(using: .utf8) else {
                return nil
            }
            let payload = try JSONDecoder().decode(KeychainOAuthPayload.self, from: jsonData)
            self.cachedOAuthToken = payload.claudeAiOauth?.accessToken
            return self.cachedOAuthToken
        } catch {
            return nil
        }
    }
    
    public func fetchDirectUsage() {
        guard !isFetchingAPI else { return }
        guard let token = getOAuthToken() else { return }
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return }
        
        isFetchingAPI = true
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("claude-code", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isFetchingAPI = false
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    self.cachedOAuthToken = nil
                    return
                }
                
                guard let data = data,
                      let decoded = try? JSONDecoder().decode(AnthropicUsageResponse.self, from: data) else {
                    return
                }
                
                if let fiveHour = decoded.five_hour, let u = fiveHour.utilization {
                    let pct = u <= 1.0 && u > 0 ? (u * 100.0) : u
                    self.directUsageSessionPercent = Int(round(pct))
                    if let resets = fiveHour.resets_at {
                        self.directUsageSessionReset = self.formatRelativeReset(resets)
                    }
                }
                
                if let sevenDay = decoded.seven_day, let u = sevenDay.utilization {
                    let pct = u <= 1.0 && u > 0 ? (u * 100.0) : u
                    self.directUsageWeeklyPercent = Int(round(pct))
                    if let resets = sevenDay.resets_at {
                        self.directUsageWeeklyReset = self.formatRelativeReset(resets)
                    }
                }
                
                self.refresh()
            }
        }.resume()
    }
    
    private func setupLiveFileWatcher() {
        let livePath = "\(homeDir)/.claude/live-usage.json"
        
        if !fileManager.fileExists(atPath: livePath) {
            let emptyData = "{}".data(using: .utf8) ?? Data()
            try? emptyData.write(to: URL(fileURLWithPath: livePath))
        }
        
        let fd = open(livePath, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib],
            queue: DispatchQueue.main
        )
        
        source.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.refresh()
            }
        }
        
        source.setCancelHandler {
            close(fd)
        }
        
        source.resume()
        self.fileWatcherSource = source
    }
    
    public func refresh() {
        var newInfo = ClaudeUsageInfo()
        
        // 1. Read usage (Priority: Direct API -> live-usage.json -> ~/.claude.json)
        readUsage(into: &newInfo)
        
        // 2. Read active sessions from ~/.claude/sessions/
        readSessions(into: &newInfo)
        
        // 3. Determine Mascot state
        determineMascotState(for: &newInfo)
        
        newInfo.lastUpdated = Date()
        self.info = newInfo
    }
    
    private func readUsage(into info: inout ClaudeUsageInfo) {
        // Source 1: Direct Live API from Anthropic (Most accurate & real-time)
        if let sPct = directUsageSessionPercent, let wPct = directUsageWeeklyPercent {
            info.sessionPercent = sPct
            if let r = directUsageSessionReset { info.sessionResetText = r }
            info.weeklyPercent = wPct
            if let r = directUsageWeeklyReset { info.weeklyResetText = r }
            return
        }
        
        // Source 2: live-usage.json file (if available and valid)
        let livePath = "\(homeDir)/.claude/live-usage.json"
        let now = Date().timeIntervalSince1970
        
        if fileManager.fileExists(atPath: livePath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: livePath)),
           let live = try? JSONDecoder().decode(LiveUsageFile.self, from: data) {
            
            var validFiveHour = false
            var validSevenDay = false
            
            if let fiveHour = live.five_hour, let u = fiveHour.utilization {
                let isExpired: Bool
                if let ts = fiveHour.resetsAt {
                    let targetSecs = ts > 100_000_000_000 ? (ts / 1000.0) : ts
                    isExpired = targetSecs < now
                } else {
                    isExpired = false
                }
                
                if !isExpired {
                    let pct = u <= 1.0 && u > 0 ? (u * 100.0) : u
                    info.sessionPercent = Int(round(pct))
                    if let resetsAtTimestamp = fiveHour.resetsAt {
                        info.sessionResetText = formatRelativeResetTimestamp(resetsAtTimestamp)
                    } else if let resetsAtStr = fiveHour.resets_at {
                        info.sessionResetText = formatRelativeReset(resetsAtStr)
                    } else {
                        info.sessionResetText = "Activo"
                    }
                    validFiveHour = true
                }
            }
            
            if let sevenDay = live.seven_day, let u = sevenDay.utilization {
                let isExpired: Bool
                if let ts = sevenDay.resetsAt {
                    let targetSecs = ts > 100_000_000_000 ? (ts / 1000.0) : ts
                    isExpired = targetSecs < now
                } else {
                    isExpired = false
                }
                
                if !isExpired {
                    let pct = u <= 1.0 && u > 0 ? (u * 100.0) : u
                    info.weeklyPercent = Int(round(pct))
                    if let resetsAtTimestamp = sevenDay.resetsAt {
                        info.weeklyResetText = formatRelativeResetTimestamp(resetsAtTimestamp)
                    } else if let resetsAtStr = sevenDay.resets_at {
                        info.weeklyResetText = formatRelativeReset(resetsAtStr)
                    } else {
                        info.weeklyResetText = "Activo"
                    }
                    validSevenDay = true
                }
            }
            
            if validFiveHour || validSevenDay {
                return
            }
        }
        
        // Source 3: ~/.claude.json fallback
        let configPath = "\(homeDir)/.claude.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)) else { return }
        
        guard let config = try? JSONDecoder().decode(ClaudeConfig.self, from: data),
              let utilization = config.cachedUsageUtilization?.utilization else {
            return
        }
        
        if let fiveHour = utilization.five_hour {
            let u = fiveHour.utilization ?? 0
            let pct = u <= 1.0 && u > 0 ? (u * 100.0) : u
            info.sessionPercent = Int(round(pct))
            if let resetsAt = fiveHour.resets_at {
                info.sessionResetText = formatRelativeReset(resetsAt)
            } else {
                info.sessionResetText = "Activo"
            }
        }
        
        if let sevenDay = utilization.seven_day {
            let u = sevenDay.utilization ?? 0
            let pct = u <= 1.0 && u > 0 ? (u * 100.0) : u
            info.weeklyPercent = Int(round(pct))
            if let resetsAt = sevenDay.resets_at {
                info.weeklyResetText = formatRelativeReset(resetsAt)
            } else {
                info.weeklyResetText = "Activo"
            }
        }
        
        if let limits = utilization.limits {
            for limit in limits {
                let kind = limit.kind ?? limit.group ?? ""
                if kind.contains("session") {
                    if let pct = limit.percent { info.sessionPercent = Int(round(pct)) }
                    if let resets = limit.resets_at { info.sessionResetText = formatRelativeReset(resets) }
                } else if kind.contains("weekly") {
                    if let pct = limit.percent { info.weeklyPercent = Int(round(pct)) }
                    if let resets = limit.resets_at { info.weeklyResetText = formatRelativeReset(resets) }
                }
            }
        }
    }
    
    private func readSessions(into info: inout ClaudeUsageInfo) {
        let sessionsDir = "\(homeDir)/.claude/sessions"
        guard let files = try? fileManager.contentsOfDirectory(atPath: sessionsDir) else {
            info.currentStatus = "offline"
            return
        }
        
        var latestSession: SessionInfo?
        var latestUpdateTime: Double = 0
        var isAnySessionBusy = false
        var activeSessionId: String?
        var activeProjectCwd: String?
        
        for file in files where file.hasSuffix(".json") {
            let fullPath = "\(sessionsDir)/\(file)"
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: fullPath)),
                  let session = try? JSONDecoder().decode(SessionInfo.self, from: data) else {
                continue
            }
            
            let updateTime = session.statusUpdatedAt ?? session.updatedAt ?? 0
            if updateTime > latestUpdateTime {
                latestUpdateTime = updateTime
                latestSession = session
            }
            
            if session.status == "busy" {
                isAnySessionBusy = true
                activeSessionId = session.sessionId
                activeProjectCwd = session.cwd
            }
        }
        
        if let session = latestSession {
            if let cwd = session.cwd {
                let folder = URL(fileURLWithPath: cwd).lastPathComponent
                info.activeProject = folder.isEmpty ? (session.name ?? "Claude Code") : folder
            } else {
                info.activeProject = session.name ?? "Claude Code"
            }
        }
        
        // If transitioning from busy to idle, Claude just completed work: refresh API usage
        if previousWasBusy && !isAnySessionBusy {
            fetchDirectUsage()
        }
        previousWasBusy = isAnySessionBusy
        
        if isAnySessionBusy {
            info.currentStatus = "busy"
            if let sessionId = activeSessionId, let cwd = activeProjectCwd {
                checkRecentTool(sessionId: sessionId, cwd: cwd, into: &info)
            }
        } else if latestSession != nil {
            info.currentStatus = "idle"
        } else {
            info.currentStatus = "offline"
        }
    }
    
    private func checkRecentTool(sessionId: String, cwd: String, into info: inout ClaudeUsageInfo) {
        let escapedCwd = cwd.replacingOccurrences(of: "/", with: "-")
        let transcriptPath = "\(homeDir)/.claude/projects/\(escapedCwd)/\(sessionId).jsonl"
        
        guard fileManager.fileExists(atPath: transcriptPath),
              let handle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: transcriptPath)) else {
            return
        }
        
        defer { try? handle.close() }
        
        let fileSize = handle.seekToEndOfFile()
        let readLength = min(fileSize, 8192)
        handle.seek(toFileOffset: fileSize - readLength)
        let data = handle.readDataToEndOfFile()
        
        guard let text = String(data: data, encoding: .utf8) else { return }
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for line in lines.reversed() {
            if line.contains("\"Edit\"") || line.contains("\"Write\"") || line.contains("\"NotebookEdit\"") {
                info.activeTool = "Edit"
                return
            } else if line.contains("\"Bash\"") || line.contains("\"Grep\"") || line.contains("\"Glob\"") || line.contains("\"ReadFile\"") || line.contains("\"View\"") {
                info.activeTool = "Analyze"
                return
            }
        }
    }
    
    private func determineMascotState(for info: inout ClaudeUsageInfo) {
        if info.currentStatus == "busy" {
            if let tool = info.activeTool {
                if tool == "Edit" {
                    info.mascotState = .coding
                } else {
                    info.mascotState = .analyzing
                }
            } else {
                info.mascotState = .thinking
            }
        } else if info.currentStatus == "idle" {
            if info.weeklyPercent >= 90 || info.sessionPercent >= 90 {
                info.mascotState = .panicking
            } else {
                info.mascotState = .idle
            }
        } else {
            info.mascotState = .sleeping
        }
    }
    
    private func formatRelativeResetTimestamp(_ timestamp: Double) -> String {
        let targetSeconds = timestamp > 100_000_000_000 ? (timestamp / 1000.0) : timestamp
        let targetDate = Date(timeIntervalSince1970: targetSeconds)
        return formatTimeDifference(from: targetDate)
    }
    
    private func formatRelativeReset(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        
        guard let targetDate = date else {
            return "Resets pronto"
        }
        
        return formatTimeDifference(from: targetDate)
    }
    
    private func formatTimeDifference(from targetDate: Date) -> String {
        let seconds = targetDate.timeIntervalSince(Date())
        if seconds <= 0 {
            return "Reseteando..."
        }
        
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let mins = (Int(seconds) % 3600) / 60
        
        if days > 0 {
            return "Resets in \(days)d"
        } else if hours > 0 {
            return "Resets in \(hours)h"
        } else {
            return "Resets in \(max(1, mins))m"
        }
    }
}
