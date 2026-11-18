package com.habitloss.app.presentation.cravings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.habitloss.app.domain.model.CravingRescueSession
import com.habitloss.app.domain.model.CravingType
import com.habitloss.app.domain.model.RescueSnack
import com.habitloss.app.domain.model.TimerStatus
import com.habitloss.app.domain.repository.CravingRescueRepository
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

/**
 * Efectos secundarios únicos emitidos por el ViewModel (vibración, cierre, navegación).
 */
sealed interface CravingsSideEffect {
    data object TimerCompletedVibration : CravingsSideEffect
    data class ShowToast(val message: String) : CravingsSideEffect
    data object DismissSheet : CravingsSideEffect
}

/**
 * ViewModel que orquesta el temporizador de "Urge Surfing" (10-15 minutos)
 * y el catálogo de snacks de rescate mexicanos de alta saciedad.
 */
class CravingsViewModel(
    private val repository: CravingRescueRepository? = null
) : ViewModel() {

    private val _uiState = MutableStateFlow(CravingsUiState())
    val uiState: StateFlow<CravingsUiState> = _uiState.asStateFlow()

    private val _sideEffects = MutableSharedFlow<CravingsSideEffect>()
    val sideEffects: SharedFlow<CravingsSideEffect> = _sideEffects.asSharedFlow()

    private var timerJob: Job? = null

    /**
     * Procesa los eventos emitidos por la UI de Compose.
     */
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

    /**
     * Cambia la duración deseada para surfear el impulso (10 o 15 minutos).
     */
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

    /**
     * Inicia el temporizador de cuenta regresiva de Urge Surfing.
     */
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

    /**
     * Pausa el temporizador si está corriendo.
     */
    fun pauseTimer() {
        if (_uiState.value.timerStatus != TimerStatus.RUNNING) return
        timerJob?.cancel()
        timerJob = null
        _uiState.update { it.copy(timerStatus = TimerStatus.PAUSED) }
    }

    /**
     * Reanuda la cuenta regresiva desde los segundos restantes actuales.
     */
    fun resumeTimer() {
        if (_uiState.value.timerStatus != TimerStatus.PAUSED) return
        startTimer()
    }

    /**
     * Reinicia el temporizador al valor inicial de minutos seleccionados.
     */
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

    /**
     * Selecciona un snack de rescate para ver el detalle de saciedad e ingredientes.
     */
    fun selectSnack(snack: RescueSnack) {
        _uiState.update {
            it.copy(
                selectedSnack = snack,
                showSnackDetails = true
            )
        }
    }

    /**
     * Cierra el modal o diálogo de detalle del snack.
     */
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

    /**
     * El usuario completó el surfeo y el antojo desapareció sin consumir nada.
     */
    fun confirmCravingPassedWithoutEating() {
        _uiState.update {
            it.copy(
                surfedWithoutEating = true,
                isSessionCompleted = true
            )
        }

        viewModelScope.launch {
            repository?.logCravingSession(
                CravingRescueSession(
                    cravingType = CravingType.SWEET,
                    delaySecondsTarget = _uiState.value.totalSeconds,
                    secondsWaited = _uiState.value.elapsedSeconds,
                    resistedSuccessfully = true,
                    selectedSwap = null
                )
            )
            _sideEffects.emit(
                CravingsSideEffect.ShowToast("¡Increíble! Venciste la dopamina del antojo 🎉")
            )
            _sideEffects.emit(CravingsSideEffect.DismissSheet)
        }
    }

    /**
     * El usuario completó el surfeo, identificó hambre fisiológica real y consumió un snack de rescate sin azúcar.
     */
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
                CravingRescueSession(
                    cravingType = when (snack.id) {
                        "mineral_water_lemon" -> CravingType.LIQUID_SUGAR
                        "cucumber_jicama_crunch" -> CravingType.SALTY_CRUNCHY
                        "boiled_eggs_protein" -> CravingType.SWEET
                        "roasted_peanuts_fats" -> CravingType.BOREDOM_STRESS
                        else -> CravingType.BOREDOM_STRESS
                    },
                    delaySecondsTarget = _uiState.value.totalSeconds,
                    secondsWaited = _uiState.value.elapsedSeconds,
                    resistedSuccessfully = true,
                    selectedSwap = snack.name
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
