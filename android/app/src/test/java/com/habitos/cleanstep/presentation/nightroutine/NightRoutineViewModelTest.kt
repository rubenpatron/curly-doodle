package com.habitos.cleanstep.presentation.nightroutine

import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.PlayerPhase
import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel
import com.habitos.cleanstep.domain.repository.NightRoutinePlanRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
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
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.time.LocalDate

@OptIn(ExperimentalCoroutinesApi::class)
class NightRoutineViewModelTest {

    private val testDispatcher = StandardTestDispatcher()

    private class FakeNightRoutineRepository : NightRoutinePlanRepository {
        val completedDaysFlow = MutableStateFlow(3)
        val routineCompletedTodayFlow = MutableStateFlow(false)

        var lastSavedExercises: List<String> = emptyList()
        var lastSavedDurationMinutes: Int = 0

        override fun getCompletedDaysInCurrentWeek(): Flow<Int> = completedDaysFlow
        override fun isRoutineCompletedToday(date: LocalDate): Flow<Boolean> = routineCompletedTodayFlow

        override suspend fun markRoutineCompleted(
            date: LocalDate,
            exercisesDone: List<String>,
            durationMinutes: Int
        ) {
            lastSavedExercises = exercisesDone
            lastSavedDurationMinutes = durationMinutes
            routineCompletedTodayFlow.value = true
        }

        override fun getPlanForLevel(level: SedentaryProgressionLevel): NightRoutinePlan {
            return NightRoutinePlan(level = level)
        }
    }

