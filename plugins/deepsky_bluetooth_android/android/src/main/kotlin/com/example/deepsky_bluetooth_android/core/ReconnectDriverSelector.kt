package com.example.deepsky_bluetooth_android.core

/**
 * 自動再接続の駆動源（Review guide §8）。Android では A（Dart 固定間隔）と C（CDM presence）の
 * 2 系があり、状況で切り替える。
 */
enum class ReconnectDriver {
    /** A: Dart 固定間隔。Dart engine 生存中だけ有効。 */
    DART_INTERVAL,

    /** C: CDM presence。関連付け + presence 監視が有効なときに使う。headless 復活でも成立する。 */
    CDM_PRESENCE,

    /** 駆動源なし。headless かつ presence 無効＝ C が必須だが不在の状態。 */
    NONE,
}

/**
 * presence 監視の有効/無効と UI engine の有無から、使用すべき再接続駆動源を選ぶ純粋関数
 * （Review guide §8）。
 *
 * - presence 有効 → C（[ReconnectDriver.CDM_PRESENCE]）。headless でも process 復活で継続できる。
 * - presence 無効 + UI engine 生存 → A（[ReconnectDriver.DART_INTERVAL]）。
 * - presence 無効 + headless → [ReconnectDriver.NONE]。A は engine 不在で不可、C は presence 無効で
 *   不可。すなわち headless 復活には presence が必須（Issue #27 受け入れ条件「presence 必須判定」）。
 */
object ReconnectDriverSelector {

    fun select(presenceEnabled: Boolean, hasUiEngine: Boolean): ReconnectDriver = when {
        presenceEnabled -> ReconnectDriver.CDM_PRESENCE
        hasUiEngine -> ReconnectDriver.DART_INTERVAL
        else -> ReconnectDriver.NONE
    }
}
