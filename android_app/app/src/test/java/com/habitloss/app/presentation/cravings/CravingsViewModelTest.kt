package com.habitloss.app.presentation.cravings

import com.habitloss.app.domain.model.CravingRescueSession
import com.habitloss.app.domain.model.MexicanRescueSnacksCatalog
import com.habitloss.app.domain.model.TimerStatus
import com.habitloss.app.domain.model.UrgeSurfingPhase
import com.habitloss.app.domain.repository.CravingRescueRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CravingsViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private val repository = mockk<CravingRescueRepository>(relaxed = true)
    private lateinit var viewModel: CravingsViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = CravingsViewModel(repository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state has 15 minutes and all 5 Mexican rescue snacks`() {
        val state = viewModel.uiState.value
        assertEquals(15, state.selectedDurationMinutes)
        assertEquals(900, state.totalSeconds)
        assertEquals(900, state.remainingSeconds)
        assertEquals(TimerStatus.IDLE, state.timerStatus)
        assertEquals("15:00", state.formattedRemainingTime)
        assertEquals(0f, state.progressFraction, 0.01f)
        assertEquals(5, state.rescueSnacks.size)
        assertFalse(state.isCompleted)
    }

    @Test
    fun `changing duration to 10 minutes updates seconds correctly`() {
        viewModel.onEvent(CravingsEvent.ChangeDuration(10))

        val state = viewModel.uiState.value
        assertEquals(10, state.selectedDurationMinutes)
        assertEquals(600, state.totalSeconds)
        assertEquals(600, state.remainingSeconds)
        assertEquals("10:00", state.formattedRemainingTime)
    }

    @Test
    fun `starting timer updates status to RUNNING and ticks down`() = runTest(testDispatcher) {
        viewModel.onEvent(CravingsEvent.StartTimer)
        assertEquals(TimerStatus.RUNNING, viewModel.uiState.value.timerStatus)

        // Avanzar 5 segundos
        advanceTimeBy(5000L)

        val state = viewModel.uiState.value
        assertEquals(895, state.remainingSeconds)
        assertEquals("14:55", state.formattedRemainingTime)
        assertTrue(state.isRunning)
    }

    @Test
    fun `pausing timer stops ticking and keeps remaining seconds`() = runTest(testDispatcher) {
        viewModel.onEvent(CravingsEvent.StartTimer)
        advanceTimeBy(3000L)
        assertEquals(897, viewModel.uiState.value.remainingSeconds)

        viewModel.onEvent(CravingsEvent.PauseTimer)
        assertEquals(TimerStatus.PAUSED, viewModel.uiState.value.timerStatus)

        // Avanzar más tiempo en pausa
        advanceTimeBy(5000L)
        assertEquals(897, viewModel.uiState.value.remainingSeconds) // no debe cambiar
    }

    @Test
    fun `resuming timer continues from paused seconds`() = runTest(testDispatcher) {
        viewModel.onEvent(CravingsEvent.StartTimer)
        advanceTimeBy(10000L)
        viewModel.onEvent(CravingsEvent.PauseTimer)

        assertEquals(890, viewModel.uiState.value.remainingSeconds)

        viewModel.onEvent(CravingsEvent.ResumeTimer)
        assertEquals(TimerStatus.RUNNING, viewModel.uiState.value.timerStatus)

        advanceTimeBy(5000L)
        assertEquals(885, viewModel.uiState.value.remainingSeconds)
    }

    @Test
    fun `resetting timer restores initial duration`() = runTest(testDispatcher) {
        viewModel.onEvent(CravingsEvent.StartTimer)
        advanceTimeBy(20000L)

        viewModel.onEvent(CravingsEvent.ResetTimer)

        val state = viewModel.uiState.value
        assertEquals(TimerStatus.IDLE, state.timerStatus)
        assertEquals(900, state.remainingSeconds)
        assertEquals("15:00", state.formattedRemainingTime)
    }

    @Test
    fun `timer completes when reaching zero and marks session completed`() = runTest(testDispatcher) {
        viewModel.onEvent(CravingsEvent.ChangeDuration(10)) // 600 segundos
        viewModel.onEvent(CravingsEvent.StartTimer)

        // Avanzar 600 segundos
        advanceTimeBy(600_000L)

        val state = viewModel.uiState.value
        assertEquals(0, state.remainingSeconds)
        assertEquals(TimerStatus.COMPLETED, state.timerStatus)
        assertTrue(state.isCompleted)
        assertEquals(UrgeSurfingPhase.COMPLETED_SURF, state.currentPhase)
    }

    @Test
    fun `confirming craving passed without eating logs session to repository`() = runTest(testDispatcher) {
        viewModel.onEvent(CravingsEvent.ConfirmCravingPassedWithoutEating)
        advanceUntilIdle()

        assertTrue(viewModel.uiState.value.surfedWithoutEating == true)
        assertTrue(viewModel.uiState.value.isSessionCompleted)

        coVerify(exactly = 1) {
            repository.logCravingSession(match {
                it.resistedSuccessfully && it.selectedSwap == null
            })
        }
    }

    @Test
    fun `confirming ate rescue snack logs session with swap details`() = runTest(testDispatcher) {
        val boiledEgg = MexicanRescueSnacksCatalog.snacks.first { it.id == "boiled_eggs_protein" }
        viewModel.onEvent(CravingsEvent.ConfirmAteRescueSnack(boiledEgg))
        advanceUntilIdle()

        assertEquals(boiledEgg, viewModel.uiState.value.selectedSnack)
        assertFalse(viewModel.uiState.value.surfedWithoutEating == true)

        coVerify(exactly = 1) {
            repository.logCravingSession(match {
                it.resistedSuccessfully && it.selectedSwap == boiledEgg.name
            })
        }
    }
}
