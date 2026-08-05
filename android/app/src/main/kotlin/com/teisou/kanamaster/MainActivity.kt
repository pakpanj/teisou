package com.teisou.kanamaster

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Adds one platform channel: turning `FLAG_SECURE` on and off, so the gate
 * quiz a learner has to pass to unlock the next chapter cannot be captured.
 *
 * Written by hand rather than pulled in as a plugin on purpose. This needs
 * two lines of Android API, while every native dependency this project has
 * added cost it an R8 keep-rule hunt or a `compileOnly` surprise (see
 * CLAUDE.md's "Verifying changes"). No AAR, no reflection, nothing for the
 * shrinker to strip.
 *
 * `FLAG_SECURE` is a window flag, so while it is set it also blocks screen
 * recording and blanks the app's thumbnail in the recents switcher. That is
 * the intended reach, not a side effect to work around.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "teisou/secure_screen"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
