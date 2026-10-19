import Foundation
import Combine

@MainActor
public class ClaudeMonitor: ObservableObject {
    @Published public var info: ClaudeUsageInfo = ClaudeUsageInfo()
    
    private var timer: Timer?
    private var fileWatcherSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let fileManager = FileManager.default
    private let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    
    public init() {
        refresh()
        startMonitoring()
        setupLiveFileWatcher()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        // Poll every 1.5 seconds for sessions, status & active tools
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
    
    private func setupLiveFileWatcher() {
        let livePath = "\(homeDir)/.claude/live-usage.json"
        
        // Ensure file exists so we can watch its descriptor
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
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        fileWatcherSource?.cancel()
        fileWatcherSource = nil
    }
    
    public func refresh() {
        var newInfo = ClaudeUsageInfo()
        
        // 1. Read usage (first check live-usage.json, then cached fallback)
        readUsage(into: &newInfo)
        
        // 2. Read active sessions from ~/.claude/sessions/
        readSessions(into: &newInfo)
        
        // 3. Determine Mascot state
        determineMascotState(for: &newInfo)
        
        newInfo.lastUpdated = Date()
        self.info = newInfo
    }
    
    private func readUsage(into info: inout ClaudeUsageInfo) {
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
            
            // Only return if at least one window is valid and not expired
            if validFiveHour || validSevenDay {
                return
            } else {
                // If live data has completely expired, remove the stale file
                try? fileManager.removeItem(atPath: livePath)
            }
        }
        
        // Fallback: ~/.claude.json
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
