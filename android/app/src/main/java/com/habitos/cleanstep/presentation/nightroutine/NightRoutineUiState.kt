package com.habitos.cleanstep.presentation.nightroutine

import com.habitos.cleanstep.domain.model.NightRoutineExercise
import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.PlayerPhase
import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel

data class NightRoutineUiState(
    val plan: NightRoutinePlan = NightRoutinePlan(),
    val currentExerciseIndex: Int = 0,
    val playerPhase: PlayerPhase = PlayerPhase.NOT_STARTED,
    val secondsRemaining: Int = 0,
    val totalPhaseSeconds: Int = 1,
    val isPaused: Boolean = false,
    val completedDaysThisWeek: Int = 3,
    val progressionLevel: SedentaryProgressionLevel = SedentaryProgressionLevel.LEVEL_1,
    val isCompletedToday: Boolean = false,
    val exercisesDoneCount: Int = 0
) {
    val currentExercise: NightRoutineExercise?
        get() = plan.exercises.getOrNull(currentExerciseIndex)

    val progressFraction: Float
        get() = if (totalPhaseSeconds > 0) {
            1f - (secondsRemaining.toFloat() / totalPhaseSeconds.toFloat()).coerceIn(0f, 1f)
        } else 0f

    val overallRoutineProgressFraction: Float
        get() {
            if (plan.exercises.isEmpty()) return 0f
            val baseExerciseProgress = currentExerciseIndex.toFloat() / plan.exercises.size.toFloat()
            val phaseFraction = (progressFraction / plan.exercises.size.toFloat())
            return (baseExerciseProgress + phaseFraction).coerceIn(0f, 1f)
        }

    val isLastExercise: Boolean
        get() = currentExerciseIndex >= plan.exercises.size - 1

    val unlockedNextLevelThisWeek: Boolean
        get() = completedDaysThisWeek >= 4
}
