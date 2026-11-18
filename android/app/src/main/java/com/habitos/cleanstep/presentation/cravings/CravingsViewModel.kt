package com.habitos.cleanstep.presentation.cravings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.habitos.cleanstep.domain.model.RescueSnack
import com.habitos.cleanstep.domain.model.TimerStatus
import com.habitos.cleanstep.domain.repository.CravingLogEntry
import com.habitos.cleanstep.domain.repository.CravingRescueRepository
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

sealed interface CravingsSideEffect {
    data object TimerCompletedVibration : CravingsSideEffect
    data class ShowToast(val message: String) : CravingsSideEffect
    data object DismissSheet : CravingsSideEffect
}

class CravingsViewModel(
    private val repository: CravingRescueRepository? = null
) : ViewModel() {

    private val _uiState = MutableStateFlow(CravingsUiState())
    val uiState: StateFlow<CravingsUiState> = _uiState.asStateFlow()

    private val _sideEffects = MutableSharedFlow<CravingsSideEffect>()
    val sideEffects: SharedFlow<CravingsSideEffect> = _sideEffects.asSharedFlow()

    private var timerJob: Job? = null

    fun onEvent(event: CravingsEvent) {
        when (event) {
            is CravingsEvent.ChangeDuration -> selectDuration(event.minutes)
            CravingsEvent.StartTimer -> startTimer()
            CravingsEvent.PauseTimer -> pauseTimer()
            CravingsEvent.ResumeTimer -> resumeTimer()
            CravingsEvent.ResetTimer -> resetTimer()
            is CravingsEvent.SelectSnack -> selectSnack(event.snack)
            CravingsEvent.DismissSnackDetails -> dismissSnackDetails()
            CravingsEvent.ToggleScienceExplainer -> toggleScienceExplainer()
            CravingsEvent.ConfirmCravingPassedWithoutEating -> confirmCravingPassedWithoutEating()
            is CravingsEvent.ConfirmAteRescueSnack -> confirmAteRescueSnack(event.snack)
            CravingsEvent.ResetSession -> resetSession()
            CravingsEvent.DismissBottomSheet -> dismissSheet()
        }
    }

    fun selectDuration(minutes: Int) {
        if (_uiState.value.timerStatus == TimerStatus.RUNNING) return
        val totalSecs = minutes * 60
        _uiState.update {
            it.copy(
                selectedDurationMinutes = minutes,
                totalSeconds = totalSecs,
                remainingSeconds = totalSecs,
                timerStatus = TimerStatus.IDLE,
                isSessionCompleted = false
            )
        }
    }

    fun startTimer() {
        if (timerJob?.isActive == true) return

        _uiState.update { it.copy(timerStatus = TimerStatus.RUNNING) }

        timerJob = viewModelScope.launch {
            while (_uiState.value.remainingSeconds > 0 && _uiState.value.timerStatus == TimerStatus.RUNNING) {
                delay(1000L)
                val newRemaining = _uiState.value.remainingSeconds - 1

                if (newRemaining <= 0) {
                    _uiState.update {
                        it.copy(
                            remainingSeconds = 0,
                            timerStatus = TimerStatus.COMPLETED,
                            isSessionCompleted = true
                        )
                    }
                    _sideEffects.emit(CravingsSideEffect.TimerCompletedVibration)
                    break
                } else {
                    _uiState.update { it.copy(remainingSeconds = newRemaining) }
                }
            }
        }
    }

    fun pauseTimer() {
        if (_uiState.value.timerStatus != TimerStatus.RUNNING) return
        timerJob?.cancel()
        timerJob = null
        _uiState.update { it.copy(timerStatus = TimerStatus.PAUSED) }
    }

    fun resumeTimer() {
        if (_uiState.value.timerStatus != TimerStatus.PAUSED) return
        startTimer()
    }

    fun resetTimer() {
        timerJob?.cancel()
        timerJob = null
        val totalSecs = _uiState.value.selectedDurationMinutes * 60
        _uiState.update {
            it.copy(
                remainingSeconds = totalSecs,
                totalSeconds = totalSecs,
                timerStatus = TimerStatus.IDLE,
                isSessionCompleted = false,
                surfedWithoutEating = null
            )
        }
    }

    fun selectSnack(snack: RescueSnack) {
        _uiState.update {
            it.copy(
                selectedSnack = snack,
                showSnackDetails = true
            )
        }
    }

    fun dismissSnackDetails() {
        _uiState.update {
            it.copy(
                selectedSnack = null,
                showSnackDetails = false
            )
        }
    }

    fun toggleScienceExplainer() {
        _uiState.update { it.copy(showScienceExplainerDialog = !it.showScienceExplainerDialog) }
    }

    fun confirmCravingPassedWithoutEating() {
        _uiState.update {
            it.copy(
                surfedWithoutEating = true,
                isSessionCompleted = true
            )
        }

        viewModelScope.launch {
            repository?.logCravingSession(
                CravingLogEntry(
                    durationSecondsTarget = _uiState.value.totalSeconds,
                    secondsWaited = _uiState.value.elapsedSeconds,
                    resistedSuccessfully = true,
                    snackChosenName = null
                )
            )
            _sideEffects.emit(
                CravingsSideEffect.ShowToast("¡Increíble! Venciste la dopamina del antojo 🎉")
            )
            _sideEffects.emit(CravingsSideEffect.DismissSheet)
        }
    }

    fun confirmAteRescueSnack(snack: RescueSnack) {
        _uiState.update {
            it.copy(
                surfedWithoutEating = false,
                selectedSnack = snack,
                isSessionCompleted = true
            )
        }

        viewModelScope.launch {
            repository?.logCravingSession(
                CravingLogEntry(
                    durationSecondsTarget = _uiState.value.totalSeconds,
                    secondsWaited = _uiState.value.elapsedSeconds,
                    resistedSuccessfully = true,
                    snackChosenName = snack.name
                )
            )
            _sideEffects.emit(
                CravingsSideEffect.ShowToast("Excelente elección: ${snack.name} apagará el hambre sin sabotear tu día 🥒✨")
            )
            _sideEffects.emit(CravingsSideEffect.DismissSheet)
        }
    }

    fun resetSession() {
        resetTimer()
        _uiState.update {
            it.copy(
                selectedSnack = null,
                showSnackDetails = false,
                surfedWithoutEating = null,
                isSessionCompleted = false
            )
        }
    }

    private fun dismissSheet() {
        viewModelScope.launch {
            _sideEffects.emit(CravingsSideEffect.DismissSheet)
        }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        timerJob = null
    }
}
