package com.habitos.cleanstep.presentation.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.habitos.cleanstep.domain.model.HabitStreak
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WaterIntake
import com.habitos.cleanstep.domain.model.WeeklySugarDay
import com.habitos.cleanstep.domain.repository.HabitRepository
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

sealed interface DashboardNavigationEvent {
    object NavigateToCravingRescue : DashboardNavigationEvent
    object NavigateToNightRoutine : DashboardNavigationEvent
}

class DashboardViewModel(
    private val habitRepository: HabitRepository? = null
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        DashboardUiState(
            habitStreak = HabitStreak(
                currentStreak = 5,
                bestStreak = 12,
                daysWithoutSoda = 7,
                daysWithoutCookies = 5,
                daysWithoutChips = 8,
                lastCleanDate = "Hoy"
            ),
            sugarLevelToday = SugarTrafficLight.GREEN,
            weeklySugarDays = listOf(
                WeeklySugarDay("Lun", "10 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Mar", "11 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Mié", "12 Nov", SugarTrafficLight.AMBER),
                WeeklySugarDay("Jue", "13 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Vie", "14 Nov", SugarTrafficLight.RED),
                WeeklySugarDay("Sáb", "15 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Dom", "16 Nov", SugarTrafficLight.GREEN, isToday = true)
            ),
            waterIntake = WaterIntake(glassesCount = 5, targetGlasses = 8),
            nightRoutine = NightRoutineSummary(
                isCompletedToday = false,
                scheduledTime = "22:00",
                durationMinutes = 15
            )
        )
    )
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    private val _navigationEvents = MutableSharedFlow<DashboardNavigationEvent>()
    val navigationEvents: SharedFlow<DashboardNavigationEvent> = _navigationEvents.asSharedFlow()

    init {
        observeRepositoryData()
    }

    private fun observeRepositoryData() {
        if (habitRepository == null) return

        viewModelScope.launch {
            combine(
                habitRepository.getHabitStreak(),
                habitRepository.getSugarTrafficLightToday(),
                habitRepository.getWeeklySugarHistory(),
                habitRepository.getWaterIntakeToday(),
                habitRepository.getNightRoutineToday()
            ) { streak, sugarToday, weeklySugar, water, nightRoutine ->
                DashboardUiState(
                    habitStreak = streak,
                    sugarLevelToday = sugarToday,
                    weeklySugarDays = weeklySugar,
                    waterIntake = water,
                    nightRoutine = nightRoutine,
                    isLoading = false
                )
            }.collect { newState ->
                _uiState.value = newState
            }
        }
    }

    fun onEvent(event: DashboardEvent) {
        when (event) {
            is DashboardEvent.SelectSugarLevel -> handleSelectSugarLevel(event.level)
            DashboardEvent.AddWaterGlass -> handleAddWater()
            DashboardEvent.RemoveWaterGlass -> handleRemoveWater()
            DashboardEvent.OpenCravingRescue -> handleOpenCravingRescue()
            DashboardEvent.OpenNightRoutine -> handleOpenNightRoutine()
            DashboardEvent.ToggleNightRoutine -> handleToggleNightRoutine()
            DashboardEvent.DismissFeedbackMessage -> _uiState.update { it.copy(userFeedbackMessage = null) }
            DashboardEvent.RefreshDashboard -> handleRefresh()
        }
    }

    private fun handleSelectSugarLevel(level: SugarTrafficLight) {
        _uiState.update { current ->
            val updatedStreak = if (level == SugarTrafficLight.GREEN) {
                current.habitStreak.copy(
                    currentStreak = current.habitStreak.currentStreak + 1,
                    bestStreak = maxOf(current.habitStreak.bestStreak, current.habitStreak.currentStreak + 1)
                )
            } else {
                current.habitStreak // Keep history intact, log event
            }
            current.copy(
                sugarLevelToday = level,
                habitStreak = updatedStreak,
                userFeedbackMessage = level.feedbackMessage
            )
        }

        viewModelScope.launch {
            habitRepository?.setSugarTrafficLightToday(level)
        }
    }

    private fun handleAddWater() {
        _uiState.update { current ->
            val currentWater = current.waterIntake
            val newCount = currentWater.glassesCount + 1
            current.copy(waterIntake = currentWater.copy(glassesCount = newCount))
        }
        viewModelScope.launch {
            habitRepository?.incrementWater()
        }
    }

    private fun handleRemoveWater() {
        _uiState.update { current ->
            val currentWater = current.waterIntake
            if (currentWater.glassesCount > 0) {
                val newCount = currentWater.glassesCount - 1
                current.copy(waterIntake = currentWater.copy(glassesCount = newCount))
            } else {
                current
            }
        }
        viewModelScope.launch {
            habitRepository?.decrementWater()
        }
    }

    private fun handleOpenCravingRescue() {
        viewModelScope.launch {
            _navigationEvents.emit(DashboardNavigationEvent.NavigateToCravingRescue)
        }
    }

    private fun handleOpenNightRoutine() {
        viewModelScope.launch {
            _navigationEvents.emit(DashboardNavigationEvent.NavigateToNightRoutine)
        }
    }

    private fun handleToggleNightRoutine() {
        _uiState.update { current ->
            val toggled = !current.nightRoutine.isCompletedToday
            current.copy(
                nightRoutine = current.nightRoutine.copy(isCompletedToday = toggled),
                userFeedbackMessage = if (toggled) "¡Rutina nocturna completada! Tu cuerpo descansará mejor." else null
            )
        }
        viewModelScope.launch {
            habitRepository?.toggleNightRoutine()
        }
    }

    private fun handleRefresh() {
        // Triggers repository reload if connected
    }
}
