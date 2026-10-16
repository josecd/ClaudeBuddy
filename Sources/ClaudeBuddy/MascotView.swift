import SwiftUI

public struct MascotView: View {
    @ObservedObject var monitor: ClaudeMonitor
    let isMini: Bool
    
    // Animation states
    @State private var walkOffset: CGFloat = 0
    @State private var isWalkingRight: Bool = true
    @State private var walkPhase: CGFloat = 0
    @State private var eyeBlink: Bool = false
    @State private var bounceOffset: CGFloat = 0
    @State private var typingPhase: CGFloat = 0
    @State private var particles: [CodeParticle] = []
    @State private var panicShake: CGFloat = 0
    @State private var pokeJump: CGFloat = 0
    
    public init(monitor: ClaudeMonitor, isMini: Bool = false) {
        self.monitor = monitor
        self.isMini = isMini
    }
    
    public var body: some View {
        let state = monitor.info.mascotState
        let scale: CGFloat = isMini ? 0.75 : 1.0
        
        ZStack {
            // Floating code particles during coding
            if state == .coding {
                ForEach(particles) { p in
                    Text(p.symbol)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.cyan.opacity(p.opacity))
                        .offset(x: p.x, y: p.y)
                }
            }
            
            // The Mascot Character
            VStack(spacing: 2) {
                // Antenna
                AntennaView(state: state, isTyping: state == .coding)
                
                // Head & Face
                HeadView(
                    state: state,
                    eyeBlink: eyeBlink,
                    panicShake: panicShake
                )
                
                // Arms / Action props (Laptop, Magnifying Glass, or Hands)
                ActionPropsView(
                    state: state,
                    typingPhase: typingPhase
                )
                
                // Feet / Walking legs
                FeetView(
                    walkPhase: walkPhase,
                    isMoving: abs(walkOffset) > 0.1 || state == .coding
                )
            }
            .scaleEffect(scale)
            .offset(x: walkOffset, y: bounceOffset + pokeJump)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    pokeJump = -20
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        pokeJump = 0
                    }
                }
            }
        }
        .frame(height: isMini ? 95 : 120)
        .onAppear {
            startAnimationLoops()
        }
    }
    
    private func startAnimationLoops() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                let state = monitor.info.mascotState
                
                // Walking movement back and forth
                let maxRange: CGFloat = isMini ? 35 : 75
                let speed: CGFloat = state == .coding ? 0.2 : (state == .panicking ? 1.5 : 0.8)
                
                if isWalkingRight {
                    walkOffset += speed
                    if walkOffset >= maxRange {
                        isWalkingRight = false
                    }
                } else {
                    walkOffset -= speed
                    if walkOffset <= -maxRange {
                        isWalkingRight = true
                    }
                }
                
                // Walking feet phase
                walkPhase += speed * 0.2
                
                // Subtle breathing / bobbing
                bounceOffset = sin(walkPhase * 1.5) * (state == .coding ? 1.5 : 3.0)
                
                // Typing / tools animation
                if state == .coding {
                    typingPhase += 0.4
                    if Int.random(in: 0...6) == 0 {
                        let symbols = ["{ }", "</>", "fn", "=>", "let", "01", "++", ";"]
                        let newP = CodeParticle(
                            symbol: symbols.randomElement()!,
                            x: walkOffset + CGFloat.random(in: -20...20),
                            y: -10,
                            opacity: 1.0
                        )
                        particles.append(newP)
                    }
                }
                
                // Update particles
                for i in particles.indices {
                    particles[i].y -= 1.8
                    particles[i].opacity -= 0.04
                }
                particles.removeAll { $0.opacity <= 0 }
                
                // Panic vibration
                if state == .panicking {
                    panicShake = CGFloat.random(in: -2...2)
                } else {
                    panicShake = 0
                }
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.1)) {
                    eyeBlink = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        eyeBlink = false
                    }
                }
            }
        }
    }
}

public struct CodeParticle: Identifiable, Sendable {
    public let id = UUID()
    public let symbol: String
    public var x: CGFloat
    public var y: CGFloat
    public var opacity: Double
}

