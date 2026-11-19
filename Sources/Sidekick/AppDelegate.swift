import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = TaskStore()
    private var panelController: PanelController?
    private var statusItem: NSStatusItem?
    private let toggleItem = NSMenuItem(title: "Hide Window", action: #selector(toggleWindow), keyEquivalent: "")
    private let clickThroughItem = NSMenuItem(
        title: "Click Through",
        action: #selector(toggleClickThrough),
        keyEquivalent: ""
    )
    private let resetPositionItem = NSMenuItem(
        title: "Reset Position",
        action: #selector(resetPosition),
        keyEquivalent: ""
    )
    private let openItem = NSMenuItem(title: "Open Tasks File", action: #selector(openTasksFile), keyEquivalent: "")
    private let openConfigItem = NSMenuItem(
        title: "Open Config File",
        action: #selector(openConfigFile),
        keyEquivalent: ""
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panelController = PanelController(store: store)
        self.panelController = panelController
        store.start()
        panelController.show()

        statusItem = makeStatusItem()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        toggleItem.title = panelController?.isVisible == true ? "Hide Window" : "Show Window"
        clickThroughItem.state = panelController?.isClickThrough == true ? .on : .off
        openItem.isEnabled = store.tasksFileURL != nil
        openConfigItem.isEnabled = FileManager.default.fileExists(
            atPath: ConfigLoader.configURL.path(percentEncoded: false)
        )
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Sidekick")

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        toggleItem.target = self
        clickThroughItem.target = self
        resetPositionItem.target = self
        openItem.target = self
        openConfigItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(clickThroughItem)
        menu.addItem(resetPositionItem)
        menu.addItem(openItem)
        menu.addItem(openConfigItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Sidekick", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        return item
    }

    @objc private func toggleWindow() {
        guard let panelController else { return }

        if panelController.isVisible {
            panelController.hide()
        } else {
            panelController.show()
        }
    }

    @objc private func toggleClickThrough() {
        guard let panelController else { return }

        panelController.isClickThrough.toggle()
    }

    @objc private func resetPosition() {
        panelController?.resetPosition(on: statusItem?.button?.window?.screen)
    }

    @objc private func openTasksFile() {
        guard let url = store.tasksFileURL else { return }

        NSWorkspace.shared.open(url)
    }

    @objc private func openConfigFile() {
        NSWorkspace.shared.open(ConfigLoader.configURL)
    }
}
