import SwiftUI
import AppKit

public struct PixelMascotView: View {
    @ObservedObject var monitor: ClaudeMonitor
    @AppStorage("selectedPetType") private var petTypeRaw: String = PetType.cat.rawValue
    @State private var walkX: CGFloat = 0
    @State private var isFacingLeft: Bool = false
    @State private var pounceY: CGFloat = 0
    @State private var showBubble: Bool = true
    
    // Heart click animation
    @State private var heartFloating: Bool = false
    @State private var heartOffset: CGFloat = 0
    @State private var heartOpacity: Double = 0
    
    // Sweat drop animation for >90% tokens
    @State private var sweatDripY: CGFloat = 0
    
    // Sleep Zzz offset
    @State private var zzzOffset: CGFloat = 0
    
    public init(monitor: ClaudeMonitor) {
        self.monitor = monitor
    }
    
    private var petType: PetType {
        PetType(rawValue: petTypeRaw) ?? .cat
    }
    
    private var petConfig: (width: CGFloat, height: CGFloat, dropX: CGFloat, dropY: CGFloat, laptopX: CGFloat) {
        switch petType {
        case .cat:
            return (width: 98, height: 56, dropX: 28, dropY: -44, laptopX: 32)
        case .fox:
            return (width: 88, height: 70, dropX: 24, dropY: -54, laptopX: 30)
        case .duck:
            return (width: 76, height: 68, dropX: 20, dropY: -52, laptopX: 26)
        case .totoro:
            return (width: 82, height: 82, dropX: 22, dropY: -66, laptopX: 32)
        case .panda:
            return (width: 78, height: 78, dropX: 22, dropY: -60, laptopX: 30)
        case .shiba:
            return (width: 98, height: 65, dropX: 28, dropY: -50, laptopX: 34)
        case .corgi:
            return (width: 96, height: 68, dropX: 28, dropY: -52, laptopX: 32)
        case .clippy:
            return (width: 68, height: 86, dropX: 18, dropY: -70, laptopX: 26)
        case .crab:
            return (width: 96, height: 58, dropX: 26, dropY: -46, laptopX: 32)
        }
    }
    