    private lateinit var fakeRepository: FakeNightRoutineRepository
    private lateinit var viewModel: NightRoutineViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeNightRoutineRepository()
        viewModel = NightRoutineViewModel(fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial ui state loads 3 completed days and level 1 by default`() = runTest(testDispatcher) {
        advanceUntilIdle()
        val state = viewModel.uiState.value

        assertEquals(3, state.completedDaysThisWeek)
        assertEquals(SedentaryProgressionLevel.LEVEL_1, state.progressionLevel)
        assertEquals(PlayerPhase.NOT_STARTED, state.playerPhase)
        assertEquals(0, state.currentExerciseIndex)
        assertNotNull(state.currentExercise)
        assertFalse(state.unlockedNextLevelThisWeek)
    }

    @Test
    fun `4 completed days this week automatically advances progression to Level 2`() = runTest(testDispatcher) {
        fakeRepository.completedDaysFlow.value = 4
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(4, state.completedDaysThisWeek)
        assertEquals(SedentaryProgressionLevel.LEVEL_2, state.progressionLevel)
        assertTrue(state.unlockedNextLevelThisWeek)
        assertEquals(35, state.plan.exercises.first().workDurationSeconds)
    }

    @Test
    fun `starting routine enters GET_READY phase with 5 seconds and emits silent haptic`() = runTest(testDispatcher) {
        advanceUntilIdle()
        val effectsList = mutableListOf<NightRoutineEffect>()
        val job = launch {
            viewModel.effects.collect { effectsList.add(it) }
        }

        viewModel.onEvent(NightRoutineEvent.StartRoutine)
        advanceTimeBy(100)

        val state = viewModel.uiState.value
        assertEquals(PlayerPhase.GET_READY, state.playerPhase)
        assertEquals(5, state.secondsRemaining)
        assertTrue(effectsList.any { it is NightRoutineEffect.TriggerSilentHaptic })

        job.cancel()
    }

    @Test
    fun `get ready countdown transitions to WORK phase when reaching zero`() = runTest(testDispatcher) {
        advanceUntilIdle()
        viewModel.onEvent(NightRoutineEvent.StartRoutine)
        advanceTimeBy(100)

        // Advance 5 seconds of GET_READY
        advanceTimeBy(5500)

        val state = viewModel.uiState.value
        assertEquals(PlayerPhase.WORK, state.playerPhase)
        assertEquals(state.currentExercise?.workDurationSeconds, state.secondsRemaining)
    }

    @Test
    fun `pause and resume stops and resumes countdown timer`() = runTest(testDispatcher) {
        advanceUntilIdle()
        viewModel.onEvent(NightRoutineEvent.StartRoutine)
        advanceTimeBy(100)
        assertEquals(5, viewModel.uiState.value.secondsRemaining)

        // Advance 1s -> 4s
        advanceTimeBy(1000)
        assertEquals(4, viewModel.uiState.value.secondsRemaining)

        // Pause
        viewModel.onEvent(NightRoutineEvent.PauseResumeTimer)
        assertTrue(viewModel.uiState.value.isPaused)

        // Advance time while paused - secondsRemaining should NOT change
        advanceTimeBy(3000)
        assertEquals(4, viewModel.uiState.value.secondsRemaining)

        // Resume
        viewModel.onEvent(NightRoutineEvent.PauseResumeTimer)
        assertFalse(viewModel.uiState.value.isPaused)

        advanceTimeBy(1000)
        assertEquals(3, viewModel.uiState.value.secondsRemaining)
    }

    @Test
    fun `skip next advances exercise index`() = runTest(testDispatcher) {
        advanceUntilIdle()
        viewModel.onEvent(NightRoutineEvent.StartRoutine)
        advanceTimeBy(100)

        assertEquals(0, viewModel.uiState.value.currentExerciseIndex)

        viewModel.onEvent(NightRoutineEvent.SkipToNextExercise)
        advanceTimeBy(100)

        val state = viewModel.uiState.value
        assertEquals(1, state.currentExerciseIndex)
        assertEquals("slow_high_knees", state.currentExercise?.id)
        assertEquals(PlayerPhase.WORK, state.playerPhase)
    }

    @Test
    fun `previous exercise moves back one exercise`() = runTest(testDispatcher) {
        advanceUntilIdle()
        viewModel.onEvent(NightRoutineEvent.StartRoutine)
        advanceTimeBy(100)
        viewModel.onEvent(NightRoutineEvent.SkipToNextExercise)
        advanceTimeBy(100)
        assertEquals(1, viewModel.uiState.value.currentExerciseIndex)

        viewModel.onEvent(NightRoutineEvent.PreviousExercise)
        advanceTimeBy(100)

        assertEquals(0, viewModel.uiState.value.currentExerciseIndex)
        assertEquals("assisted_squats", viewModel.uiState.value.currentExercise?.id)
    }

    @Test
    fun `finish and save completes routine and saves to repository`() = runTest(testDispatcher) {
        advanceUntilIdle()

        viewModel.onEvent(NightRoutineEvent.FinishAndSaveRoutine)
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(PlayerPhase.ROUTINE_FINISHED, state.playerPhase)
        assertTrue(state.isCompletedToday)
        assertEquals(6, fakeRepository.lastSavedExercises.size)
        assertTrue(fakeRepository.lastSavedDurationMinutes > 0)
    }

    @Test
    fun `manually selecting level updates plan durations`() = runTest(testDispatcher) {
        advanceUntilIdle()

        viewModel.onEvent(NightRoutineEvent.SelectLevel(SedentaryProgressionLevel.LEVEL_3))
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(SedentaryProgressionLevel.LEVEL_3, state.progressionLevel)
        assertEquals(40, state.plan.exercises.first().workDurationSeconds)
        assertEquals(20, state.plan.exercises.first().restDurationSeconds)
    }

    @Test
    fun `reset routine returns to not started state`() = runTest(testDispatcher) {
        advanceUntilIdle()
        viewModel.onEvent(NightRoutineEvent.StartRoutine)
        advanceTimeBy(100)
        assertEquals(PlayerPhase.GET_READY, viewModel.uiState.value.playerPhase)

        viewModel.onEvent(NightRoutineEvent.ResetRoutine)
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(PlayerPhase.NOT_STARTED, state.playerPhase)
        assertEquals(0, state.currentExerciseIndex)
        assertEquals(0, state.secondsRemaining)
    }
}
