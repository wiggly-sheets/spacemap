import SwiftUI

struct GridView: View {
    let state: GridState
    let hoveredCell: Int?
    let onSelect: (Int) -> Void
    let uiScale: Double
    let theme: String
    
    private var isDarkMode: Bool {
        switch state.config.mode {
        case .light: return false
        case .dark:  return true
        case .auto:  return NSApp.effectiveAppearance.name == .darkAqua
        }
    }
    
    // These values will be scaled by uiScale
    private let baseCellWidth: CGFloat = 80
    private let baseCellHeight: CGFloat = 50
    private let baseGap: CGFloat = 6
    private let basePadding: CGFloat = 12
    
    var body: some View {
        let cells = visibleSpaceIndices
        // Chunk into rows of config.cols width
        let rows = stride(from: 0, to: cells.count, by: state.config.cols).map {
            Array(cells[$0..<min($0 + state.config.cols, cells.count)])
        }
        VStack(spacing: effectiveGap) {
            ForEach(0..<rows.count, id: \.self) { row in
                HStack(spacing: effectiveGap) {
                    ForEach(rows[row], id: \.self) { spaceIndex in
                        makeCell(for: spaceIndex, row: row)
                    }
                }
            }
        }
        .padding(effectivePadding)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    private func spaceLabel(for index: Int) -> String? {
        state.spaces.first { $0.index == index }?.label
    }
    
    private var visibleSpaceIndices: [Int] {
        let maxN = min(state.config.maxSpaces, 16)
        let all = (1...maxN).map { $0 }
        if state.config.showMode == .active {
            let activeSet = Set(state.spaces.map { $0.index })
            return all.filter { activeSet.contains($0) }
        }
        return all
    }
    
    private func makeCell(for spaceIndex: Int, row: Int) -> some View {
        let cellSpaceIndex = spaceIndex
        let cellSpaceLabel = spaceLabel(for: spaceIndex)
        let cellSpaceName = state.config.spaceNames[spaceIndex]
        let cellIsFocused = spaceIndex == state.focusedIndex
        let cellIsDropTarget = spaceIndex == hoveredCell
        let cellWindows = state.windows(forSpace: spaceIndex)
        let cellDisplayBounds = state.displayBounds
        let cellStyle = state.config.cellStyle
        
        return CellView(
            spaceIndex: cellSpaceIndex,
            spaceLabel: cellSpaceLabel,
            spaceName: cellSpaceName,
            isFocused: cellIsFocused,
            isDropTarget: cellIsDropTarget,
            windows: cellWindows,
            displayBounds: cellDisplayBounds,
            cellStyle: cellStyle,
            onSelect: onSelect,
            uiScale: uiScale,
            theme: theme,
            mode: state.config.mode,
            iconScale: state.config.iconScale,
            showNames: state.config.showNames
        )
    }
    
    var effectiveCellWidth: CGFloat { baseCellWidth * uiScale * 10 }
    var effectiveCellHeight: CGFloat { baseCellHeight * uiScale * 10 }
    var effectiveGap: CGFloat { baseGap * uiScale * 10 }
    var effectivePadding: CGFloat { basePadding * uiScale * 10 }
    
    var idealSize: CGSize {
        let cells = visibleSpaceIndices
        let rowCount = Int((cells.count + state.config.cols - 1) / state.config.cols)
        let colCount = min(state.config.cols, cells.count)
        let w = CGFloat(colCount) * (effectiveCellWidth + effectiveGap) - effectiveGap + effectivePadding * 2
        let h = CGFloat(rowCount) * (effectiveCellHeight + effectiveGap) - effectiveGap + effectivePadding * 2
        return CGSize(width: w, height: h)
    }
    
    private var backgroundColor: Color {
        let alpha = state.config.backgroundAlpha
        if !isDarkMode {
            return Color.white.opacity(alpha)
        } else {
            let t = AppTheme.named(theme)
            return Color(hex: t.background).opacity(alpha)
        }
    }
    
    init(state: GridState, hoveredCell: Int?, onSelect: @escaping (Int) -> Void, uiScale: Double = 1.0, theme: String = "default") {
        self.state = state
        self.hoveredCell = hoveredCell
        self.onSelect = onSelect
        self.uiScale = uiScale
        self.theme = theme
    }
}