    public var body: some View {
        let isPanicking = monitor.info.weeklyPercent >= 90 || monitor.info.sessionPercent >= 90
        let isSleeping = monitor.info.mascotState == .sleeping
        let isCoding = monitor.info.mascotState == .coding
        let isThinking = monitor.info.mascotState == .thinking
        let isAnalyzing = monitor.info.mascotState == .analyzing
        let config = petConfig
        
        VStack(spacing: 2) {
            // Live Tokens & Status Speech Bubble (Smooth pop animation without layout collapse)
            SpeechBubbleView(info: monitor.info)
                .opacity(showBubble ? 1 : 0)
                .scaleEffect(showBubble ? 1 : 0.01, anchor: .bottom)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showBubble)
                .allowsHitTesting(showBubble)
            
            // The Pet & Action Props
            ZStack(alignment: .bottom) {
                // Heart on Click
                if heartFloating {
                    Text("❤️")
                        .font(.system(size: 18))
                        .offset(x: walkX, y: heartOffset - 20)
                        .opacity(heartOpacity)
                        .zIndex(25)
                }
                
                // Sleeping Zzz & Heart
                if isSleeping {
                    HStack(spacing: 4) {
                        Text("❤️")
                            .font(.system(size: 13))
                        Text("zZz")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .offset(x: isFacingLeft ? -28 : 28, y: zzzOffset - 36)
                    .zIndex(25)
                }
                
                // Authentic Animated Pet GIF (from vscode-pets)
                AnimatedGifView(
                    gifName: currentGifName,
                    targetSize: CGSize(width: config.width, height: config.height)
                )
                .frame(width: config.width, height: config.height)
                    .scaleEffect(x: isFacingLeft ? -1 : 1, y: 1)
                    .offset(x: walkX, y: pounceY)
                    .zIndex(1)
                    .onTapGesture {
                        triggerPounce()
                    }
                
                // Props: Mini Glowing Cyber Laptop when Coding
                if isCoding {
                    HStack(spacing: 4) {
                        Text("💻")
                            .font(.system(size: 16))
                        Text("< / >")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .offset(x: isFacingLeft ? (walkX - config.laptopX) : (walkX + config.laptopX), y: -8)
                    .zIndex(15)
                }
                
                // Props: Thinking Cloud when Thinking
                if isThinking {
                    Text("💭")
                        .font(.system(size: 16))
                        .offset(x: isFacingLeft ? (walkX - 22) : (walkX + 22), y: config.dropY - 6)
                        .zIndex(15)
                }
                
                // Props: Magnifying Glass when Analyzing
                if isAnalyzing {
                    Text("🔍")
                        .font(.system(size: 16))
                        .offset(x: isFacingLeft ? (walkX - 22) : (walkX + 22), y: config.dropY - 6)
                        .zIndex(15)
                }
                
                // Animated Teardrop (Sweat Drop) when Tokens >= 90%
                if isPanicking && !isSleeping {
                    TeardropShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.90, blue: 1.0),
                                    Color(red: 0.05, green: 0.55, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 11, height: 16)
                        .overlay(
                            // Crisp glossy shine
                            Circle()
                                .fill(Color.white.opacity(0.95))
                                .frame(width: 3.5, height: 3.5)
                                .offset(x: -2, y: 1)
                        )
                        .overlay(
                            // Subtle outline so it stands out clearly
                            TeardropShape()
                                .stroke(Color.black.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.cyan.opacity(0.85), radius: 4)
                        .rotationEffect(.degrees(isFacingLeft ? -16 : 16))
                        .offset(
                            x: isFacingLeft ? (walkX - config.dropX) : (walkX + config.dropX),
                            y: config.dropY + sweatDripY
                        )
                        .zIndex(20)
                }
            }
        }
        .frame(width: 260, height: 140)
        .contextMenu {
            Menu("Elegir Mascota") {
                ForEach(PetType.allCases, id: \.self) { pet in
                    Button(action: { petTypeRaw = pet.rawValue }) {
                        if petType == pet {
                            Text("✓  \(pet.rawValue)")
                        } else {
                            Text("    \(pet.rawValue)")
                        }
                    }
                }
            }
            
            Button(showBubble ? "Ocultar Burbuja de Tokens" : "Mostrar Burbuja de Tokens") {
                withAnimation(.spring()) {
                    showBubble.toggle()
                }
            }
            
            Divider()
            
            Button("Salir de ClaudeBuddy") {
                NSApp.terminate(nil)
            }
        }
        .onAppear {
            startAnimationLoops()
        }
    }
    
    private var currentGifName: String {
        let state = monitor.info.mascotState
        
        switch petType {
        case .cat:
            switch state {
            case .sleeping: return "orange_idle_8fps"
            case .coding, .analyzing, .thinking: return "orange_idle_8fps"
            case .idle: return "orange_walk_8fps"
            case .panicking: return "orange_run_8fps"
            }
        case .fox:
            switch state {
            case .sleeping: return "fox_red_lie_8fps"
            case .coding, .analyzing, .thinking: return "fox_red_idle_8fps"
            case .idle: return "fox_red_walk_8fps"
            case .panicking: return "fox_red_run_8fps"
            }
        case .duck:
            switch state {
            case .sleeping: return "duck_yellow_idle_8fps"
            case .coding, .analyzing, .thinking: return "duck_yellow_idle_8fps"
            case .idle: return "duck_yellow_walk_8fps"
            case .panicking: return "duck_yellow_run_8fps"
            }
        case .totoro:
            switch state {
            case .sleeping: return "totoro_gray_lie_8fps"
            case .coding, .analyzing, .thinking: return "totoro_gray_idle_8fps"
            case .idle, .panicking: return "totoro_gray_walk_8fps"
            }
        case .panda:
            switch state {
            case .sleeping: return "panda_black_lie_8fps"
            case .coding, .analyzing, .thinking: return "panda_black_idle_8fps"
            case .idle, .panicking: return "panda_black_walk_8fps"
            }
        case .shiba:
            switch state {
            case .sleeping: return "dog_akita_lie_8fps"
            case .coding, .analyzing, .thinking: return "dog_akita_idle_8fps"
            case .idle: return "dog_akita_walk_8fps"
            case .panicking: return "dog_akita_run_8fps"
            }
        case .corgi:
            switch state {
            case .sleeping: return "brown_lie_8fps"
            case .coding, .analyzing, .thinking: return "brown_idle_8fps"
            case .idle: return "brown_walk_8fps"
            case .panicking: return "brown_run_8fps"
            }
        case .clippy:
            switch state {
            case .sleeping: return "clippy_yellow_idle_8fps"
            case .coding, .analyzing, .thinking: return "clippy_yellow_idle_8fps"
            case .idle: return "clippy_yellow_walk_8fps"
            case .panicking: return "clippy_yellow_run_8fps"
            }
        case .crab:
            switch state {
            case .sleeping: return "crab_red_idle_8fps"
            case .coding, .analyzing, .thinking: return "crab_red_idle_8fps"
            case .idle: return "crab_red_walk_8fps"
            case .panicking: return "crab_red_run_8fps"
            }
        }
    }
    
    private func triggerPounce() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            pounceY = -24
            heartFloating = true
            heartOffset = -32
            heartOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                pounceY = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                heartOpacity = 0
                heartOffset = -48
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                heartFloating = false
            }
        }
    }
    
    private func startAnimationLoops() {
        // Smooth horizontal walking across the bottom
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                let state = monitor.info.mascotState
                
                // The pet WALKS when idle or panicking.
                // When thinking, analyzing, coding, or sleeping, it STOPS in place!
                if state == .idle || state == .panicking {
                    let speed: CGFloat = state == .panicking ? 1.6 : 1.0
                    let limit: CGFloat = 65.0
                    
                    if isFacingLeft {
                        walkX -= speed
                        if walkX <= -limit {
                            isFacingLeft = false
                        }
                    } else {
                        walkX += speed
                        if walkX >= limit {
                            isFacingLeft = true
                        }
                    }
                }
            }
        }
        
        // Sweat drip & Zzz loop
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            Task { @MainActor in
                sweatDripY += 0.8
                if sweatDripY > 8 {
                    sweatDripY = 0
                }
                
                zzzOffset -= 0.6
                if zzzOffset < -18 {
                    zzzOffset = 0
                }
            }
        }
    }
}

