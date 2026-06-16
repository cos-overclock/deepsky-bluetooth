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
