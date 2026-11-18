package com.habitos.cleanstep.presentation.nightroutine

import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel

sealed interface NightRoutineEvent {
    object StartRoutine : NightRoutineEvent
    object PauseResumeTimer : NightRoutineEvent
    object SkipToNextExercise : NightRoutineEvent
    object PreviousExercise : NightRoutineEvent
    object ResetRoutine : NightRoutineEvent
    object FinishAndSaveRoutine : NightRoutineEvent
    data class SelectLevel(val level: SedentaryProgressionLevel) : NightRoutineEvent
}

sealed interface NightRoutineEffect {
    data class TriggerSilentHaptic(val isDoublePulse: Boolean = false) : NightRoutineEffect
    object NavigateBack : NightRoutineEffect
}
