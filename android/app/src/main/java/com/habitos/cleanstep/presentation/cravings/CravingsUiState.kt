package com.habitos.cleanstep.presentation.cravings

import com.habitos.cleanstep.domain.model.MexicanRescueSnacksCatalog
import com.habitos.cleanstep.domain.model.RescueSnack
import com.habitos.cleanstep.domain.model.TimerStatus
import com.habitos.cleanstep.domain.model.UrgeSurfingPhase

/**
 * Estado inmutable de la interfaz de usuario para el módulo "Tengo Antojo / Urge Surfing".
 */
data class CravingsUiState(
    val selectedDurationMinutes: Int = 15,
    val remainingSeconds: Int = 15 * 60,
    val totalSeconds: Int = 15 * 60,
    val timerStatus: TimerStatus = TimerStatus.IDLE,
    val rescueSnacks: List<RescueSnack> = MexicanRescueSnacksCatalog.snacks,
    val selectedSnack: RescueSnack? = null,
    val showSnackDetails: Boolean = false,
    val surfedWithoutEating: Boolean? = null,
    val isSessionCompleted: Boolean = false,
    val showScienceExplainerDialog: Boolean = false
) {
    val progressFraction: Float
        get() = if (totalSeconds <= 0) 1f else ((totalSeconds - remainingSeconds).toFloat() / totalSeconds).coerceIn(0f, 1f)

    val formattedRemainingTime: String
        get() {
            val minutes = remainingSeconds / 60
            val seconds = remainingSeconds % 60
            return "%02d:%02d".format(minutes, seconds)
        }

    val elapsedSeconds: Int
        get() = totalSeconds - remainingSeconds

    val currentPhase: UrgeSurfingPhase
        get() = UrgeSurfingPhase.fromProgress(remainingSeconds, totalSeconds)

    val isRunning: Boolean
        get() = timerStatus == TimerStatus.RUNNING

    val isPaused: Boolean
        get() = timerStatus == TimerStatus.PAUSED

    val isCompleted: Boolean
        get() = timerStatus == TimerStatus.COMPLETED || remainingSeconds <= 0
}

sealed interface CravingsEvent {
    data class ChangeDuration(val minutes: Int) : CravingsEvent
    data object StartTimer : CravingsEvent
    data object PauseTimer : CravingsEvent
    data object ResumeTimer : CravingsEvent
    data object ResetTimer : CravingsEvent
    data class SelectSnack(val snack: RescueSnack) : CravingsEvent
    data object DismissSnackDetails : CravingsEvent
    data object ToggleScienceExplainer : CravingsEvent
    data object ConfirmCravingPassedWithoutEating : CravingsEvent
    data class ConfirmAteRescueSnack(val snack: RescueSnack) : CravingsEvent
    data object ResetSession : CravingsEvent
    data object DismissBottomSheet : CravingsEvent
}