struct AntennaView: View {
    let state: MascotState
    let isTyping: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: state == .panicking ? [.red, .orange] :
                               (state == .coding ? [.cyan, .blue] : [.orange, .yellow]),
                        center: .center,
                        startRadius: 1,
                        endRadius: 6
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(
                    color: state == .panicking ? .red : (state == .coding ? .cyan : .orange),
                    radius: isTyping ? 6 : 3
                )
            
            Rectangle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 2, height: 6)
        }
    }
}

struct HeadView: View {
    let state: MascotState
    let eyeBlink: Bool
    let panicShake: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.95), Color(white: 0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 62, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.1, green: 0.12, blue: 0.15))
                .frame(width: 50, height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                )
            
            HStack(spacing: 12) {
                if state == .panicking {
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(width: 9, height: 9)
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(width: 9, height: 9)
                } else if eyeBlink || state == .sleeping {
                    Capsule()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 2)
                    Capsule()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 2)
                } else if state == .analyzing {
                    HStack(spacing: 2) {
                        Circle().fill(Color.yellow).frame(width: 6, height: 6)
                        Circle().fill(Color.yellow.opacity(0.4)).frame(width: 3, height: 3)
                    }
                    HStack(spacing: 2) {
                        Circle().fill(Color.yellow).frame(width: 6, height: 6)
                        Circle().fill(Color.yellow.opacity(0.4)).frame(width: 3, height: 3)
                    }
                } else if state == .coding {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.cyan)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.cyan)
                } else {
                    Capsule()
                        .fill(Color.cyan)
                        .frame(width: 7, height: 9)
                        .shadow(color: .cyan.opacity(0.8), radius: 2)
                    Capsule()
                        .fill(Color.cyan)
                        .frame(width: 7, height: 9)
                        .shadow(color: .cyan.opacity(0.8), radius: 2)
                }
            }
            
            if state == .panicking {
                Text("💧")
                    .font(.system(size: 12))
                    .offset(x: 24, y: -16)
            }
        }
        .offset(x: panicShake)
    }
}

struct ActionPropsView: View {
    let state: MascotState
    let typingPhase: CGFloat
    
    var body: some View {
        Group {
            if state == .coding {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.3))
                        .frame(width: 44, height: 10)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                        .frame(width: 36, height: 16)
                        .overlay(
                            VStack(spacing: 2) {
                                Capsule().fill(Color.cyan).frame(width: 24, height: 2)
                                Capsule().fill(Color.green).frame(width: 18, height: 2)
                                Capsule().fill(Color.orange).frame(width: 20, height: 2)
                            }
                        )
                        .rotation3DEffect(.degrees(25), axis: (x: 1, y: 0, z: 0))
                        .offset(y: -9)
                    
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                            .offset(y: sin(typingPhase) * 2)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                            .offset(y: cos(typingPhase) * 2)
                    }
                    .offset(y: 2)
                }
                .offset(y: -4)
            } else if state == .analyzing {
                HStack(spacing: 4) {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "sparkle")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        )
                    
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 8, height: 2)
                        .rotationEffect(.degrees(45))
                }
                .offset(y: -2)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.92))
                    .frame(width: 32, height: 14)
                    .overlay(
                        HStack(spacing: 4) {
                            Circle().fill(Color.gray.opacity(0.4)).frame(width: 4, height: 4)
                            Circle().fill(Color.orange.opacity(0.8)).frame(width: 4, height: 4)
                            Circle().fill(Color.gray.opacity(0.4)).frame(width: 4, height: 4)
                        }
                    )
            }
        }
    }
}

struct FeetView: View {
    let walkPhase: CGFloat
    let isMoving: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(Color(white: 0.75))
                .frame(width: 8, height: 5)
                .offset(y: isMoving ? sin(walkPhase) * 3 : 0)
            
            Capsule()
                .fill(Color(white: 0.75))
                .frame(width: 8, height: 5)
                .offset(y: isMoving ? -sin(walkPhase) * 3 : 0)
        }
    }
}
