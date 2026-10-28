import Flutter
import UIKit
import MachO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let securityChannelName = "com.kiranadesainindonesia.kiranapeople/security"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SecurityPlugin") else { return }
    let channel = FlutterMethodChannel(name: securityChannelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "CHECK_FAILED", message: "Integrity check unavailable", details: nil))
        return
      }
      switch call.method {
      case "isDeviceCompromised":
        let r = self.securityReport()
        result((r["rooted"] as? Bool ?? false) || (r["hooked"] as? Bool ?? false))
      case "getSecurityReport":
        result(self.securityReport())
      case "isDeveloperMode":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Device integrity (MASVS-RESILIENCE)
  // Client-side heuristics only; bypassable. Backend should cross-check and,
  // when available, verify App Attest assertions.

  private func securityReport() -> [String: Any] {
    var signals: [String] = []
    #if targetEnvironment(simulator)
    let rooted = false
    let hooked = false
    let emulator = true
    signals.append("emulator")
    #else
    let rooted = isJailbroken(&signals)
    let hooked = isHooked(&signals)
    let emulator = false
    #endif
    let debugger = isDebuggerAttached()
    if debugger { signals.append("debugger_attached") }
    return [
      "rooted": rooted,
      "hooked": hooked,
      "emulator": emulator,
      "debugger": debugger,
      "developerMode": false,
      "fakeGpsAppInstalled": false,
      "appSignature": NSNull(),
      "signals": signals,
    ]
  }

  private func isJailbroken(_ signals: inout [String]) -> Bool {
    var jb = false
    let suspiciousPaths = [
      // Classic (rootful) jailbreaks
      "/Applications/Cydia.app", "/Applications/Sileo.app", "/Applications/Zebra.app",
      "/Applications/Filza.app", "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash", "/usr/sbin/sshd", "/etc/apt", "/private/var/lib/apt/",
      "/usr/bin/ssh", "/usr/libexec/sftp-server", "/private/var/stash",
      // Rootless jailbreaks (Dopamine, palera1n)
      "/var/jb", "/private/preboot/jb", "/var/binpack", "/var/LIB",
      "/var/jb/usr/bin/su", "/var/jb/Applications/Sileo.app",
      // TrollStore
      "/var/containers/Bundle/Application/TrollStore.app",
    ]
    for path in suspiciousPaths where FileManager.default.fileExists(atPath: path) {
      signals.append("jb_path"); jb = true; break
    }

    // Sandbox integrity: apps must not be able to write outside their container
    let testPath = "/private/jailbreak_test_\(UUID().uuidString).txt"
    if (try? "x".write(toFile: testPath, atomically: true, encoding: .utf8)) != nil {
      try? FileManager.default.removeItem(atPath: testPath)
      signals.append("sandbox_writable"); jb = true
    }

    // Symlinked system dirs are a common jailbreak artifact
    for dir in ["/Applications", "/Library/Ringtones", "/usr/arm-apple-darwin9", "/usr/include"] {
      if let attrs = try? FileManager.default.attributesOfItem(atPath: dir),
         attrs[.type] as? FileAttributeType == .typeSymbolicLink {
        signals.append("symlinked_system_dir"); jb = true; break
      }
    }

    if getenv("DYLD_INSERT_LIBRARIES") != nil {
      signals.append("dyld_insert"); jb = true
    }
    return jb
  }

  private func isHooked(_ signals: inout [String]) -> Bool {
    let markers = ["frida", "fridagadget", "cynject", "libcycript", "mobilesubstrate",
                   "substrate", "substitute", "libhooker", "tweakinject", "ellekit",
                   "systemhook", "sslkillswitch", "rocketbootstrap"]
    for i in 0..<_dyld_image_count() {
      guard let cName = _dyld_get_image_name(i) else { continue }
      let name = String(cString: cName).lowercased()
      if markers.contains(where: { name.contains($0) }) {
        signals.append("hook_library_loaded")
        return true
      }
    }
    return false
  }

  private func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let rc = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    return rc == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
  }
}