// Pixel-perfect Animated GIF View with strictly enforced target size
struct AnimatedGifView: NSViewRepresentable {
    let gifName: String
    let targetSize: CGSize
    
    func makeNSView(context: Context) -> PixelFitImageView {
        let view = PixelFitImageView(targetSize: targetSize)
        view.loadGif(named: gifName)
        return view
    }
    
    func updateNSView(_ nsView: PixelFitImageView, context: Context) {
        nsView.targetSize = targetSize
        nsView.loadGif(named: gifName)
    }
}

class PixelFitImageView: NSImageView {
    var targetSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    private var currentLoadedGif: String = ""
    
    init(targetSize: CGSize) {
        self.targetSize = targetSize
        super.init(frame: NSRect(origin: .zero, size: targetSize))
        self.imageScaling = .scaleProportionallyUpOrDown
        self.animates = true
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        self.layer?.magnificationFilter = .nearest
        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentHuggingPriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: targetSize.width, height: targetSize.height)
    }
    
    func loadGif(named gifName: String) {
        guard gifName != currentLoadedGif else { return }
        currentLoadedGif = gifName
        
        let bundlePath = Bundle.main.path(forResource: gifName, ofType: "gif", inDirectory: "Pets")
            ?? Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Pets/\(gifName).gif").path
        let devPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/Pets/\(gifName).gif").path
        let path = FileManager.default.fileExists(atPath: bundlePath) ? bundlePath : devPath
        
        if let image = NSImage(contentsOfFile: path) {
            self.image = image
            self.animates = true
        }
    }
}

// Teardrop shape for the sweat drop
struct TeardropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topCenter = CGPoint(x: rect.midX, y: rect.minY)
        let bottomCenter = CGPoint(x: rect.midX, y: rect.maxY - rect.width / 2)
        let radius = rect.width / 2
        
        path.move(to: topCenter)
        path.addLine(to: CGPoint(x: rect.maxX, y: bottomCenter.y))
        path.addArc(
            center: bottomCenter,
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: topCenter)
        path.closeSubpath()
        return path
    }
}

// Speech Bubble with Live Tokens & Status
struct SpeechBubbleView: View {
    let info: ClaudeUsageInfo
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 7, height: 7)
                    
                    Text(info.mascotState.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    if !info.activeProject.isEmpty {
                        Text("• \(info.activeProject)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Text("5h:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("\(info.sessionPercent)%")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Text("|")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    HStack(spacing: 3) {
                        Text("7d:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("\(info.weeklyPercent)%")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(info.weeklyPercent >= 90 ? Color.orange : .green)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.13, blue: 0.16).opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            
            TrianglePointer()
                .fill(Color(red: 0.12, green: 0.13, blue: 0.16).opacity(0.92))
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var badgeColor: Color {
        switch info.mascotState {
        case .coding: return .cyan
        case .analyzing: return .yellow
        case .thinking: return .purple
        case .panicking: return .red
        case .idle: return .green
        case .sleeping: return .gray
        }
    }
}

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
