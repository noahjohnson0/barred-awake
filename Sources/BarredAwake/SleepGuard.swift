import Foundation
import IOKit.pwr_mgt

/// Keeps the Mac awake. Two layers:
///  1. An IOPMAssertion that blocks idle system sleep (no admin needed).
///  2. `pmset disablesleep` so the machine stays awake even with the lid
///     shut (clamshell). That requires admin rights, so we ask once via an
///     authorization prompt.
final class SleepGuard {
    static let shared = SleepGuard()
    private var assertionID: IOPMAssertionID = 0
    private var assertionActive = false

    private(set) var isAwake = false

    /// Returns true on success. On failure (e.g. user cancels the admin
    /// prompt) it rolls back and returns false so the UI can stay in sync.
    @discardableResult
    func setAwake(_ awake: Bool) -> Bool {
        guard awake != isAwake else { return true }
        if awake {
            createAssertion()
            if !setLidSleepDisabled(true) {
                releaseAssertion()
                return false
            }
        } else {
            _ = setLidSleepDisabled(false)
            releaseAssertion()
        }
        isAwake = awake
        return true
    }

    // MARK: - Idle sleep assertion

    private func createAssertion() {
        guard !assertionActive else { return }
        let reason = "Barred Awake is keeping this Mac awake" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        assertionActive = (result == kIOReturnSuccess)
    }

    private func releaseAssertion() {
        guard assertionActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionActive = false
        assertionID = 0
    }

    // MARK: - Clamshell (lid-shut) sleep

    /// `pmset -a disablesleep <0|1>` needs admin, so run it through an
    /// authorization prompt. Returns false if it didn't apply.
    private func setLidSleepDisabled(_ disabled: Bool) -> Bool {
        let value = disabled ? "1" : "0"
        let source = "do shell script \"/usr/bin/pmset -a disablesleep \(value)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            NSLog("Barred Awake: pmset disablesleep failed: \(error)")
            return false
        }
        return true
    }
}
