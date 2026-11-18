package com.habitos.cleanstep.presentation.dashboard

import com.habitos.cleanstep.domain.model.HabitStreak
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WaterIntake
import com.habitos.cleanstep.domain.model.WeeklySugarDay
import com.habitos.cleanstep.domain.repository.HabitRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
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
class DashboardViewModelTest {

    private val testDispatcher = StandardTestDispatcher()

    private class FakeHabitRepository : HabitRepository {
        val streakFlow = MutableStateFlow(HabitStreak(currentStreak = 3, bestStreak = 7))
        val sugarFlow = MutableStateFlow(SugarTrafficLight.GREEN)
        val weeklySugarFlow = MutableStateFlow<List<WeeklySugarDay>>(emptyList())
        val waterFlow = MutableStateFlow(WaterIntake(glassesCount = 4, targetGlasses = 8))
        val nightRoutineFlow = MutableStateFlow(NightRoutineSummary(isCompletedToday = false))

        var recordedSugarLevel: SugarTrafficLight? = null
        var waterIncrementCalls = 0
        var waterDecrementCalls = 0
        var toggleNightRoutineCalls = 0

        override fun getHabitStreak(): Flow<HabitStreak> = streakFlow
        override fun getSugarTrafficLightToday(): Flow<SugarTrafficLight> = sugarFlow
        override fun getWeeklySugarHistory(): Flow<List<WeeklySugarDay>> = weeklySugarFlow
        override fun getWaterIntakeToday(): Flow<WaterIntake> = waterFlow
        override fun getNightRoutineToday(): Flow<NightRoutineSummary> = nightRoutineFlow

        override suspend fun setSugarTrafficLightToday(level: SugarTrafficLight) {
            recordedSugarLevel = level
            sugarFlow.value = level
        }

        override suspend fun incrementWater() {
            waterIncrementCalls++
            waterFlow.value = waterFlow.value.copy(glassesCount = waterFlow.value.glassesCount + 1)
        }

        override suspend fun decrementWater() {
            waterDecrementCalls++
            if (waterFlow.value.glassesCount > 0) {
                waterFlow.value = waterFlow.value.copy(glassesCount = waterFlow.value.glassesCount - 1)
            }
        }

        override suspend fun toggleNightRoutine() {
            toggleNightRoutineCalls++
            nightRoutineFlow.value = nightRoutineFlow.value.copy(
                isCompletedToday = !nightRoutineFlow.value.isCompletedToday
            )
        }
    }

    private lateinit var fakeRepository: FakeHabitRepository
    private lateinit var viewModel: DashboardViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeHabitRepository()
        viewModel = DashboardViewModel(fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial ui state loads correctly from repository`() = runTest(testDispatcher) {
        advanceUntilIdle()
        val state = viewModel.uiState.value
        assertEquals(3, state.habitStreak.currentStreak)
        assertEquals(SugarTrafficLight.GREEN, state.sugarLevelToday)
        assertEquals(4, state.waterIntake.glassesCount)
        assertFalse(state.nightRoutine.isCompletedToday)
    }

    @Test
    fun `selecting sugar traffic light updates state and calls repository`() = runTest(testDispatcher) {
        advanceUntilIdle()

        viewModel.onEvent(DashboardEvent.SelectSugarLevel(SugarTrafficLight.AMBER))
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(SugarTrafficLight.AMBER, state.sugarLevelToday)
        assertEquals(SugarTrafficLight.AMBER, fakeRepository.recordedSugarLevel)
        assertNotNull(state.userFeedbackMessage)
        assertTrue(state.userFeedbackMessage!!.contains("agua", ignoreCase = true))
    }

    @Test
    fun `selecting green sugar level increments streak and shows motivational feedback`() = runTest(testDispatcher) {
        advanceUntilIdle()

        viewModel.onEvent(DashboardEvent.SelectSugarLevel(SugarTrafficLight.GREEN))
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(SugarTrafficLight.GREEN, state.sugarLevelToday)
        assertEquals(4, state.habitStreak.currentStreak)
        assertTrue(state.userFeedbackMessage!!.contains("glucosa", ignoreCase = true))
    }

    @Test
    fun `add water glass increments water count and calls repository`() = runTest(testDispatcher) {
        advanceUntilIdle()
        val initialCount = viewModel.uiState.value.waterIntake.glassesCount

        viewModel.onEvent(DashboardEvent.AddWaterGlass)
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(initialCount + 1, state.waterIntake.glassesCount)
        assertEquals(1, fakeRepository.waterIncrementCalls)
    }

    @Test
    fun `remove water glass decrements water count and calls repository`() = runTest(testDispatcher) {
        advanceUntilIdle()
        val initialCount = viewModel.uiState.value.waterIntake.glassesCount

        viewModel.onEvent(DashboardEvent.RemoveWaterGlass)
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(initialCount - 1, state.waterIntake.glassesCount)
        assertEquals(1, fakeRepository.waterDecrementCalls)
    }

    @Test
    fun `cannot decrement water below zero`() = runTest(testDispatcher) {
        fakeRepository.waterFlow.value = WaterIntake(glassesCount = 0)
        advanceUntilIdle()

        viewModel.onEvent(DashboardEvent.RemoveWaterGlass)
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(0, state.waterIntake.glassesCount)
    }

    @Test
    fun `craving rescue event emits navigation event`() = runTest(testDispatcher) {
        var receivedNavigation: DashboardNavigationEvent? = null
        val job = kotlinx.coroutines.launch {
            viewModel.navigationEvents.collect {
                receivedNavigation = it
            }
        }

        viewModel.onEvent(DashboardEvent.OpenCravingRescue)
        advanceUntilIdle()

        assertEquals(DashboardNavigationEvent.NavigateToCravingRescue, receivedNavigation)
        job.cancel()
    }

    @Test
    fun `open night routine event emits navigation event`() = runTest(testDispatcher) {
        var receivedNavigation: DashboardNavigationEvent? = null
        val job = kotlinx.coroutines.launch {
            viewModel.navigationEvents.collect {
                receivedNavigation = it
            }
        }

        viewModel.onEvent(DashboardEvent.OpenNightRoutine)
        advanceUntilIdle()

        assertEquals(DashboardNavigationEvent.NavigateToNightRoutine, receivedNavigation)
        job.cancel()
    }

    @Test
    fun `toggle night routine updates state and calls repository`() = runTest(testDispatcher) {
        advanceUntilIdle()
        assertFalse(viewModel.uiState.value.nightRoutine.isCompletedToday)

        viewModel.onEvent(DashboardEvent.ToggleNightRoutine)
        advanceUntilIdle()

        assertTrue(viewModel.uiState.value.nightRoutine.isCompletedToday)
        assertEquals(1, fakeRepository.toggleNightRoutineCalls)
        assertNotNull(viewModel.uiState.value.userFeedbackMessage)
    }

    @Test
    fun `dismiss feedback message clears feedback message in state`() = runTest(testDispatcher) {
        viewModel.onEvent(DashboardEvent.SelectSugarLevel(SugarTrafficLight.RED))
        advanceUntilIdle()
        assertNotNull(viewModel.uiState.value.userFeedbackMessage)

        viewModel.onEvent(DashboardEvent.DismissFeedbackMessage)
        advanceUntilIdle()
        assertNull(viewModel.uiState.value.userFeedbackMessage)
    }
}
