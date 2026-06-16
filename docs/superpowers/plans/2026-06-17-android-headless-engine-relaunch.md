# Android Headless Engine Relaunch (Issue #28) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Revive Dart in a headless `FlutterEngine` from a persisted `@pragma('vm:entry-point')` callback handle (never `main()`/`runApp()`), with a JVM-tested lifecycle state machine.

**Architecture:** A pure `core/HeadlessLifecycleState` object owns every start/destroy decision and is fully JVM-tested (the "launcher lifecycle test"). A thin `HeadlessEngineLauncher` shell does `SharedPreferences` persistence + `FlutterEngine` create/destroy, delegating decisions to the state machine. Wired into `BleCentralManager.initialize` (persist handle + accept `COMPANION_DEVICE`), `DeepskyCompanionDeviceService` (relaunch trigger), and the plugin (UI-vs-headless lifecycle).

**Tech Stack:** Kotlin, Flutter Android embedding v2 (`FlutterEngine`, `FlutterCallbackInformation`, `DartExecutor.DartCallback`, `FlutterLoader`), `SharedPreferences`, kotlin.test/JUnit5.

**Spec:** `docs/superpowers/specs/2026-06-17-android-headless-engine-relaunch-design.md`

**Test command** (from `plugins/deepsky_bluetooth_android/example/android`, with `JAVA_HOME` = Android Studio JBR):
`./gradlew :deepsky_bluetooth_android:testDebugUnitTest`

---

### Task 1: `HeadlessLifecycleState` pure state machine

**Files:**
- Create: `plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/core/HeadlessLifecycleState.kt`
- Test: `plugins/deepsky_bluetooth_android/android/src/test/kotlin/com/example/deepsky_bluetooth_android/core/HeadlessLifecycleStateTest.kt`

- [ ] **Step 1: Write the failing test**

```kotlin
package com.example.deepsky_bluetooth_android.core

import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class HeadlessLifecycleStateTest {
    @AfterTest
    fun tearDown() = HeadlessLifecycleState.resetForTest()

    @Test
    fun shouldNotStartWhenHandleUnregistered() {
        assertFalse(HeadlessLifecycleState.shouldStartHeadless(handleRegistered = false))
    }

    @Test
    fun startsWhenRegisteredAndNoEngine() {
        assertTrue(HeadlessLifecycleState.shouldStartHeadless(handleRegistered = true))
    }

    @Test
    fun doesNotStartTwiceAfterHeadlessStarted() {
        HeadlessLifecycleState.onHeadlessStarted()
        assertFalse(HeadlessLifecycleState.shouldStartHeadless(handleRegistered = true))
    }

    @Test
    fun doesNotStartWhenUiEnginePresent() {
        HeadlessLifecycleState.onUiEngineCandidateAttached()
        assertFalse(HeadlessLifecycleState.shouldStartHeadless(handleRegistered = true))
    }

    @Test
    fun ackDestroysOnlyWhenHeadlessAlive() {
        assertFalse(HeadlessLifecycleState.onUiHandoverAcknowledged())
        HeadlessLifecycleState.onHeadlessStarted()
        assertTrue(HeadlessLifecycleState.onUiHandoverAcknowledged())
        assertFalse(HeadlessLifecycleState.isHeadlessAlive)
    }

    @Test
    fun headlessDetachClearsAliveAndNeverRelaunches() {
        HeadlessLifecycleState.onHeadlessStarted()
        val relaunch = HeadlessLifecycleState.onEngineDetached(
            isHeadless = true, fgsRunning = true, handleRegistered = true)
        assertFalse(relaunch)
        assertFalse(HeadlessLifecycleState.isHeadlessAlive)
    }

    @Test
    fun uiDetachRelaunchesOnlyWhenFgsRunningAndRegisteredAndNoHeadless() {
        HeadlessLifecycleState.onUiEngineCandidateAttached()
        // fgs off -> no relaunch
        assertFalse(HeadlessLifecycleState.onEngineDetached(false, fgsRunning = false, handleRegistered = true))
        HeadlessLifecycleState.onUiEngineCandidateAttached()
        // handle unregistered -> no relaunch
        assertFalse(HeadlessLifecycleState.onEngineDetached(false, fgsRunning = true, handleRegistered = false))
        HeadlessLifecycleState.onUiEngineCandidateAttached()
        // all conditions met -> relaunch
        assertTrue(HeadlessLifecycleState.onEngineDetached(false, fgsRunning = true, handleRegistered = true))
        assertFalse(HeadlessLifecycleState.hasUiEngine)
    }

    @Test
    fun uiDetachDoesNotRelaunchWhenHeadlessAlreadyAlive() {
        HeadlessLifecycleState.onHeadlessStarted()
        HeadlessLifecycleState.onUiEngineCandidateAttached()
        assertFalse(HeadlessLifecycleState.onEngineDetached(false, fgsRunning = true, handleRegistered = true))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./gradlew :deepsky_bluetooth_android:testDebugUnitTest --tests "*HeadlessLifecycleStateTest"`
Expected: FAIL — `HeadlessLifecycleState` unresolved reference (compilation error).

