import SwiftUI

public enum PetType: String, CaseIterable, Sendable {
    case cat = "Gatito Naranja 🐱"
    case fox = "Zorro Rojo 🦊"
    case duck = "Patito de Goma 🦆"
    case totoro = "Totoro 🍃"
    case panda = "Oso Panda 🐼"
    case shiba = "Shiba Inu 🐕"
    case corgi = "Corgi 🐶"
    case clippy = "Clippy 📎"
    case crab = "Ferris Cangrejo 🦀"
}

public struct PixelFrame: Sendable {
    public let width: Int
    public let height: Int
    public let rows: [String]
    
    public init(rows: [String]) {
        self.rows = rows
        self.height = rows.count
        self.width = rows.first?.count ?? 0
    }
}

public struct PixelPalette {
    public static func color(for char: Character, petType: PetType) -> Color? {
        switch char {
        case ".": return nil // Transparent
        case "B": return Color(red: 0.14, green: 0.11, blue: 0.08) // Dark contour
        case "O": // Main fur: Warm ginger orange for cat, golden honey for corgi
            return petType == .cat ? Color(red: 0.96, green: 0.54, blue: 0.22) : Color(red: 0.88, green: 0.54, blue: 0.24)
        case "o": // Shaded fur
            return petType == .cat ? Color(red: 0.82, green: 0.42, blue: 0.15) : Color(red: 0.74, green: 0.42, blue: 0.18)
        case "W": return Color(white: 0.98) // White belly, chest & socks
        case "w": return Color(red: 0.90, green: 0.88, blue: 0.86) // Shaded white
        case "P": return Color(red: 1.0, green: 0.58, blue: 0.68) // Pink nose & inner ears
        case "E": return Color(red: 0.08, green: 0.08, blue: 0.10) // Black pupil
        case "e": return Color(red: 0.25, green: 0.82, blue: 0.45) // Emerald green cat eye
        case "T": return Color(red: 1.0, green: 0.45, blue: 0.55) // Corgi tongue
        case "K": return Color(red: 0.20, green: 0.22, blue: 0.26) // Laptop base
        case "C": return Color(red: 0.0, green: 0.88, blue: 1.0) // Glowing laptop screen
        case "G": return Color(red: 1.0, green: 0.82, blue: 0.22) // Golden magnifying glass
        default: return nil
        }
    }
}

// 26 columns x 16 rows: Anatomic quadruped Cat
public struct CatSprites {
    // Walk Frame 1 (Left paws forward, tail up)
    public static let walk1 = PixelFrame(rows: [
        "..........................",
        "......................BBB.",
        "...BB...BB...........BOOB.",
        "..BPB..BPB..........BOOB..",
        ".BOOBOOBOB.........BOOB...",
        ".BOeEOeEBOBBBBBBBBBBOB....",
        ".BOOPEPOOOOOOOOOOOOOB.....",
        ".BOOOPOOOOOOOOOOOOOOB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "...BOOOOOOOOOOOOOOOB......",
        "...BOOB.BOOB..BOOB.BOB....",
        "...BOOB.BOOB..BOOB.BOB....",
        "...BWWB.BWWB..BWWB.BWB....",
        "...BBBB.BBBB..BBBB.BBBB...",
    ])
    
    // Walk Frame 2 (Passing paws)
    public static let walk2 = PixelFrame(rows: [
        "..........................",
        ".......................BB.",
        "...BB...BB............BOB.",
        "..BPB..BPB...........BOOB.",
        ".BOOBOOBOB..........BOOB..",
        ".BOeEOeEBOBBBBBBBBBBOOB...",
        ".BOOPEPOOOOOOOOOOOOOOB....",
        ".BOOOPOOOOOOOOOOOOOOB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "...BOOOOOOOOOOOOOOOB......",
        "....BOOB.BOOB..BOOB.BOB...",
        "....BOOB.BOOB..BOOB.BOB...",
        "....BWWB.BWWB..BWWB.BWB...",
        "....BBBB.BBBB..BBBB.BBBB..",
    ])
    
    // Walk Frame 3 (Right paws forward, tail waving)
    public static let walk3 = PixelFrame(rows: [
        "..........................",
        "......................BBB.",
        "...BB...BB...........BOOB.",
        "..BPB..BPB..........BOOB..",
        ".BOOBOOBOB.........BOOB...",
        ".BOeEOeEBOBBBBBBBBBBOB....",
        ".BOOPEPOOOOOOOOOOOOOB.....",
        ".BOOOPOOOOOOOOOOOOOOB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "...BOOOOOOOOOOOOOOOB......",
        "....BOOB.BOOB..BOOB.BOB...",
        "...BOOB..BOOB.BOOB..BOB...",
        "...BWWB..BWWB.BWWB..BWB...",
        "...BBBB..BBBB.BBBB..BBBB..",
    ])
    
    // Coding on mini laptop (Sitting upright, paws on keys)
    public static let coding = PixelFrame(rows: [
        "....BB...BB...............",
        "...BPB..BPB...............",
        "..BOOBOOBOB...............",
        "..BOeEOeEBOB..............",
        "..BOOPEPOOOB...BCCB.......",
        "..BOOOPOOOOB...BCCB.......",
        "...BOWWWWOB.....BB........",
        "...BOWWWWOBB....KKKK......",
        "...BOWWWWWWOOBBBKKKB......",
        "...BOOWWWWWWOOOOOOB.......",
        "...BOOOOOOOOOOOOOOB.......",
        "...BOOOOOOOOOOOOOOB.BB....",
        "....BOOBBOOBBOOOOOBBOOB...",
        "....BWBBBWBB.BOOOOBBOOB...",
        "....BB..BB....BBBBB.BB....",
    ])
    
