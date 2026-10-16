import SwiftUI

public struct WidgetCardView: View {
    @ObservedObject var monitor: ClaudeMonitor
    @State private var isCompact: Bool = false
    @State private var isHovered: Bool = false
    
    public init(monitor: ClaudeMonitor) {
        self.monitor = monitor
    }
    
    public var body: some View {
        ZStack {
            // Dark Frosted Glass Background
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.12, blue: 0.14).opacity(0.88),
                            Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.05),
                                    Color.black.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
            
            // Content Layout
            VStack(spacing: 8) {
                // Top Header Row
                HStack(alignment: .center) {
                    // Status Badge Pill
                    HStack(spacing: 5) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 7, height: 7)
                            .shadow(color: statusColor, radius: 4)
                        
                        Text(monitor.info.mascotState.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Project Name
                    if !monitor.info.activeProject.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text(monitor.info.activeProject)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    
                    // Compact Mode Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            isCompact.toggle()
                        }
                    }) {
                        Image(systemName: isCompact ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(4)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(isCompact ? "Expandir Widget" : "Modo Compacto")
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                
                // Animated Mascot Character Area
                MascotView(monitor: monitor, isMini: isCompact)
                    .padding(.vertical, isCompact ? 2 : 4)
                
                // Token Usage Section (hidden when in Compact Mode)
                if !isCompact {
                    VStack(alignment: .leading, spacing: 10) {
                        // Section Title
                        Text("USAGE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.45))
                            .tracking(1.2)
                        
                        // 1. Session (5hr)
                        UsageRow(
                            title: "Session (5hr)",
                            percent: monitor.info.sessionPercent,
                            resetText: monitor.info.sessionResetText,
                            gradient: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.45, blue: 0.95)]
                        )
                        
                        // 2. Weekly (7 day)
                        let weeklyPct = monitor.info.weeklyPercent
                        let weeklyGradient: [Color] = weeklyPct >= 85 ?
                            [Color(red: 1.0, green: 0.45, blue: 0.3), Color(red: 0.95, green: 0.25, blue: 0.2)] :
                            [Color(red: 0.95, green: 0.55, blue: 0.35), Color(red: 0.85, green: 0.45, blue: 0.25)]
                        
                        UsageRow(
                            title: "Weekly (7 day)",
                            percent: weeklyPct,
                            resetText: monitor.info.weeklyResetText,
                            gradient: weeklyGradient
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(width: 250)
        .fixedSize(horizontal: false, vertical: true)
        .onHover { h in
            isHovered = h
        }
    }
    
    private var statusColor: Color {
        switch monitor.info.mascotState {
        case .coding:
            return .cyan
        case .analyzing:
            return .yellow
        case .thinking:
            return .purple
        case .panicking:
            return .red
        case .idle:
            return .green
        case .sleeping:
            return .gray
        }
    }
}

// Single Usage Row with Progress Bar
struct UsageRow: View {
    let title: String
    let percent: Int
    let resetText: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Labels
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("\(percent)%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(percent >= 90 ? Color.orange : .white.opacity(0.85))
            }
            
            // Progress Bar Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 5)
                    
                    // Filled Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(4, geo.size.width * CGFloat(min(100, max(0, percent))) / 100.0),
                            height: 5
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: percent)
                }
            }
            .frame(height: 5)
            
            // Subtitle: Reset countdown
            Text(resetText)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
        }
    }
}
