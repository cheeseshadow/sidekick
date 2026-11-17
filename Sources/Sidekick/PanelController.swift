import AppKit
import SidekickCore
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    let panel: FloatingPanel

    private static let autosaveName = "SidekickPanel"
    private static let screenMargin: CGFloat = 16
    /// Longer than the longest row animation, so rows that fade out are not cut off by the shrinking window.
    private static let shrinkDelay: Duration = .milliseconds(900)

    private let store: TaskStore
    private let container: TopPinnedContainer
    private var contentHeight: CGFloat = 0
    private var shrinkTask: Task<Void, Never>?
    private var fadeBackTask: Task<Void, Never>?

    init(store: TaskStore) {
        self.store = store
        let width = CGFloat(SidekickConfig.defaultWindowWidth)
        let visibleFrame = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: 40))

        let hostingView = PanelHostingView(rootView: SidekickView(store: store) { _ in })
        hostingView.sizingOptions = []
        container = TopPinnedContainer(
            hostingView: hostingView,
            size: NSSize(width: width, height: Self.maxHeight(on: NSScreen.main))
        )
        super.init()

        hostingView.rootView = SidekickView(store: store) { [weak self] size in
            self?.contentSizeChanged(size)
        }
        hostingView.onHoverChange = { [weak self] isInside in
            self?.hoverChanged(isInside: isInside)
        }
        panel.contentView = container
        panel.delegate = self

        if !panel.setFrameUsingName(Self.autosaveName) {
            panel.setFrameTopLeftPoint(NSPoint(
                x: visibleFrame.maxX - width - Self.screenMargin,
                y: visibleFrame.maxY - Self.screenMargin
            ))
        }
        panel.setFrameAutosaveName(Self.autosaveName)
    }

    var isVisible: Bool {
        panel.isVisible
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        container.hostingHeight = Self.maxHeight(on: panel.screen)
        updateHeight()
    }

    /// Past this height the window cuts off the bottom rows. A list that long has stopped being a working list.
    private static func maxHeight(on screen: NSScreen?) -> CGFloat {
        ((screen ?? NSScreen.main ?? NSScreen.screens[0]).visibleFrame.height / 2).rounded()
    }

    private func contentSizeChanged(_ size: CGSize) {
        contentHeight = size.height
        let width = ceil(size.width)
        if width != panel.frame.width {
            setFrame(width: width, height: panel.frame.height)
        }
        updateHeight()
    }

    private func updateHeight() {
        let target = min(ceil(contentHeight), Self.maxHeight(on: panel.screen))
        shrinkTask?.cancel()
        if target >= panel.frame.height {
            setFrame(width: panel.frame.width, height: target)
            return
        }

        shrinkTask = Task { [weak self] in
            try? await Task.sleep(for: Self.shrinkDelay)
            guard !Task.isCancelled, let self else { return }

            setFrame(width: panel.frame.width, height: target)
        }
    }

    private func setFrame(width: CGFloat, height: CGFloat) {
        var frame = panel.frame
        let top = frame.maxY
        frame.size = NSSize(width: width, height: height)
        frame.origin.y = top - height
        panel.setFrame(frame, display: true)
        panel.invalidateShadow()
    }

    private func hoverChanged(isInside: Bool) {
        fadeBackTask?.cancel()
        if isInside {
            fade(to: store.hoverOpacity)
            return
        }

        let delay = store.hoverFadeBackDelay
        fadeBackTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }

            self?.fade(to: 1)
        }
    }

    private func fade(to opacity: Double) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = opacity
        }
    }
}
