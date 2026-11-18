package com.habitos.cleanstep.data.repository

import com.habitos.cleanstep.data.local.dao.NightRoutineDao
import com.habitos.cleanstep.data.local.entity.NightRoutineEntity
import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

class NightRoutineRepositoryTest {

    private val dao = mockk<NightRoutineDao>(relaxed = true)
    private val testDispatcher = StandardTestDispatcher()
    private val repository = NightRoutinePlanRepositoryImpl(dao, testDispatcher)

    @Test
    fun `getCompletedDaysInCurrentWeek returns count from DAO within current Monday-Sunday window`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        val startOfWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))

        coEvery { dao.getCompletedDaysCountFlow(startOfWeek, endOfWeek) } returns flowOf(4)

        val result = repository.getCompletedDaysInCurrentWeek().first()
        assertEquals(4, result)
    }

    @Test
    fun `isRoutineCompletedToday returns true when Room has completed record`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        val entity = NightRoutineEntity(date = today, completed = true)
        coEvery { dao.getRoutineForDateFlow(today) } returns flowOf(entity)

        val isCompleted = repository.isRoutineCompletedToday(today).first()
        assertTrue(isCompleted)
    }

    @Test
    fun `isRoutineCompletedToday returns false when Room has no record`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        coEvery { dao.getRoutineForDateFlow(today) } returns flowOf(null)

        val isCompleted = repository.isRoutineCompletedToday(today).first()
        assertFalse(isCompleted)
    }

    @Test
    fun `getPlanForLevel generates plan with adjusted work and rest intervals`() {
        val level1Plan = repository.getPlanForLevel(SedentaryProgressionLevel.LEVEL_1)
        assertEquals(30, level1Plan.level.workDurationSeconds)
        assertEquals(30, level1Plan.level.restDurationSeconds)
        assertEquals(6, level1Plan.exercises.size)

        val level2Plan = repository.getPlanForLevel(SedentaryProgressionLevel.LEVEL_2)
        assertEquals(35, level2Plan.level.workDurationSeconds)
        assertEquals(25, level2Plan.level.restDurationSeconds)

        val level3Plan = repository.getPlanForLevel(SedentaryProgressionLevel.LEVEL_3)
        assertEquals(40, level3Plan.level.workDurationSeconds)
        assertEquals(20, level3Plan.level.restDurationSeconds)
    }

    @Test
    fun `markRoutineCompleted saves completed routine with progression level in Room`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        val exercises = listOf("assisted_squats", "slow_high_knees", "incline_plank", "wall_push_ups", "childs_pose", "breathing_4_7_8")

        val todayDate = LocalDate.now()
        val startOfWeek = todayDate.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = todayDate.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))
        coEvery { dao.getCompletedDaysCountSync(startOfWeek, endOfWeek) } returns 3

        val slot = slot<NightRoutineEntity>()
        coEvery { dao.insertOrUpdate(capture(slot)) } returns Unit

        repository.markRoutineCompleted(
            date = today,
            exercisesDone = exercises,
            durationMinutes = 15
        )

        val saved = slot.captured
        assertEquals(today, saved.date)
        assertTrue(saved.completed)
        assertEquals(15, saved.durationMinutes)
        assertEquals(exercises, saved.exercisesDone)
        // 3 + 1 = 4 completed days -> Advances to LEVEL_2
        assertEquals(2, saved.weekNumber)
        assertEquals("LEVEL_2", saved.difficultyLevel)
    }
}
