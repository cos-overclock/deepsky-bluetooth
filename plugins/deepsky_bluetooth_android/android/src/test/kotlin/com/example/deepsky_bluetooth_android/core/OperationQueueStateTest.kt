package com.example.deepsky_bluetooth_android.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

internal class OperationQueueStateTest {
    private val epoch = 7L
    private val otherEpoch = 8L

    private fun queue() = OperationQueueState<String>(epoch)

    // --- opSeq 採番 -------------------------------------------------------

    @Test
    fun enqueue_assignsStrictlyIncreasingOpSeqStartingAtFirst() {
        val q = queue()

        assertEquals(OperationQueueState.FIRST_OP_SEQ,
            q.enqueue(OperationKind.READ_CHARACTERISTIC, "a").opSeq)
        assertEquals(OperationQueueState.FIRST_OP_SEQ + 1L,
            q.enqueue(OperationKind.READ_CHARACTERISTIC, "b").opSeq)
        assertEquals(OperationQueueState.FIRST_OP_SEQ + 2L,
            q.enqueue(OperationKind.READ_CHARACTERISTIC, "c").opSeq)
    }

    @Test
    fun enqueue_carriesEpochKindAndPayload() {
        val q = queue()

        val op = q.enqueue(OperationKind.WRITE_CHARACTERISTIC, "payload")

        assertEquals(epoch, op.epoch)
        assertEquals(OperationKind.WRITE_CHARACTERISTIC, op.kind)
        assertEquals("payload", op.payload)
    }

    // --- 同時1操作 / FIFO ------------------------------------------------

    @Test
    fun startNext_returnsHeadInFifoOrder() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "first")
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "second")

        assertEquals("first", q.startNext()?.payload)
        // 先頭を完了させると次が出る。
        q.completeCurrent(epoch, CallbackKind.CHARACTERISTIC_READ)
        assertEquals("second", q.startNext()?.payload)
    }

    @Test
    fun startNext_returnsNullWhileBusySoOnlyOneOperationRunsAtATime() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "b")

        val started = q.startNext()
        assertEquals("a", started?.payload)
        assertTrue(q.isBusy)
        // 先頭が in-flight の間は次を実行できない(device ごと同時1操作)。
        assertNull(q.startNext())
        assertSame(started, q.current)
    }

    @Test
    fun startNext_returnsNullWhenEmpty() {
        val q = queue()

        assertNull(q.startNext())
        assertFalse(q.isBusy)
    }

    // --- callback 相関(epoch + kind) -----------------------------------

    @Test
    fun completeCurrent_completesHeadWhenEpochAndKindMatch() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        val started = q.startNext()

        val completed = q.completeCurrent(epoch, CallbackKind.CHARACTERISTIC_READ)

        assertSame(started, completed)
        assertFalse(q.isBusy)
        assertNull(q.current)
    }

    @Test
    fun completeCurrent_ignoresMismatchedKindSoDelayedCallbackDoesNotCompleteNext() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        val started = q.startNext()

        // write 応答が遅れて届いても read の先頭は完了させない。
        val completed = q.completeCurrent(epoch, CallbackKind.CHARACTERISTIC_WRITE)

        assertNull(completed)
        assertTrue(q.isBusy)
        assertSame(started, q.current)
    }

    @Test
    fun completeCurrent_ignoresStaleEpochCallback() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        val started = q.startNext()

        // 旧 epoch の遅延 callback は現行 operation を完了しない(Review guide §9/§10)。
        val completed = q.completeCurrent(otherEpoch, CallbackKind.CHARACTERISTIC_READ)

        assertNull(completed)
        assertTrue(q.isBusy)
        assertSame(started, q.current)
    }

    @Test
    fun completeCurrent_returnsNullWhenNothingInFlight() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")

        // まだ startNext していない = in-flight なし。
        assertNull(q.completeCurrent(epoch, CallbackKind.CHARACTERISTIC_READ))
    }

    @Test
    fun completeCurrent_matchesSetNotifyAndDescriptorWriteToDescriptorWriteCallback() {
        // CCCD 書込(setNotify)と通常の descriptor write はどちらも onDescriptorWrite で
        // 返るため、同じ callback kind で完了できる(同時1操作なので取り違えない)。
        for (kind in listOf(OperationKind.SET_NOTIFY, OperationKind.WRITE_DESCRIPTOR)) {
            val q = queue()
            q.enqueue(kind, "a")
            val started = q.startNext()

            val completed = q.completeCurrent(epoch, CallbackKind.DESCRIPTOR_WRITE)

            assertSame(started, completed, "kind=$kind should complete on DESCRIPTOR_WRITE")
        }
    }

    @Test
    fun everyOperationKindCompletesOnItsMappedCallbackKind() {
        for (kind in OperationKind.entries) {
            val q = queue()
            q.enqueue(kind, "a")
            q.startNext()

            val completed = q.completeCurrent(epoch, kind.callbackKind)
            assertEquals("a", completed?.payload, "kind=$kind did not complete on ${kind.callbackKind}")
        }
    }

    // --- abort ------------------------------------------------------------

    @Test
    fun abortCurrent_clearsCurrentSoNextCanStart() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "b")
        val started = q.startNext()

        val aborted = q.abortCurrent()

        assertSame(started, aborted)
        assertFalse(q.isBusy)
        assertEquals("b", q.startNext()?.payload)
    }

    @Test
    fun abortCurrent_returnsNullWhenNothingInFlight() {
        val q = queue()

        assertNull(q.abortCurrent())
    }

    // --- timeout 退役 -----------------------------------------------------

    @Test
    fun retire_drainsInFlightThenPendingInOrder() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "b")
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "c")
        q.startNext() // "a" in-flight, "b"/"c" pending

        val drained = q.retire().map { it.payload }

        assertEquals(listOf("a", "b", "c"), drained)
        assertTrue(q.isRetired)
        assertFalse(q.isBusy)
        assertEquals(0, q.pendingCount)
    }

    @Test
    fun retire_drainsPendingOnlyWhenNoneInFlight() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "b")

        val drained = q.retire().map { it.payload }

        assertEquals(listOf("a", "b"), drained)
    }

    @Test
    fun retire_isTerminalSoStartNextDoesNotContinueOnSameQueue() {
        // timeout 退役後は同じ queue(=同じ GATT)で処理を続行しない(Review guide §10)。
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        q.retire()

        assertNull(q.startNext())
    }

    @Test
    fun retire_isTerminalSoCompleteCurrentIsIgnored() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        q.startNext()
        q.retire()

        // 退役後に届いた遅延 callback は何も完了しない。
        assertNull(q.completeCurrent(epoch, CallbackKind.CHARACTERISTIC_READ))
    }

    @Test
    fun retire_isIdempotentAndSecondCallDrainsNothing() {
        val q = queue()
        q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")

        assertEquals(1, q.retire().size)
        assertTrue(q.retire().isEmpty())
    }

    @Test
    fun enqueue_afterRetireFails() {
        val q = queue()
        q.retire()

        assertFailsWith<IllegalStateException> {
            q.enqueue(OperationKind.READ_CHARACTERISTIC, "a")
        }
    }
}
