package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.SugarLogDao
import com.habitloss.app.data.local.entity.SugarLogEntity
import com.habitloss.app.domain.model.SugarTrafficLight
import io.mockk.coEvery
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import java.time.LocalDate

class SugarLogRepositoryTest {

    private val dao = mockk<SugarLogDao>(relaxed = true)
    private val testDispatcher = StandardTestDispatcher()
    private val repository = SugarLogRepositoryImpl(dao, testDispatcher)

    @Test
    fun `logSugar persists correct traffic light and date`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        coEvery { dao.getSugarLogForDateSync(today) } returns null

        val slot = slot<SugarLogEntity>()
        coEvery { dao.insertOrUpdate(capture(slot)) } returns 1L

        repository.logSugar(
            trafficLight = SugarTrafficLight.GREEN,
            notes = "Día limpio sin papitas",
            date = today
        )

        val saved = slot.captured
        assertEquals(today, saved.date)
        assertEquals(SugarTrafficLight.GREEN, saved.sugarTrafficLight)
        assertEquals("Día limpio sin papitas", saved.notes)
    }

    @Test
    fun `getSugarLogForDate emits mapped domain SugarLog`() = runTest(testDispatcher) {
        val today = LocalDate.of(2026, 11, 18)
        val entity = SugarLogEntity(
            id = 1L,
            date = today,
            sugarTrafficLight = SugarTrafficLight.AMBER,
            notes = "Refresco de dieta"
        )
        coEvery { dao.getSugarLogForDateFlow(today) } returns flowOf(entity)

        val result = repository.getSugarLogForDate(today).first()

        assertNotNull(result)
        assertEquals(SugarTrafficLight.AMBER, result?.trafficLight)
        assertEquals("Refresco de dieta", result?.notes)
    }
}
