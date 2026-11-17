import AppKit
import SwiftUI

enum RowStyle {
    case inProgress
    case planned

    var fontWeight: NSFont.Weight {
        self == .inProgress ? .medium : .regular
    }

    var textStyle: HierarchicalShapeStyle {
        self == .inProgress ? .primary : .secondary
    }
}

struct TaskRowView: View {
    let text: String
    let style: RowStyle
    let isCompleting: Bool

    @Environment(\.palette) private var palette
    @Environment(\.typography) private var typography
    @State private var fill: CGFloat = 0
    @State private var check: CGFloat = 0
    @State private var strike: CGFloat = 0

    var body: some View {
        let font = typography.font(weight: style.fontWeight)

        HStack(alignment: .top, spacing: Metrics.markerSpacing) {
            MarkerView(style: style, fill: fill, check: check)
                .frame(width: typography.markerWidth, height: ceil(font.ascender - font.descender + font.leading))
            label(font: Font(font as CTFont))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            if isCompleting {
                playCompletion()
            }
        }
        .onChange(of: isCompleting) { _, isCompleting in
            if isCompleting {
                playCompletion()
            }
        }
    }

    @ViewBuilder private func label(font: Font) -> some View {
        let markdown = InlineMarkdown.render(text, linkColor: palette.accent)
        if isCompleting {
            ZStack(alignment: .topLeading) {
                styledText(markdown, font: font)
                    .foregroundStyle(style.textStyle)
                    .mask(alignment: .trailing) { RevealMask(fraction: 1 - strike, edge: .trailing) }
                styledText(markdown, font: font)
                    .strikethrough()
                    .foregroundStyle(.tertiary)
                    .mask(alignment: .leading) { RevealMask(fraction: strike, edge: .leading) }
            }
        } else {
            styledText(markdown, font: font)
                .foregroundStyle(style.textStyle)
                .contentTransition(.opacity)
        }
    }

    private func styledText(_ markdown: AttributedString, font: Font) -> some View {
        Text(markdown)
            .font(font)
            .lineSpacing(Metrics.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func playCompletion() {
        withAnimation(.easeOut(duration: 0.15)) {
            fill = 1
        }
        withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
            check = 1
        }
        withAnimation(.easeInOut(duration: 0.25).delay(0.3)) {
            strike = 1
        }
    }
}

private struct RevealMask: View {
    let fraction: CGFloat
    let edge: HorizontalEdge

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .frame(width: proxy.size.width * fraction)
                .frame(maxWidth: .infinity, alignment: edge == .leading ? .leading : .trailing)
        }
    }
}

struct MarkerView: View {
    let style: RowStyle
    let fill: CGFloat
    let check: CGFloat

    @Environment(\.palette) private var palette
    @Environment(\.typography) private var typography

    var body: some View {
        ZStack {
            switch style {
            case .inProgress:
                Circle()
                    .fill(palette.accent)
                    .frame(width: typography.inProgressDotSize, height: typography.inProgressDotSize)
            case .planned:
                Circle()
                    .strokeBorder(.tertiary, lineWidth: 1.2)
                    .frame(width: typography.plannedRingSize, height: typography.plannedRingSize)
            }
            Circle()
                .fill(palette.accent)
                .frame(width: typography.completionDotSize, height: typography.completionDotSize)
                .scaleEffect(0.6 + 0.4 * fill)
                .opacity(fill)
            CheckmarkShape()
                .trim(from: 0, to: check)
                .stroke(.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: typography.checkmarkSize.width, height: typography.checkmarkSize.height)
        }
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        return path
    }
}

enum InlineMarkdown {
    static func render(_ text: String, linkColor: Color) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        var result = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        let linkRanges = result.runs.compactMap { $0.link == nil ? nil : $0.range }
        for range in linkRanges {
            result[range].link = nil
            result[range][AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = linkColor
        }

        return result
    }
}
