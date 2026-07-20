import SwiftUI
import AppKit

struct CellView: View {
    let spaceIndex: Int
    let spaceLabel: String?
    let spaceName: String? // config-based name
    let isFocused: Bool
    let isDropTarget: Bool
    let isActive: Bool
    let windows: [YabaiWindow]
    let displayBounds: CGRect
    let cellStyle: CellStyle
    let onSelect: (Int) -> Void
    
    // These values will be passed from GridView
    private let baseCellWidth: CGFloat = 80
    private let baseCellHeight: CGFloat = 50
    private let uiScale: CGFloat
    private let theme: String
    private let mode: ThemeMode
    private let iconScale: CGFloat
    private let showSpaceNumbers: Bool
    private let showSpaceNames: Bool
    
    private var isDarkMode: Bool {
        switch mode {
        case .light: return false
        case .dark:  return true
        case .auto:  return NSApp.effectiveAppearance.name == .darkAqua
        }
    }
    
    private var cellSize: CGSize {
        CGSize(width: baseCellWidth * uiScale * 10, height: baseCellHeight * uiScale * 10)
    }
    
init(spaceIndex: Int,
            spaceLabel: String? = nil,
            spaceName: String? = nil,
            isFocused: Bool,
             isActive: Bool,
             windows: [YabaiWindow],
             displayBounds: CGRect,
             cellStyle: CellStyle,
             onSelect: @escaping (Int) -> Void,
             uiScale: CGFloat = 1.0,
             theme: String = "default",
             mode: ThemeMode = .auto,
             iconScale: CGFloat = 1.0,
             showSpaceNumbers: Bool = true,
             showSpaceNames: Bool = true) {
        self.spaceIndex = spaceIndex
        self.spaceLabel = spaceLabel
        self.spaceName = spaceName
        self.isFocused = isFocused
        self.isDropTarget = isDropTarget
        self.isActive = isActive
        self.windows = windows
        self.displayBounds = displayBounds
        self.cellStyle = cellStyle
        self.onSelect = onSelect
        self.uiScale = uiScale
        self.theme = theme
        self.mode = mode
        self.iconScale = iconScale
        self.showNames = showNames
    }
    
var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)

            ForEach(windows, id: \.id) { window in
                switch cellStyle {
                case .rects:  windowRect(window)
                case .icons:  windowIcon(window)
                case .hybrid: windowRect(window)
                }
            }

            if cellStyle == .icons || cellStyle == .hybrid {
                iconStrip()
            }

            // Show space number at top-left when showNames is enabled
            if showNames {
                Text("\(spaceIndex)")
                    .font(.system(size: 12 * uiScale * 10, weight: .bold))
                    .foregroundColor(textColor.opacity(0.7))
                    .position(x: 8, y: 12)
            }

            // Show space name (if exists) in center
            if let name = spaceName, !name.isEmpty {
                Text(name)
                    .font(.system(size: 14 * uiScale * 10, weight: .medium))
                    .foregroundColor(textColor)
                    .position(x: cellSize.width / 2, y: cellSize.height / 2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        .frame(width: cellSize.width, height: cellSize.height)
        .onTapGesture { onSelect(spaceIndex) }
    }
    
    private var backgroundColor: Color {
        let t = AppTheme.named(theme)
        let baseColor: Color
        if isDropTarget { baseColor = Color(hex: t.dropTarget).opacity(isDarkMode ? 0.35 : 0.5) }
        else if isFocused {
            if isDarkMode { baseColor = Color(hex: t.cellBgFocused).opacity(0.55) }
            else { baseColor = Color(hex: t.focused).opacity(0.2) }
        }
        else if isDarkMode { baseColor = Color(hex: t.cellBg).opacity(0.25) }
        else { baseColor = Color.white.opacity(0.8) }
        
        if !isActive { return baseColor.opacity(0.35) }
        return baseColor
    }
    
    private var textColor: Color {
        let t = AppTheme.named(theme)
        if isFocused { return Color(hex: t.focused) }
        if isDarkMode { return Color(hex: t.text).opacity(0.4) }
        return Color(hex: 0x333333).opacity(0.7)
    }
    
    private var borderColor: Color {
        let t = AppTheme.named(theme)
        if isDropTarget { return Color(hex: t.dropTarget) }
        if isFocused { return Color(hex: t.focused) }
        if isDarkMode { return Color(hex: t.text).opacity(0.15) }
        return Color(hex: 0x999999).opacity(0.3)
    }
    
    private var borderWidth: CGFloat {
        isDropTarget || isFocused ? 2.5 : 0.5
    }
    
    @ViewBuilder
    private func windowRect(_ window: YabaiWindow) -> some View {
        let scaleX = cellSize.width / displayBounds.width
        let scaleY = cellSize.height / displayBounds.height
        let x = (window.cgFrame.minX - displayBounds.minX) * scaleX
        let y = (window.cgFrame.minY - displayBounds.minY) * scaleY
        let w = max(window.cgFrame.width * scaleX, 2)
        let h = max(window.cgFrame.height * scaleY, 2)
        
        RoundedRectangle(cornerRadius: 1)
            .fill(appColor(window.app).opacity(0.6))
            .frame(width: w, height: h)
            .offset(x: x, y: y)
    }
    
    @ViewBuilder
    private func windowIcon(_ window: YabaiWindow) -> some View {
        if !window.isHidden && !window.isMinimized {
            let scaleX = cellSize.width / displayBounds.width
            let scaleY = cellSize.height / displayBounds.height
            let x = (window.cgFrame.minX - displayBounds.minX) * scaleX
            let y = (window.cgFrame.minY - displayBounds.minY) * scaleY
            let w = max(window.cgFrame.width * scaleX, 14)
            let h = max(window.cgFrame.height * scaleY, 14)
            let iconSize = min(w, h)
            
            if let icon = appIcon(for: window.app) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .offset(x: x, y: y)
            }
        }
    }
    
    @ViewBuilder
    private func iconStrip() -> some View {
        let icons = uniqueIconWindows()
        let ic = iconScale
        HStack(spacing: 2 * uiScale * 10 * ic * 2) {
            ForEach(icons, id: \.id) { window in
                if let icon = appIcon(for: window.app) {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12 * uiScale * 10 * ic * 2, height: 12 * uiScale * 10 * ic * 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 3 * uiScale * 10 * ic * 2)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 3 * uiScale * 10 * ic * 2)
    }
    
    private func uniqueIconWindows() -> [YabaiWindow] {
        var seen = Set<String>()
        return windows.filter { seen.insert($0.app).inserted }
    }
    
    private func appIcon(for appName: String) -> NSImage? {
        NSWorkspace.shared.runningApplications
            .first { $0.localizedName == appName }
            .flatMap { $0.bundleURL }
            .map { NSWorkspace.shared.icon(forFile: $0.path) }
    }
    
    private func appColor(_ name: String) -> Color {
        let hue = Double(abs(name.hashValue) % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
