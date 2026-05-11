import Foundation
import CoreGraphics

enum CellStyle { case rects, icons, hybrid }

struct GridConfig {
    var cols: Int
    var rows: Int
    var cellStyle: CellStyle

    static let `default` = GridConfig(cols: 8, rows: 2, cellStyle: .rects)
}

struct YabaiSpace: Decodable {
    let id: Int
    let index: Int
    let display: Int
    let hasFocus: Bool

    enum CodingKeys: String, CodingKey {
        case id, index, display
        case hasFocus = "has-focus"
    }
}

struct YabaiWindow: Decodable {
    let id: Int
    let app: String
    let space: Int
    let frame: WindowFrame
    let isHidden: Bool
    let isMinimized: Bool

    struct WindowFrame: Decodable {
        let x: CGFloat
        let y: CGFloat
        let w: CGFloat
        let h: CGFloat
    }

    enum CodingKeys: String, CodingKey {
        case id, app, space, frame
        case isHidden = "is-hidden"
        case isMinimized = "is-minimized"
    }

    var cgFrame: CGRect {
        CGRect(x: frame.x, y: frame.y, width: frame.w, height: frame.h)
    }
}

struct GridState {
    let config: GridConfig
    let spaces: [YabaiSpace]
    let windows: [YabaiWindow]
    let displayBounds: CGRect
    let focusedIndex: Int?

    func windows(forSpace index: Int) -> [YabaiWindow] {
        windows.filter { $0.space == index }
    }
}
