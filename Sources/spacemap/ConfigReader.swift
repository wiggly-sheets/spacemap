import Foundation

enum ConfigReader {
    static func load() -> GridConfig {
        let path = NSString(string: "~/.config/spacemap/config").expandingTildeInPath
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return .default
        }

        var cols = GridConfig.default.cols
        var rows = GridConfig.default.rows
        var cellStyle = GridConfig.default.cellStyle

        for line in contents.components(separatedBy: .newlines) {
            let parts = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            switch key {
            case "GRID_COLS": cols = Int(value) ?? cols
            case "GRID_ROWS": rows = Int(value) ?? rows
            case "CELL_STYLE":
                switch value {
                case "icons":  cellStyle = .icons
                case "hybrid": cellStyle = .hybrid
                default:       cellStyle = .rects
                }
            default: break
            }
        }

        return GridConfig(cols: cols, rows: rows, cellStyle: cellStyle)
    }
}
