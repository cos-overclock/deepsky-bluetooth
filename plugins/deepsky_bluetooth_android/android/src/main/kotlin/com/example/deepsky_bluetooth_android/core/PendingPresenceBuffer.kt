package com.example.deepsky_bluetooth_android.core

import java.util.ArrayDeque

/**
 * sink（Flutter engine）不在のあいだ presence event を保持する有界 FIFO バッファ。
 *
 * `CompanionDeviceService` は process 死後にもシステムから起動され得るため、配送先 sink が
 * まだ無い瞬間がある（Issue #27 受け入れ条件「engine 不在でも event を保持できる」）。本バッファは
 * その間の event を蓄え、sink 復帰時に [drain] で一括 flush する。
 *
 * 上限超過時は最古から破棄する（Review guide §12 の handover バッファ方針に合わせる）。最新の
 * 接続状態は別途 snapshot が正とするため、古い presence の取りこぼしは許容する。
 */
class PendingPresenceBuffer(private val capacity: Int = DEFAULT_CAPACITY) {

    private val events = ArrayDeque<CompanionPresenceEvent>()

    /** event を末尾へ追加する。上限超過なら最古を捨てる。 */
    @Synchronized
    fun record(event: CompanionPresenceEvent) {
        if (events.size >= capacity) events.pollFirst()
        events.addLast(event)
    }

    /** 保持中の event を FIFO 順で返し、バッファを空にする。 */
    @Synchronized
    fun drain(): List<CompanionPresenceEvent> {
        if (events.isEmpty()) return emptyList()
        val drained = events.toList()
        events.clear()
        return drained
    }

    companion object {
        /** Review guide §12 の handover 上限に合わせた既定容量。 */
        const val DEFAULT_CAPACITY = 256
    }
}
