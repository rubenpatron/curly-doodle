package com.habitos.cleanstep.presentation.nightroutine

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.PlayerPhase
import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel
import com.habitos.cleanstep.domain.repository.NightRoutinePlanRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class NightRoutineViewModel(
    private val routineRepository: NightRoutinePlanRepository? = null
) : ViewModel() {

    private val _uiState = MutableStateFlow(NightRoutineUiState())
    val uiState: StateFlow<NightRoutineUiState> = _uiState.asStateFlow()

    private val _effects = MutableSharedFlow<NightRoutineEffect>()
    val effects: SharedFlow<NightRoutineEffect> = _effects.asSharedFlow()

    private var timerJob: Job? = null

    init {
        loadWeeklyProgression()
    }

    private fun loadWeeklyProgression() {
        if (routineRepository == null) {
            val defaultPlan = NightRoutinePlan()
            _uiState.update { it.copy(plan = defaultPlan) }
            return
        }

        viewModelScope.launch {
            routineRepository.getCompletedDaysInCurrentWeek().collect { days ->
                val calculatedLevel = SedentaryProgressionLevel.fromCompletedDaysThisWeek(days)
                val planForLevel = routineRepository.getPlanForLevel(calculatedLevel)
                _uiState.update { current ->
                    current.copy(
                        completedDaysThisWeek = days,
                        progressionLevel = calculatedLevel,
                        plan = planForLevel
                    )
                }
            }
        }
    }

    fun onEvent(event: NightRoutineEvent) {
        when (event) {
            NightRoutineEvent.StartRoutine -> startRoutine()
            NightRoutineEvent.PauseResumeTimer -> togglePauseResume()
            NightRoutineEvent.SkipToNextExercise -> skipNext()
            NightRoutineEvent.PreviousExercise -> previousExercise()
            NightRoutineEvent.ResetRoutine -> resetRoutine()
            NightRoutineEvent.FinishAndSaveRoutine -> finishAndSave()
            is NightRoutineEvent.SelectLevel -> changeLevel(event.level)
        }
    }

    private fun startRoutine() {
        if (_uiState.value.playerPhase != PlayerPhase.NOT_STARTED) return

        // Start with 5-second gentle get-ready phase
        transitionToPhase(
            phase = PlayerPhase.GET_READY,
            seconds = 5
        )
    }

    private fun togglePauseResume() {
        val currentlyPaused = _uiState.value.isPaused
        if (currentlyPaused) {
            _uiState.update { it.copy(isPaused = false) }
            resumeTimer()
        } else {
            _uiState.update { it.copy(isPaused = true) }
            timerJob?.cancel()
        }
    }

    private fun skipNext() {
        timerJob?.cancel()
        val currentState = _uiState.value
        if (currentState.isLastExercise) {
            finishAndSave()
        } else {
            val nextIndex = currentState.currentExerciseIndex + 1
            _uiState.update { it.copy(currentExerciseIndex = nextIndex, isPaused = false) }
            val nextExercise = _uiState.value.currentExercise
            val duration = nextExercise?.workDurationSeconds ?: 30
            transitionToPhase(PlayerPhase.WORK, duration)
        }
    }

    private fun previousExercise() {
        timerJob?.cancel()
        val currentIndex = _uiState.value.currentExerciseIndex
        if (currentIndex > 0) {
            val prevIndex = currentIndex - 1
            _uiState.update { it.copy(currentExerciseIndex = prevIndex, isPaused = false) }
            val exercise = _uiState.value.currentExercise
            val duration = exercise?.workDurationSeconds ?: 30
            transitionToPhase(PlayerPhase.WORK, duration)
        }
    }

    private fun transitionToPhase(phase: PlayerPhase, seconds: Int) {
        timerJob?.cancel()
        _uiState.update {
            it.copy(
                playerPhase = phase,
                secondsRemaining = seconds,
                totalPhaseSeconds = maxOf(seconds, 1),
                isPaused = false
            )
        }

        viewModelScope.launch {
            _effects.emit(NightRoutineEffect.TriggerSilentHaptic(isDoublePulse = phase == PlayerPhase.REST))
        }

        resumeTimer()
    }

    private fun resumeTimer() {
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (_uiState.value.secondsRemaining > 0) {
                delay(1000L)
                _uiState.update {
                    it.copy(secondsRemaining = maxOf(0, it.secondsRemaining - 1))
                }
            }
            onPhaseCompleted()
        }
    }

    private fun onPhaseCompleted() {
        val currentState = _uiState.value
        when (currentState.playerPhase) {
            PlayerPhase.GET_READY -> {
                val currentEx = currentState.currentExercise
                val workSecs = currentEx?.workDurationSeconds ?: 30
                transitionToPhase(PlayerPhase.WORK, workSecs)
            }
            PlayerPhase.WORK -> {
                val currentEx = currentState.currentExercise
                val restSecs = currentEx?.restDurationSeconds ?: 0

                if (currentState.isLastExercise) {
                    finishAndSave()
                } else if (restSecs > 0) {
                    transitionToPhase(PlayerPhase.REST, restSecs)
                } else {
                    val nextIndex = currentState.currentExerciseIndex + 1
                    _uiState.update { it.copy(currentExerciseIndex = nextIndex) }
                    val nextEx = _uiState.value.currentExercise
                    transitionToPhase(PlayerPhase.WORK, nextEx?.workDurationSeconds ?: 30)
                }
            }
            PlayerPhase.REST -> {
                val nextIndex = currentState.currentExerciseIndex + 1
                _uiState.update { it.copy(currentExerciseIndex = nextIndex) }
                val nextEx = _uiState.value.currentExercise
                transitionToPhase(PlayerPhase.WORK, nextEx?.workDurationSeconds ?: 30)
            }
            PlayerPhase.NOT_STARTED, PlayerPhase.ROUTINE_FINISHED -> Unit
        }
    }

    private fun finishAndSave() {
        timerJob?.cancel()
        val allDoneExercises = _uiState.value.plan.exercises.map { it.name }
        val durationMin = maxOf(1, _uiState.value.plan.totalEstimatedMinutes)

        _uiState.update {
            it.copy(
                playerPhase = PlayerPhase.ROUTINE_FINISHED,
                secondsRemaining = 0,
                isCompletedToday = true,
                exercisesDoneCount = allDoneExercises.size,
                completedDaysThisWeek = it.completedDaysThisWeek + 1
            )
        }

        viewModelScope.launch {
            _effects.emit(NightRoutineEffect.TriggerSilentHaptic(isDoublePulse = true))
            routineRepository?.markRoutineCompleted(
                exercisesDone = allDoneExercises,
                durationMinutes = durationMin
            )
        }
    }

    private fun resetRoutine() {
        timerJob?.cancel()
        _uiState.update {
            it.copy(
                playerPhase = PlayerPhase.NOT_STARTED,
                currentExerciseIndex = 0,
                secondsRemaining = 0,
                isPaused = false
            )
        }
    }

    private fun changeLevel(level: SedentaryProgressionLevel) {
        val newPlan = routineRepository?.getPlanForLevel(level) ?: NightRoutinePlan(level = level)
        _uiState.update {
            it.copy(
                progressionLevel = level,
                plan = newPlan,
                currentExerciseIndex = 0,
                playerPhase = PlayerPhase.NOT_STARTED,
                secondsRemaining = 0
            )
        }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
    }
}
