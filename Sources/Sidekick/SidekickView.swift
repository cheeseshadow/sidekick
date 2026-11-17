import AppKit
import SidekickCore
import SwiftUI

struct SidekickView: View {
    let store: TaskStore
    let onSizeChange: (CGSize) -> Void

    @Namespace private var rows

    var body: some View {
        content
            .frame(width: store.windowWidth, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .background { WindowBackground() }
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { onSizeChange($0) }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .environment(\.palette, store.palette)
            .environment(\.typography, Typography(fontSize: store.fontSize))
    }

    @ViewBuilder private var content: some View {
        if let display = store.display {
            if display.isEmpty {
                MessageLine(text: "Nothing on the list")
            } else {
                taskGroups(display)
            }
        } else if case .message(let text) = store.content {
            MessageLine(text: text)
        }
    }

    private func taskGroups(_ display: TaskDisplay) -> some View {
        let footer = display.footer
        let hasCard = !display.inProgress.isEmpty
        let hasPlannedList = !display.planned.isEmpty || footer != nil

        return VStack(alignment: .leading, spacing: Metrics.groupSpacing) {
            if hasCard {
                InProgressCard(rows: display.inProgress, namespace: rows)
                    .padding([.horizontal, .top], Metrics.cardInset)
                    .padding(.bottom, hasPlannedList ? 0 : Metrics.cardInset)
                    .transition(.opacity)
            }
            if hasPlannedList {
                PlannedList(rows: display.planned, footer: footer, namespace: rows)
                    .padding(.top, hasCard ? 0 : Metrics.listVerticalPadding)
                    .padding(.bottom, Metrics.listVerticalPadding)
                    .transition(.opacity)
            }
        }
    }
}

private struct InProgressCard: View {
    let rows: [TaskRow]
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.rowSpacing) {
            ForEach(rows) { row in
                TaskRowView(text: row.text, style: .inProgress, isCompleting: row.isCompleting)
                    .matchedRow(id: row.id, in: namespace, enabled: !reduceMotion)
                    .transition(rowTransition(reduceMotion: reduceMotion))
            }
        }
        .padding(.horizontal, Metrics.cardHorizontalPadding)
        .padding(.vertical, Metrics.cardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                .fill(palette.accent.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                .strokeBorder(palette.accent.opacity(0.22), lineWidth: 0.5)
        }
    }
}

private struct PlannedList: View {
    let rows: [TaskRow]
    let footer: String?
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.typography) private var typography

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.rowSpacing) {
            ForEach(rows) { row in
                TaskRowView(text: row.text, style: .planned, isCompleting: row.isCompleting)
                    .matchedRow(id: row.id, in: namespace, enabled: !reduceMotion)
                    .transition(rowTransition(reduceMotion: reduceMotion))
            }
            if let footer {
                Text(footer)
                    .font(.system(size: typography.footerSize).monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .contentTransition(.numericText())
                    .padding(.leading, typography.textIndent)
                    .padding(.top, rows.isEmpty ? 0 : 2)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Metrics.listLeadingPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MessageLine: View {
    let text: String

    @Environment(\.typography) private var typography

    var body: some View {
        Text(text)
            .font(.system(size: typography.fontSize))
            .foregroundStyle(.secondary)
            .lineSpacing(Metrics.lineSpacing)
            .lineLimit(3)
            .padding(Metrics.listLeadingPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WindowBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            BlurView()
            if let tint {
                tint.opacity(palette.backgroundTintOpacity)
            }
        }
    }

    private var tint: Color? {
        colorScheme == .dark ? palette.backgroundTintDark : palette.backgroundTintLight
    }
}

private struct BlurView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.maskImage = .roundedMask(radius: Metrics.cornerRadius)

        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private func rowTransition(reduceMotion: Bool) -> AnyTransition {
    if reduceMotion {
        return .opacity
    }

    return .asymmetric(insertion: .opacity.combined(with: .offset(y: -4)), removal: .opacity)
}

private extension View {
    @ViewBuilder
    func matchedRow(id: String, in namespace: Namespace.ID, enabled: Bool) -> some View {
        if enabled {
            matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}

private extension NSImage {
    static func roundedMask(radius: CGFloat) -> NSImage {
        let side = radius * 2 + 1
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch

        return image
    }
}
