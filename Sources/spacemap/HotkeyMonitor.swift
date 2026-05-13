import Cocoa

class HotkeyMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onTrigger: () -> Void
    private let targetKeyCode: CGKeyCode
    private let targetModifiers: CGEventFlags
    private var isStarted = false

    init(config: HotkeyConfig, onTrigger: @escaping () -> Void) {
        self.targetKeyCode = config.keyCode
        self.targetModifiers = config.modifiers
        self.onTrigger = onTrigger
    }

    func start() {
        guard !isStarted else { return }

        if !AXIsProcessTrusted() {
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self.start()
                }
            }
            return
        }

        isStarted = true
        createTap()
    }

    private func createTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()

                guard type == .keyDown else { return Unmanaged.passUnretained(event) }
                let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
                let flags = event.flags.intersection([.maskControl, .maskCommand,
                                                      .maskAlternate, .maskShift])

                if keyCode == monitor.targetKeyCode && flags == monitor.targetModifiers {
                    DispatchQueue.main.async { monitor.onTrigger() }
                    return nil
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap else {
            print("spacemap: CGEvent tap failed even though trusted — retrying")
            isStarted = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.start()
            }
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("spacemap: hotkey active")
    }
}