- [ ] **Step 3: Write minimal implementation**

```kotlin
package com.example.deepsky_bluetooth_android.core

/**
 * Process-wide headless `FlutterEngine` lifecycle state machine.
 *
 * Owns every start/destroy *decision* so `HeadlessEngineLauncher` stays a thin framework shell.
 * Two flags: a UI (Activity-attached) engine is present, and a headless engine is alive.
 * A headless engine must never be started while a UI engine is present or another headless engine
 * is alive, and must survive UI attach until the sink-handover ack (Review guide §12). Framework
 * independent so all transitions are JVM-testable (Review guide §16).
 */
internal object HeadlessLifecycleState {
    @Volatile
    private var snapshot = Snapshot()

    val hasUiEngine: Boolean
        get() = snapshot.hasUiEngine

    val isHeadlessAlive: Boolean
        get() = snapshot.headlessAlive

    /**
     * Whether `ensureEngine` should create a headless engine now. False unless a background handle
     * is registered and no engine of any kind is active.
     */
    @Synchronized
    fun shouldStartHeadless(handleRegistered: Boolean): Boolean =
        handleRegistered && !snapshot.hasUiEngine && !snapshot.headlessAlive

    /** Record that a headless engine was actually created. */
    @Synchronized
    fun onHeadlessStarted() {
        snapshot = snapshot.copy(headlessAlive = true)
    }

    /** A UI engine attached to an Activity. Headless must not be destroyed yet (only after ack). */
    @Synchronized
    fun onUiEngineCandidateAttached() {
        snapshot = snapshot.copy(hasUiEngine = true)
    }

    /**
     * UI sink-handover acknowledged. Returns true (and clears the flag) only when a headless engine
     * is alive and must now be destroyed. The trigger is wired in #29.
     */
    @Synchronized
    fun onUiHandoverAcknowledged(): Boolean {
        if (!snapshot.headlessAlive) return false
        snapshot = snapshot.copy(headlessAlive = false)
        return true
    }

    /**
     * An engine detached. Headless detach just clears the alive flag. UI detach clears the UI flag
     * and returns whether headless relaunch is required (FGS running, handle registered, and no
     * headless already alive).
     */
    @Synchronized
    fun onEngineDetached(isHeadless: Boolean, fgsRunning: Boolean, handleRegistered: Boolean): Boolean {
        if (isHeadless) {
            snapshot = snapshot.copy(headlessAlive = false)
            return false
        }
        snapshot = snapshot.copy(hasUiEngine = false)
        return fgsRunning && handleRegistered && !snapshot.headlessAlive
    }

    @Synchronized
    fun resetForTest() {
        snapshot = Snapshot()
    }

    private data class Snapshot(
        val hasUiEngine: Boolean = false,
        val headlessAlive: Boolean = false,
    )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./gradlew :deepsky_bluetooth_android:testDebugUnitTest --tests "*HeadlessLifecycleStateTest"`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/core/HeadlessLifecycleState.kt plugins/deepsky_bluetooth_android/android/src/test/kotlin/com/example/deepsky_bluetooth_android/core/HeadlessLifecycleStateTest.kt
git commit -m "feat(android): headless engine lifecycle state machine (#28)"
```

---

### Task 2: `HeadlessEngineLauncher` framework shell

**Files:**
- Create: `plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/HeadlessEngineLauncher.kt`

No new JVM test: this layer only touches `FlutterEngine` / `SharedPreferences` / `FlutterLoader` (framework, verified on device per §16). All decision logic is in `HeadlessLifecycleState` (Task 1).

- [ ] **Step 1: Write the implementation**

```kotlin
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
        val handleRegistered =
            prefs(context).getLong(KEY_BG_HANDLE, NO_HANDLE) != NO_HANDLE
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
```

- [ ] **Step 2: Verify it compiles via the existing test build**

Run: `./gradlew :deepsky_bluetooth_android:testDebugUnitTest`
Expected: BUILD SUCCESSFUL (no new tests; confirms the shell compiles against the embedding APIs).

- [ ] **Step 3: Commit**

```bash
git add plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/HeadlessEngineLauncher.kt
git commit -m "feat(android): headless engine launcher shell (#28)"
```

---

### Task 3: Wire relaunch trigger into `DeepskyCompanionDeviceService`

**Files:**
- Modify: `plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/DeepskyCompanionDeviceService.kt`

- [ ] **Step 1: Add `ensureEngine` after each `ensureAttached`**

In each of the 6 callbacks, immediately after `BleProcessOwner.ensureAttached(applicationContext)` add:

```kotlin
        HeadlessEngineLauncher.ensureEngine(applicationContext)
```

So e.g. the 31-32 appeared path becomes:

```kotlin
    @Deprecated("Deprecated in API 33; superseded by onDeviceAppeared(AssociationInfo)")
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onDeviceAppeared(address: String) {
        BleProcessOwner.ensureAttached(applicationContext)
        HeadlessEngineLauncher.ensureEngine(applicationContext)
        BleProcessOwner.onCompanionDeviceAppeared(address)
    }
