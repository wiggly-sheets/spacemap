import SwiftUI

struct CellView: View {
    let spaceIndex: Int
    let isFocused: Bool
    let windows: [YabaiWindow]
    let displayBounds: CGRect

    private let cellSize = CGSize(width: 80, height: 50)

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isFocused ? Color(hex: 0x4a9eff).opacity(0.35) : Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isFocused ? Color(hex: 0x4a9eff) : Color.white.opacity(0.15), lineWidth: isFocused ? 1.5 : 0.5)
                )

            ForEach(windows, id: \.id) { window in
                windowRect(window)
            }

            Text("\(spaceIndex)")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(isFocused ? Color(hex: 0x4a9eff) : .white.opacity(0.4))
                .padding(3)
        }
        .frame(width: cellSize.width, height: cellSize.height)
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
