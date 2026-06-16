package com.example.deepsky_bluetooth_android

import android.content.Context
import com.example.deepsky_bluetooth_android.core.ForegroundServiceState
import com.example.deepsky_bluetooth_android.core.HeadlessLifecycleState
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.view.FlutterCallbackInformation

/**
 * Revives Dart in a headless [FlutterEngine] by running the app's dedicated
 * `@pragma('vm:entry-point')` background entry point (callback handle persisted in
 * [android.content.SharedPreferences]). **`main()`/`runApp()` are never executed** to avoid
 * Activity-dependent plugin crashes and double-`runApp` races (Review guide §12).
 *
 * Trigger points:
 * - [DeepskyCompanionDeviceService] device events (system start after process death).
 * - UI engine loss while the Foreground Service runs (task swipe etc.).
 *
 * The native BLE state lives in the process-global [BleProcessOwner] and is not tied to any engine.
 * When a UI engine attaches, the headless engine is destroyed only after the sink-handover ack
 * (mechanism here; trigger in #29). All start/destroy decisions are delegated to the JVM-tested
 * [HeadlessLifecycleState]; this object is the thin framework shell.
 */
object HeadlessEngineLauncher {
    private const val PREFS = "deepsky_bluetooth"
    private const val KEY_BG_HANDLE = "background_relaunch_handle"
    private const val NO_HANDLE = -1L

    private var headlessEngine: FlutterEngine? = null

    /** Persist the background relaunch handle so it survives process death. */
    fun storeBackgroundHandle(context: Context, handle: Long) {
        prefs(context).edit().putLong(KEY_BG_HANDLE, handle).apply()
    }

    /**
     * Create a headless engine if the lifecycle state allows it. No-op when a UI/headless engine is
     * already active. When no handle is registered, warns via the observer and does not start
     * (the user relies on UI return to reconnect instead).
     */
    @Synchronized
    fun ensureEngine(context: Context) {
        val handle = prefs(context).getLong(KEY_BG_HANDLE, NO_HANDLE)
        if (!HeadlessLifecycleState.shouldStartHeadless(handleRegistered = handle != NO_HANDLE)) {
            if (handle == NO_HANDLE) {
                BleNativeObservers.emitCallback(
                    "headless.relaunchSkipped", mapOf("reason" to "noBackgroundHandle"))
            }
            return
        }
        val appContext = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(appContext)
            loader.ensureInitializationComplete(appContext, null)
        }
        val callback = FlutterCallbackInformation.lookupCallbackInformation(handle)
        if (callback == null) {
            BleNativeObservers.emitCallback(
                "headless.relaunchSkipped", mapOf("reason" to "callbackLookupFailed"))
            return
        }
        val engine = FlutterEngine(appContext)
        // Run the dedicated background entry point only — never main()/runApp().
        engine.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(appContext.assets, loader.findAppBundlePath(), callback))
        headlessEngine = engine
        HeadlessLifecycleState.onHeadlessStarted()
    }

    /** A UI engine attached to an Activity. Keep the headless engine until the handover ack. */
    fun onUiEngineCandidateAttached() {
        HeadlessLifecycleState.onUiEngineCandidateAttached()
    }

    /** Owner verified the UI sink-handover ack. Destroy the now-redundant headless engine (#29). */
    @Synchronized
    fun onUiHandoverAcknowledged() {
        if (HeadlessLifecycleState.onUiHandoverAcknowledged()) {
            headlessEngine?.destroy()
            headlessEngine = null
        }
    }

    /**
     * An engine detached. The headless engine's own detach just clears state; a UI engine loss
     * relaunches headless when the Foreground Service is still running.
     */
    @Synchronized
    fun onEngineDetached(context: Context, isHeadless: Boolean) {
        val handleRegistered = prefs(context).getLong(KEY_BG_HANDLE, NO_HANDLE) != NO_HANDLE
        if (isHeadless) headlessEngine = null
        val relaunch = HeadlessLifecycleState.onEngineDetached(
            isHeadless = isHeadless,
            fgsRunning = ForegroundServiceState.isRunning,
            handleRegistered = handleRegistered,
        )
        if (relaunch) ensureEngine(context)
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