    // Analyzing with magnifying glass
    public static let analyzing = PixelFrame(rows: [
        "....BB...BB....BGB........",
        "...BPB..BPB...BGGGB.......",
        "..BOOBOOBOB....BGB........",
        "..BOeEOeEBOB....B.........",
        "..BOOPEPOOOB...B..........",
        "..BOOOPOOOOB.BB...........",
        "...BOWWWWOBB.BOOB.........",
        "...BOWWWWWWWBOOOB.........",
        "...BOWWWWWWWWOOB..........",
        "...BOOOOOOOOOOB...........",
        "...BOOOOOOOOOOB.....BB....",
        "....BOOBBOOOOOB....BOOB...",
        "....BWBBBWBOOOB...BOOB....",
        "....BB..BB.BOOOBBBOOB.....",
        "............BBBBBBB.......",
    ])
    
    // Sleeping curled up into a doughnut (like the reference cat!)
    public static let sleep = PixelFrame(rows: [
        "..........................",
        "..........................",
        "..........................",
        ".....BB...BB..............",
        "....BPB..BPB..............",
        "...BOOBOOBOBOBBBBBBBB.....",
        "..BOO--O--BOOOOOOOOOOB....",
        "..BOOPEPOOOOOOOOOOOOOOB...",
        "..BOOOOOOOOOOOOOOOOOOOB...",
        "..BOWWWWWWWWWWWWWWWWOB....",
        "..BOWWWWWWWWWWWWWWWWOB....",
        "...BOOOOOOOOOOOOOOOOB.....",
        "....BBBBBBBBBBBBBBBB......",
    ])
}

// 26 columns x 16 rows: Anatomic Corgi
public struct CorgiSprites {
    public static let walk1 = PixelFrame(rows: [
        "....B.....B...............",
        "...BPB...BPB..............",
        "..BOOB...BOOB.............",
        "..BOOOOOOOOOB.............",
        "..BOEOEOEOOOB.............",
        "..BOOPEPOOOOB.............",
        "...BOOOTOOOB..............",
        "...BOOOOOOBBBBBBBBBBB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "..BOWWWWWWWWWWWWWWWOB.BB..",
        "..BOWWWWWWWWWWWWWWWOBBOOB.",
        "...BOOOOOOOOOOOOOOOBBOOB..",
        "...BOOB.BOOB..BOOB..BB....",
        "...BWWB.BWWB..BWWB........",
        "...BBBB.BBBB..BBBB........",
    ])
    
    public static let walk2 = PixelFrame(rows: [
        "....B.....B...............",
        "...BPB...BPB..............",
        "..BOOB...BOOB.............",
        "..BOOOOOOOOOB.............",
        "..BOEOEOEOOOB.............",
        "..BOOPEPOOOOB.............",
        "...BOOOTOOOB..............",
        "...BOOOOOOBBBBBBBBBBB.....",
        "..BOWWWWWWWWWWWWWWWOB.....",
        "..BOWWWWWWWWWWWWWWWOB.BB..",
        "..BOWWWWWWWWWWWWWWWOBBOOB.",
        "...BOOOOOOOOOOOOOOOBBOOB..",
        "....BOOB.BOOB..BOOB.BB....",
        "....BWWB.BWWB..BWWB.......",
        "....BBBB.BBBB..BBBB.......",
    ])
    
    public static let coding = PixelFrame(rows: [
        "....B.....B...............",
        "...BPB...BPB..............",
        "..BOOB...BOOB.............",
        "..BOOOOOOOOOB.............",
        "..BOEOEOEOOOB.............",
        "..BOOPEPOOOOB..BCCB.......",
        "...BOOOTOOOB...BCCB.......",
        "...BOOOOOOB.....BB........",
        "..BOWWWWWWOB....KKKK......",
        "..BOWWWWWWOBBBBBKKKB......",
        "..BOWWWWWWWWWWWWWOB.BB....",
        "...BOOOOOOOOOOOOOB.BOOB...",
        "....BOOB.BOOBBOOOB.BOOB...",
        "....BWWB.BWWB.BBBB..BB....",
        "....BBBB.BBBB.............",
    ])
    
    public static let sleep = PixelFrame(rows: [
        "..........................",
        "..........................",
        "....B.....B...............",
        "...BPB...BPB..............",
        "..BOOB...BOOB.............",
        "..BOOOOOOOOOBBBBBBBB......",
        "..BOO--O--BOOOOOOOOOB.....",
        "..BOOPEPOOOOOOOOOOOOOB....",
        "..BOWWWWWWWWWWWWWWWWOB.BB.",
        "..BOWWWWWWWWWWWWWWWWOBBOOB",
        "...BOOOOOOOOOOOOOOOOBBOOB.",
        "....BBBBBBBBBBBBBBBB.BB...",
    ])
}

// High performance Canvas renderer for the pixel grid
public struct PixelFrameView: View {
    let frame: PixelFrame
    let petType: PetType
    let pixelSize: CGFloat
    
    public init(frame: PixelFrame, petType: PetType = .cat, pixelSize: CGFloat = 3.6) {
        self.frame = frame
        self.petType = petType
        self.pixelSize = pixelSize
    }
    
    public var body: some View {
        Canvas { context, size in
            for (y, row) in frame.rows.enumerated() {
                for (x, char) in row.enumerated() {
                    if let color = PixelPalette.color(for: char, petType: petType) {
                        let rect = CGRect(
                            x: CGFloat(x) * pixelSize,
                            y: CGFloat(y) * pixelSize,
                            width: pixelSize,
                            height: pixelSize
                        )
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
        .frame(
            width: CGFloat(frame.width) * pixelSize,
            height: CGFloat(frame.height) * pixelSize
        )
    }
}
