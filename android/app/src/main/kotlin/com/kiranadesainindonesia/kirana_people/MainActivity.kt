package com.kiranadesainindonesia.kirana_people

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket
import java.security.MessageDigest

/**
 * Hosts the device integrity method channel (MASVS-RESILIENCE).
 *
 * NOTE: All checks here are client-side heuristics and can be bypassed by a
 * determined attacker. They raise the cost of casual tampering and provide
 * telemetry the backend should cross-check. Server-verified attestation
 * (Play Integrity) should replace/augment this once the app is on Play.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kiranadesainindonesia.kiranapeople/security"

    // Static device attributes cached once per process to keep integrity checks under <5ms
    @Volatile private var cachedSignature: String? = null
    @Volatile private var cachedEmulator: Boolean? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Legacy boolean API (kept for backward compatibility)
                "isDeviceCompromised" -> {
                    Thread {
                        val r = try { collectReport() } catch (_: Exception) { null }
                        runOnUiThread {
                            result.success(r == null || r["rooted"] == true || r["hooked"] == true)
                        }
                    }.start()
                }
                "getSecurityReport" -> {
                    Thread {
                        val report = try {
                            collectReport()
                        } catch (_: Exception) {
                            null
                        }
                        runOnUiThread {
                            if (report != null) result.success(report)
                            else result.error("CHECK_FAILED", "Integrity check failed", null)
                        }
                    }.start()
                }
                "isDeveloperMode" -> result.success(isDevModeEnabled(context))
                else -> result.notImplemented()
            }
        }
    }

    private fun collectReport(): Map<String, Any?> {
        val signals = mutableListOf<String>()

        val rooted = checkRoot(signals)
        val hooked = checkHooking(signals)
        val emulator = checkEmulator(signals)
        val debugger = Debug.isDebuggerConnected() || Debug.waitingForDebugger()
        if (debugger) signals.add("debugger_attached")
        val fakeGpsApps = hasAnyInstalledPackage(FAKE_GPS_PACKAGES)
        if (fakeGpsApps) signals.add("fake_gps_app_installed")
        val devMode = isDevModeEnabled(context)
        if (devMode) signals.add("developer_mode")

        return mapOf(
            "rooted" to rooted,
            "hooked" to hooked,
            "emulator" to emulator,
            "debugger" to debugger,
            "developerMode" to devMode,
            "fakeGpsAppInstalled" to fakeGpsApps,
            "appSignature" to getSigningCertSha256(),
            "signals" to signals
        )
    }

    // ---------------------------------------------------------------- Root

    private fun checkRoot(signals: MutableList<String>): Boolean {
        var rooted = false

        Build.TAGS?.let {
            if (it.contains("test-keys")) { signals.add("test_keys"); rooted = true }
        }

        val suPaths = arrayOf(
            "/system/app/Superuser.apk", "/sbin/su", "/system/bin/su", "/system/xbin/su",
            "/data/local/xbin/su", "/data/local/bin/su", "/system/sd/xbin/su",
            "/system/bin/failsafe/su", "/data/local/su", "/su/bin/su", "/system/xbin/daemonsu",
            "/system/bin/.ext/su", "/system/usr/we-need-root/su", "/cache/su", "/dev/su",
            "/data/adb/magisk", "/data/adb/ksu", "/data/adb/ap", "/sbin/.magisk",
            "/system/xbin/busybox", "/data/adb/modules"
        )
        if (suPaths.any { safeExists(it) }) { signals.add("su_binary"); rooted = true }

        // su anywhere on PATH
        System.getenv("PATH")?.split(":")?.let { dirs ->
            if (dirs.any { dir -> safeExists("$dir/su") }) {
                signals.add("su_on_path")
                rooted = true
            }
        }

        if (hasAnyInstalledPackage(ROOT_PACKAGES)) {
            signals.add("root_manager_app"); rooted = true
        }

        if (isSystemMountedRw()) { signals.add("system_rw"); rooted = true }

        return rooted
    }

    private fun isSystemMountedRw(): Boolean = try {
        File("/proc/mounts").useLines { lines ->
            lines.any { line ->
                val parts = line.split(" ")
                parts.size > 3 && (parts[1] == "/system" || parts[1] == "/") &&
                    parts[3].split(",").contains("rw") && parts[2] != "tmpfs" && parts[2] != "rootfs"
            }
        }
    } catch (_: Exception) { false }

    // ------------------------------------------------------------- Hooking

    private fun checkHooking(signals: MutableList<String>): Boolean {
        var hooked = false

        // Frida / Xposed / LSPosed / Substrate libraries mapped into our process.
        // Stream lines and only inspect file-backed mappings (lines containing '/') to stay fast.
        try {
            val markers = arrayOf("frida", "gum-js-loop", "gadget", "xposed", "lsposed", "edxp",
                "substrate", "riru", "zygisk")
            val foundInMaps = File("/proc/self/maps").useLines { lines ->
                lines.any { line ->
                    val slashIdx = line.indexOf('/')
                    if (slashIdx < 0) false
                    else {
                        val pathPart = line.substring(slashIdx)
                        markers.any { pathPart.contains(it, ignoreCase = true) }
                    }
                }
            }
            if (foundInMaps) {
                signals.add("hook_library_mapped"); hooked = true
            }
        } catch (_: Exception) {}

        // Xposed bridge class loaded
        try {
            Class.forName("de.robv.android.xposed.XposedBridge")
            signals.add("xposed_bridge"); hooked = true
        } catch (_: Throwable) {}

        // Default frida-server port on loopback (fast 20ms timeout on localhost)
        try {
            Socket().use { s ->
                s.connect(InetSocketAddress("127.0.0.1", 27042), 20)
                signals.add("frida_port_open"); hooked = true
            }
        } catch (_: Exception) {}

        if (hasAnyInstalledPackage(HOOK_PACKAGES)) {
            signals.add("hook_framework_app"); hooked = true
        }

        return hooked
    }

    // ------------------------------------------------------------ Emulator

    private fun checkEmulator(signals: MutableList<String>): Boolean {
        val emu = cachedEmulator ?: (
            Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.contains("emulator") ||
            Build.MODEL.contains("google_sdk") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for") ||
            Build.MANUFACTURER.contains("Genymotion") ||
            Build.HARDWARE.contains("goldfish") ||
            Build.HARDWARE.contains("ranchu") ||
            Build.PRODUCT.contains("sdk") ||
            Build.PRODUCT.contains("vbox") ||
            (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) ||
            safeExists("/dev/qemu_pipe") || safeExists("/dev/socket/qemud")
        ).also { cachedEmulator = it }
        if (emu) signals.add("emulator")
        return emu
    }

    // ------------------------------------------------------------- Helpers

    /** SHA-256 of the APK signing certificate, cached after first read. */
    private fun getSigningCertSha256(): String? {
        cachedSignature?.let { return it }
        return try {
            val pm = packageManager
            val sigs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = pm.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                info.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
            }
            sigs?.firstOrNull()?.toByteArray()?.let { bytes ->
                MessageDigest.getInstance("SHA-256").digest(bytes).joinToString(":") { "%02X".format(it) }
            }?.also { cachedSignature = it }
        } catch (_: Exception) { null }
    }

    /** Short-circuits on first found package instead of scanning the entire array. */
    private fun hasAnyInstalledPackage(candidates: Array<String>): Boolean {
        val pm = packageManager
        for (pkg in candidates) {
            try {
                pm.getPackageInfo(pkg, 0)
                return true
            } catch (_: Exception) {}
        }
        return false
    }

    private fun safeExists(path: String): Boolean = try { File(path).exists() } catch (_: Exception) { false }

    private fun isDevModeEnabled(context: Context): Boolean = try {
        Settings.Global.getInt(context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) != 0
    } catch (_: Exception) { false }

    companion object {
        // Must also be declared in AndroidManifest <queries> for Android 11+ visibility
        val ROOT_PACKAGES = arrayOf(
            "com.topjohnwu.magisk", "io.github.vvb2060.magisk", "io.github.huskydg.magisk",
            "me.weishu.kernelsu", "me.bmax.apatch", "eu.chainfire.supersu",
            "com.noshufou.android.su", "com.koushikdutta.superuser", "com.thirdparty.superuser",
            "com.yellowes.su", "com.kingroot.kinguser", "com.kingo.root"
        )
        val HOOK_PACKAGES = arrayOf(
            "de.robv.android.xposed.installer", "org.lsposed.manager", "io.github.lsposed.manager",
            "org.meowcat.edxposed.manager", "com.saurik.substrate", "com.devadvance.rootcloak",
            "com.devadvance.rootcloakplus", "com.formyhm.hideroot", "com.amphoras.hidemyroot"
        )
        val FAKE_GPS_PACKAGES = arrayOf(
            "com.lexa.fakegps", "com.incorporateapps.fakegps.fre", "com.blogspot.newapphorizons.fakegps",
            "com.theappninjas.fakegpsjoystick", "com.rosteam.gpsemulator", "com.evezzon.fakegps",
            "com.fakegps.mock", "com.gsmartstudio.fakegps", "com.hopefactory2021.fakegpslocation",
            "ru.gavrikov.mocklocations"
        )
    }
}
