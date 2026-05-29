import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let keepAwakeKey = "keepAwakeEnabled"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Restore the previous "keep awake" preference.
        if UserDefaults.standard.bool(forKey: keepAwakeKey) {
            if !SleepGuard.shared.setAwake(true) {
                UserDefaults.standard.set(false, forKey: keepAwakeKey)
            }
        }

        refreshIcon()
        buildMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Be a good citizen: drop the clamshell override on quit.
        SleepGuard.shared.setAwake(false)
    }

    // MARK: - UI

    private func refreshIcon() {
        statusItem.button?.image = OwlIcon.image(awake: SleepGuard.shared.isAwake)
        statusItem.button?.toolTip = SleepGuard.shared.isAwake
            ? "Barred Awake — keeping your Mac awake"
            : "Barred Awake — sleeping normally"
    }

    private func buildMenu() {
        let menu = NSMenu()

        let awakeItem = NSMenuItem(
            title: "Keep Awake (even with lid shut)",
            action: #selector(toggleKeepAwake),
            keyEquivalent: ""
        )
        awakeItem.target = self
        awakeItem.state = SleepGuard.shared.isAwake ? .on : .off
        menu.addItem(awakeItem)

        let bootItem = NSMenuItem(
            title: "Start on Boot",
            action: #selector(toggleStartOnBoot),
            keyEquivalent: ""
        )
        bootItem.target = self
        bootItem.state = isLoginItemEnabled ? .on : .off
        menu.addItem(bootItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Barred Awake",
                              action: #selector(NSApplication.terminate(_:)),
                              keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Keep awake

    @objc private func toggleKeepAwake() {
        let target = !SleepGuard.shared.isAwake
        if SleepGuard.shared.setAwake(target) {
            UserDefaults.standard.set(target, forKey: keepAwakeKey)
        }
        refreshIcon()
        buildMenu()
    }

    // MARK: - Start on boot

    private var isLoginItemEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @objc private func toggleStartOnBoot() {
        do {
            if isLoginItemEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Barred Awake: login item toggle failed: \(error)")
        }
        buildMenu()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Menu-bar only — no Dock icon, no main window.
app.setActivationPolicy(.accessory)
app.run()
