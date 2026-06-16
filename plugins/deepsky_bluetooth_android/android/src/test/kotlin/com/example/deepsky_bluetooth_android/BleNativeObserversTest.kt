package com.example.deepsky_bluetooth_android

import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

internal class BleNativeObserversTest {
    private val events = mutableListOf<String>()

    @AfterTest
    fun tearDown() {
        BleNativeObservers.clear()
    }

    @Test
    fun observeMethodEmitsStartThenEndToRegisteredObserversInOrder() {
        BleNativeObservers.register(recordingObserver("first"))
        BleNativeObservers.register(recordingObserver("second"))

        val result = BleNativeObservers.observeMethod("initialize") {
            "engine-token"
        }

        assertEquals("engine-token", result)
        assertEquals(
            listOf(
                "first:start:initialize",
                "second:start:initialize",
                "first:end:initialize:ok",
                "second:end:initialize:ok",
            ),
            events,
        )
    }

    @Test
    fun observeMethodEmitsEndWithPigeonCodeWhenMethodFails() {
        BleNativeObservers.register(recordingObserver("observer"))

        val error = assertFailsWith<FlutterError> {
            BleNativeObservers.observeMethod("startScan") {
                throw bleError(BleErrorCode.PERMISSION_DENIED, "denied")
            }
        }

        assertEquals(BleErrorCode.PERMISSION_DENIED, error.code)
        assertEquals(
            listOf(
                "observer:start:startScan",
                "observer:end:startScan:permissionDenied",
            ),
            events,
        )
    }

    @Test
    fun pluginLifecycleCallbacksAreObservableAndCleanupRemovesObservers() {
        BleNativeObservers.register(recordingObserver("observer"))

        BleNativeObservers.observeMethod("plugin.attach") {}
        BleNativeObservers.observeMethod("plugin.detach") {}
        BleNativeObservers.observeMethod("dispose") {}
        BleNativeObservers.emitCallback("onAdapterStateChanged")
        BleNativeObservers.clear()
        BleNativeObservers.emitCallback("onConnectionStateChanged")

        assertEquals(
            listOf(
                "observer:start:plugin.attach",
                "observer:end:plugin.attach:ok",
                "observer:start:plugin.detach",
                "observer:end:plugin.detach:ok",
                "observer:start:dispose",
                "observer:end:dispose:ok",
                "observer:callback:onAdapterStateChanged",
            ),
            events,
        )
    }

    private fun recordingObserver(prefix: String) = object : BleNativeObserver {
        override fun onMethodStart(method: String, payload: Map<String, Any?>) {
            events.add("$prefix:start:$method")
        }

        override fun onMethodEnd(method: String, payload: Map<String, Any?>, errorCode: String?) {
            events.add("$prefix:end:$method:${errorCode ?: "ok"}")
        }

        override fun onCallback(callback: String, payload: Map<String, Any?>) {
            events.add("$prefix:callback:$callback")
        }
    }
}
