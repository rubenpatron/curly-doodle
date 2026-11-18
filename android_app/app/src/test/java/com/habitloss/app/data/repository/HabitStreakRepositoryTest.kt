package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.HabitStreakDao
import com.habitloss.app.data.local.entity.HabitStreakEntity
import com.habitloss.app.domain.model.HabitStreak
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class HabitStreakRepositoryTest {

    private val dao = mockk<HabitStreakDao>(relaxed = true)
    private val testDispatcher = StandardTestDispatcher()
    private val repository = HabitStreakRepositoryImpl(dao, testDispatcher)

    @Test
    fun `getStreak emits domain HabitStreak from DAO`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        val entity = HabitStreakEntity(
            id = 1L,
            currentStreak = 5,
            bestStreak = 10,
            lastCleanDate = today
        )
        coEvery { dao.getStreakFlow(1L) } returns flowOf(entity)

        val result = repository.getStreak().first()

        assertEquals(5, result.currentStreak)
        assertEquals(10, result.bestStreak)
        assertEquals(today, result.lastCleanDate)
        assertTrue(result.isTodayClean)
    }

    @Test
    fun `recordCleanDay increments consecutive streak when yesterday was clean`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        val yesterday = LocalDate.of(2026, 11, 17)

        val existing = HabitStreakEntity(
            id = 1L,
            currentStreak = 3,
            bestStreak = 4,
            lastCleanDate = yesterday
        )
        coEvery { dao.getStreakSync(1L) } returns existing

        val slot = slot<HabitStreakEntity>()
        coEvery { dao.insertOrUpdate(capture(slot)) } returns Unit

        repository.recordCleanDay(today)

        val saved = slot.captured
        assertEquals(4, saved.currentStreak)
        assertEquals(4, saved.bestStreak)
        assertEquals(today, saved.lastCleanDate)
    }

    @Test
    fun `recordCleanDay does not increment if already recorded for today`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        val existing = HabitStreakEntity(
            id = 1L,
            currentStreak = 3,
            bestStreak = 4,
            lastCleanDate = today
        )
        coEvery { dao.getStreakSync(1L) } returns existing

        repository.recordCleanDay(today)

        coVerify(exactly = 0) { dao.insertOrUpdate(any()) }
    }

    @Test
    fun `recordRelapse resets currentStreak to 0 while maintaining bestStreak`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        val existing = HabitStreakEntity(
            id = 1L,
            currentStreak = 7,
            bestStreak = 12,
            lastCleanDate = today.minusDays(1)
        )
        coEvery { dao.getStreakSync(1L) } returns existing

        val slot = slot<HabitStreakEntity>()
        coEvery { dao.insertOrUpdate(capture(slot)) } returns Unit

        repository.recordRelapse(today)

        val saved = slot.captured
        assertEquals(0, saved.currentStreak)
        assertEquals(12, saved.bestStreak)
    }
}