```

Apply the same insertion to `onDeviceDisappeared(String)`, `onDeviceAppeared(AssociationInfo)`,
`onDeviceDisappeared(AssociationInfo)`, and `onDevicePresenceEvent(DevicePresenceEvent)`.

Also update the class KDoc: replace the `#27`/`#29` deferral note with a line stating the service
revives the headless engine via [HeadlessEngineLauncher] before delivering the event (#28).

- [ ] **Step 2: Verify it compiles**

Run: `./gradlew :deepsky_bluetooth_android:testDebugUnitTest`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/DeepskyCompanionDeviceService.kt
git commit -m "feat(android): relaunch headless engine from companion device service (#28)"
```

---

### Task 4: Wire UI-vs-headless lifecycle into the plugin

**Files:**
- Modify: `plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/DeepskyBluetoothAndroidPlugin.kt`

- [ ] **Step 1: Track UI engine and report detach**

Add a field next to the existing `callbacks`/`activityBinding`:

```kotlin
    // Whether this engine's plugin instance ever attached to an Activity. A headless relaunch
    // engine never does, so this distinguishes UI vs headless engines on detach (#28).
    private var wasUiEngine = false
    private var appContext: Context? = null
```

In `onAttachedToEngine`, capture the context (inside the existing `observeMethod` block, after
`BleProcessOwner.attach`):

```kotlin
            appContext = binding.applicationContext
```

In `onDetachedFromEngine`, after clearing `callbacks`, report the detach (still inside the
`observeMethod` block):

```kotlin
            appContext?.let { HeadlessEngineLauncher.onEngineDetached(it, isHeadless = !wasUiEngine) }
```

In `bindActivity`, after `BleProcessOwner.setActivity(binding.activity)`, mark this as a UI engine:

```kotlin
            wasUiEngine = true
            HeadlessEngineLauncher.onUiEngineCandidateAttached()
```

Add the import at the top if not present:

```kotlin
import android.content.Context
```

- [ ] **Step 2: Verify it compiles**

Run: `./gradlew :deepsky_bluetooth_android:testDebugUnitTest`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/DeepskyBluetoothAndroidPlugin.kt
git commit -m "feat(android): wire headless lifecycle into plugin attach/detach (#28)"
```

---

### Task 5: Persist handle and accept `COMPANION_DEVICE` in `initialize`

**Files:**
- Modify: `plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/BleCentralManager.kt`

- [ ] **Step 1: Persist the handle and replace the COMPANION_DEVICE throw**

Replace the body of `initialize` so it (a) persists the handle when present and (b) accepts
`COMPANION_DEVICE`:

```kotlin
    override fun initialize(request: InitializeRequestMessage): String {
        return observe("initialize", mapOf("isBackground" to request.isBackground)) {
            BleProcessOwner.attach(context)
            // Persist the dedicated background entry-point handle so the headless engine can be
            // revived after process death (#28). Registration originates from Dart's
            // background(onBackgroundRelaunch:) (Task 17) and arrives via this request.
            request.backgroundCallbackHandle?.let {
                HeadlessEngineLauncher.storeBackgroundHandle(context, it)
            }
            if (request.isBackground) {
                when (request.strategy) {
                    BackgroundStrategyMessage.FOREGROUND_SERVICE -> {
                        val notification = request.notification
                            ?: throw bleError(
                                BleErrorCode.BACKGROUND_CONFIG_MISSING,
                                "Foreground service notification config is required",
                            )
                        BleProcessOwner.startForegroundService(notification)
                    }
                    // Companion Device drives reconnection via presence events delivered to the
                    // CompanionDeviceService (#27); the headless engine is revived there (#28).
                    // Presence observation is enabled per device via associate, not at init
                    // (Review guide §8), so initialize only attaches the owner here.
                    BackgroundStrategyMessage.COMPANION_DEVICE -> Unit
                    null -> throw bleError(
                        BleErrorCode.BACKGROUND_CONFIG_MISSING,
                        "Android background strategy is required",
                    )
                }
            }
            "engine-${System.identityHashCode(this)}"
        }
    }
```

Also update the class KDoc line that says
`Companion Device background mode の init / presence event 配送は後続 issue（#27/#29）` to note that
`COMPANION_DEVICE` init and headless relaunch are handled as of #28.

- [ ] **Step 2: Verify it compiles**

Run: `./gradlew :deepsky_bluetooth_android:testDebugUnitTest`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/BleCentralManager.kt
git commit -m "feat(android): persist background handle and accept companion device init (#28)"
```

---

### Task 6: Full verification

- [ ] **Step 1: Run the full module test suite**

Run: `./gradlew :deepsky_bluetooth_android:testDebugUnitTest`
Expected: BUILD SUCCESSFUL, all tests pass (existing + 8 new `HeadlessLifecycleStateTest`).

- [ ] **Step 2: Confirm `main()`/`runApp()` is not referenced by the launcher**

Run: `grep -nE "executeDartEntrypoint|runApp|createDefault" plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/HeadlessEngineLauncher.kt`
Expected: no matches (only `executeDartCallback` is used).

- [ ] **Step 3: Push branch and open PR** (see handoff).
