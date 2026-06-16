package com.example.deepsky_bluetooth_android.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class ReconnectDriverSelectorTest {

    @Test
    fun presenceEnabled_usesCdmPresenceRegardlessOfEngine() {
        // 関連付け + presence 有効なら駆動源 C（Review guide §8）。UI engine 有無に依らない。
        assertEquals(
            ReconnectDriver.CDM_PRESENCE,
            ReconnectDriverSelector.select(presenceEnabled = true, hasUiEngine = true),
        )
        assertEquals(
            ReconnectDriver.CDM_PRESENCE,
            ReconnectDriverSelector.select(presenceEnabled = true, hasUiEngine = false),
        )
    }

    @Test
    fun presenceDisabledWithUiEngine_usesDartInterval() {
        // presence 無効でも Dart engine 生存中なら駆動源 A。
        assertEquals(
            ReconnectDriver.DART_INTERVAL,
            ReconnectDriverSelector.select(presenceEnabled = false, hasUiEngine = true),
        )
    }

    @Test
    fun presenceDisabledHeadless_hasNoDriver() {
        // headless かつ presence 無効では A も C も成立しない（presence 必須だが不在）。
        assertEquals(
            ReconnectDriver.NONE,
            ReconnectDriverSelector.select(presenceEnabled = false, hasUiEngine = false),
        )
    }

    @Test
    fun presenceRequiredForHeadless_isTrueOnlyWhenHeadlessAndPresenceDisabled() {
        // 受け入れ条件「headless 復活時の presence 必須判定」: NONE は presence 必須を意味する。
        assertTrue(
            ReconnectDriverSelector.select(presenceEnabled = false, hasUiEngine = false)
                == ReconnectDriver.NONE,
        )
    }
}
