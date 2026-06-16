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
