package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.WaterIntakeDao
import com.habitloss.app.data.local.entity.WaterIntakeEntity
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

class WaterRepositoryTest {

    private val dao = mockk<WaterIntakeDao>(relaxed = true)
    private val testDispatcher = StandardTestDispatcher()
    private val repository = WaterRepositoryImpl(dao, testDispatcher)

    @Test
    fun `getTodayWaterIntake emits default when dao returns null`() = runTest(testDispatcher) {
        val today = LocalDate.now()
        coEvery { dao.getWaterIntakeForDateFlow(today) } returns flowOf(null)

        val result = repository.getTodayWaterIntake().first()

        assertEquals(0, result.glassesCount)
        assertEquals(8, result.targetGlasses)
    }

    @Test
    fun `incrementGlass inserts record if none exists`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        coEvery { dao.getWaterIntakeForDateSync(today) } returns null

        val slot = slot<WaterIntakeEntity>()
        coEvery { dao.insertOrUpdate(capture(slot)) } returns Unit

        repository.incrementGlass(today)

        val saved = slot.captured
        assertEquals(1, saved.glassesCount)
        assertEquals(8, saved.targetGlasses)
    }

    @Test
    fun `incrementGlass calls incrementGlasses on dao if record exists`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        val existing = WaterIntakeEntity(date = today, glassesCount = 3, targetGlasses = 8)
        coEvery { dao.getWaterIntakeForDateSync(today) } returns existing

        repository.incrementGlass(today)

        coVerify { dao.incrementGlasses(date = today, amount = 1) }
    }
}
