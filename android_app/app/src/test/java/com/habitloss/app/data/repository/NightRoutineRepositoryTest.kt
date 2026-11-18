package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.NightRoutineDao
import com.habitloss.app.data.local.entity.NightRoutineEntity
import com.habitloss.app.domain.model.RoutineDifficulty
import io.mockk.coEvery
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

class NightRoutineRepositoryTest {

    private val dao = mockk<NightRoutineDao>(relaxed = true)
    private val testDispatcher = StandardTestDispatcher()
    private val repository = NightRoutineRepositoryImpl(dao, testDispatcher)

    @Test
    fun `getCompletedDaysInCurrentWeek returns completed count from DAO`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        val startOfWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))

        coEvery { dao.getCompletedCountBetweenFlow(startOfWeek, endOfWeek) } returns flowOf(5)

        val count = repository.getCompletedDaysInCurrentWeek().first()
        assertEquals(5, count)
    }

    @Test
    fun `getCurrentRoutinePlan advances to Level 2 on 4 or more completed days`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        val startOfWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))

        coEvery { dao.getCompletedCountBetweenFlow(startOfWeek, endOfWeek) } returns flowOf(4)

        val plan = repository.getCurrentRoutinePlan().first()
        assertEquals(2, plan.level)
        assertTrue(plan.exercises.any { it.id == "incline_plank" })
    }

    @Test
    fun `completeRoutine stores completed routine in Room`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        val exercises = listOf("assisted_squats", "slow_high_knees", "breathing_478")
        val slot = slot<NightRoutineEntity>()
        coEvery { dao.insertOrUpdate(capture(slot)) } returns Unit

        repository.completeRoutine(
            date = today,
            exercises = exercises,
            durationMinutes = 15,
            weekNumber = 2,
            difficulty = RoutineDifficulty.GENTLE
        )

        val saved = slot.captured
        assertEquals(today, saved.date)
        assertTrue(saved.completed)
        assertEquals(15, saved.durationMinutes)
        assertEquals(exercises, saved.exercisesDone)
    }
}
