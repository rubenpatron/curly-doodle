package com.habitos.cleanstep.data.repository

import com.habitos.cleanstep.data.local.dao.HabitStreakDao
import com.habitos.cleanstep.data.local.dao.NightRoutineDao
import com.habitos.cleanstep.data.local.dao.SugarLogDao
import com.habitos.cleanstep.data.local.dao.WaterIntakeDao
import com.habitos.cleanstep.data.local.entity.HabitStreakEntity
import com.habitos.cleanstep.data.local.entity.WaterIntakeEntity
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import java.time.LocalDate

@OptIn(ExperimentalCoroutinesApi::class)
class HabitRepositoryImplTest {

    private val testDispatcher = StandardTestDispatcher()

    private val habitStreakDao = mockk<HabitStreakDao>(relaxed = true)
    private val sugarLogDao = mockk<SugarLogDao>(relaxed = true)
    private val waterIntakeDao = mockk<WaterIntakeDao>(relaxed = true)
    private val nightRoutineDao = mockk<NightRoutineDao>(relaxed = true)

    private lateinit var repository: HabitRepositoryImpl

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        repository = HabitRepositoryImpl(
            habitStreakDao = habitStreakDao,
            sugarLogDao = sugarLogDao,
            waterIntakeDao = waterIntakeDao,
            nightRoutineDao = nightRoutineDao,
            ioDispatcher = testDispatcher
        )
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `getHabitStreak maps entity to domain model correctly`() = runTest(testDispatcher) {
        val entity = HabitStreakEntity(
            currentStreak = 5,
            bestStreak = 10,
            daysWithoutSoda = 7,
            daysWithoutCookies = 5,
            daysWithoutChips = 8,
            lastCleanDate = LocalDate.of(2026, 11, 17)
        )
        every { habitStreakDao.getStreakFlow(1L) } returns flowOf(entity)

        val result = repository.getHabitStreak().first()

        assertEquals(5, result.currentStreak)
        assertEquals(10, result.bestStreak)
        assertEquals(7, result.daysWithoutSoda)
        assertEquals(5, result.daysWithoutCookies)
        assertEquals(8, result.daysWithoutChips)
    }

    @Test
    fun `incrementWater creates row when not present`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        coEvery { waterIntakeDao.getWaterIntakeSync(today) } returns null

        repository.incrementWater()

        val slot = slot<WaterIntakeEntity>()
        coVerify { waterIntakeDao.insertOrUpdate(capture(slot)) }
        assertEquals(1, slot.captured.glassesCount)
        assertEquals(8, slot.captured.targetGlasses)
    }

    @Test
    fun `incrementWater calls incrementGlasses when row exists`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        val existing = WaterIntakeEntity(date = today, glassesCount = 3, targetGlasses = 8)
        coEvery { waterIntakeDao.getWaterIntakeSync(today) } returns existing

        repository.incrementWater()

        coVerify { waterIntakeDao.incrementGlasses(today) }
    }

    @Test
    fun `setSugarTrafficLightToday with RED resets current streak`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        val currentEntity = HabitStreakEntity(id = 1L, currentStreak = 5, bestStreak = 10)
        coEvery { habitStreakDao.getStreakSync(1L) } returns currentEntity

        repository.setSugarTrafficLightToday(SugarTrafficLight.RED)

        val slot = slot<HabitStreakEntity>()
        coVerify { habitStreakDao.insertOrUpdate(capture(slot)) }
        assertEquals(0, slot.captured.currentStreak)
        assertEquals(10, slot.captured.bestStreak) // best streak is preserved
    }
}
