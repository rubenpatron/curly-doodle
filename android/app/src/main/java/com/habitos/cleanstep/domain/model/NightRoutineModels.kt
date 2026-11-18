package com.habitos.cleanstep.domain.model

enum class ExerciseType {
    MOBILITY,
    GENTLE_STRENGTH,
    SPINAL_RELIEF,
    PARASYMPATHETIC_BREATHING
}

data class NightRoutineExercise(
    val id: String,
    val name: String,
    val type: ExerciseType,
    val targetArea: String,
    val instructions: String,
    val postureTip: String,
    val workDurationSeconds: Int = 40,
    val restDurationSeconds: Int = 20,
    val iconEmoji: String
)

enum class SedentaryProgressionLevel(
    val levelNumber: Int,
    val title: String,
    val subtitle: String,
    val workDurationSeconds: Int,
    val restDurationSeconds: Int,
    val progressionNote: String
) {
    LEVEL_1(
        levelNumber = 1,
        title = "Nivel 1: Descompresión Inicial",
        subtitle = "Adaptación para cuerpo sedentario (6-8 min)",
        workDurationSeconds = 30,
        restDurationSeconds = 30,
        progressionNote = "Completa 4 días esta semana para desbloquear +5s de resistencia."
    ),
    LEVEL_2(
        levelNumber = 2,
        title = "Nivel 2: Activación y Alivio",
        subtitle = "Ritmo intermedio sin impacto articular (10-12 min)",
        workDurationSeconds = 35,
        restDurationSeconds = 25,
        progressionNote = "+5s de trabajo y descansos más eficientes. ¡Gran consistencia!"
    ),
    LEVEL_3(
        levelNumber = 3,
        title = "Nivel 3: Consolidación Nocturna",
        subtitle = "Rutina completa de 15 min para sueño profundo",
        workDurationSeconds = 40,
        restDurationSeconds = 20,
        progressionNote = "Nivel óptimo alcanzado. Movilidad constante antes de dormir."
    );

    companion object {
        fun fromCompletedDaysThisWeek(completedDays: Int): SedentaryProgressionLevel {
            return when {
                completedDays >= 8 -> LEVEL_3
                completedDays >= 4 -> LEVEL_2
                else -> LEVEL_1
            }
        }
    }
}

data class NightRoutinePlan(
    val id: String = "sedentary_night_v1",
    val title: String = "Rutina Nocturna Sedentaria (10:00 PM)",
    val targetTime: String = "22:00",
    val description: String = "Secuencia de bajo impacto diseñada para personas que pasan muchas horas sentadas. Alivia espalda baja, descontractura cuello y activa el sistema parasimpático para dormir sin insomnio.",
    val level: SedentaryProgressionLevel = SedentaryProgressionLevel.LEVEL_1,
    val exercises: List<NightRoutineExercise> = listOf(
        NightRoutineExercise(
            id = "assisted_squats",
            name = "Sentadillas Asistidas",
            type = ExerciseType.GENTLE_STRENGTH,
            targetArea = "Glúteos y cuádriceps",
            instructions = "Sostén una silla o marco de puerta. Baja suavemente la cadera como sentándote en una silla y sube controlando el movimiento.",
            postureTip = "Mantén la espalda recta y el peso en los talones. No busques velocidad, sino tensión constante sin dolor de rodillas.",
            workDurationSeconds = level.workDurationSeconds,
            restDurationSeconds = level.restDurationSeconds,
            iconEmoji = "🪑"
        ),
        NightRoutineExercise(
            id = "slow_high_knees",
            name = "Elevación Lenta de Rodillas",
            type = ExerciseType.MOBILITY,
            targetArea = "Psoas y flexores de cadera",
            instructions = "De pie, levanta una rodilla a la altura de la cadera de manera pausada (2s arriba, 2s abajo). Alterna piernas.",
            postureTip = "Cero saltos. Si necesitas equilibrio, apoya una mano en la pared. Despierta la cadera tras horas sentado.",
            workDurationSeconds = level.workDurationSeconds,
            restDurationSeconds = level.restDurationSeconds,
            iconEmoji = "🦵"
        ),
        NightRoutineExercise(
            id = "incline_plank",
            name = "Plancha Inclinada",
            type = ExerciseType.GENTLE_STRENGTH,
            targetArea = "Core y zona lumbar",
            instructions = "Apoya los antebrazos sobre una mesa o escritorio firme. Mantén el cuerpo en línea recta activando el abdomen.",
            postureTip = "No arquees la espalda baja. Mucho más seguro y cómodo para principiantes que la plancha en el suelo.",
            workDurationSeconds = level.workDurationSeconds,
            restDurationSeconds = level.restDurationSeconds,
            iconEmoji = "🪵"
        ),
        NightRoutineExercise(
            id = "wall_push_ups",
            name = "Flexiones en Pared",
            type = ExerciseType.GENTLE_STRENGTH,
            targetArea = "Pecho y hombros",
            instructions = "Colócate a un paso de la pared con manos a la altura del pecho. Flexiona codos y empuja suavemente.",
            postureTip = "Abre la postura encorvada producida por la computadora o el teléfono.",
            workDurationSeconds = level.workDurationSeconds,
            restDurationSeconds = level.restDurationSeconds,
            iconEmoji = "🧱"
        ),
        NightRoutineExercise(
            id = "childs_pose",
            name = "Postura del Niño (Descompresión Espinal)",
            type = ExerciseType.SPINAL_RELIEF,
            targetArea = "Espalda baja y dorsal",
            instructions = "De rodillas sobre tapete o cama, siéntate sobre los talones y extiende los brazos hacia adelante en el suelo.",
            postureTip = "Respira profundo por la nariz y siente cómo se descomprimen las vértebras lumbares.",
            workDurationSeconds = level.workDurationSeconds,
            restDurationSeconds = level.restDurationSeconds,
            iconEmoji = "🧘"
        ),
        NightRoutineExercise(
            id = "breathing_4_7_8",
            name = "Respiración 4-7-8 Parasimpática",
            type = ExerciseType.PARASYMPATHETIC_BREATHING,
            targetArea = "Sistema nervioso central",
            instructions = "Inhala por la nariz en 4 segundos, retén el aire 7 segundos y exhala suavemente por la boca en 8 segundos.",
            postureTip = "Apaga el cortisol y la adrenalina. Prepara el ritmo cardíaco para descansar.",
            workDurationSeconds = level.workDurationSeconds,
            restDurationSeconds = 0,
            iconEmoji = "🌬️"
        )
    )
) {
    val totalEstimatedMinutes: Int
        get() = (exercises.sumOf { it.workDurationSeconds + it.restDurationSeconds }) / 60
}

enum class PlayerPhase {
    NOT_STARTED,
    GET_READY,
    WORK,
    REST,
    ROUTINE_FINISHED
}

object NightRoutineCatalog {
    fun getPlanForLevel(levelNumber: Int): NightRoutinePlan {
        val level = when (levelNumber) {
            3 -> SedentaryProgressionLevel.LEVEL_3
            2 -> SedentaryProgressionLevel.LEVEL_2
            else -> SedentaryProgressionLevel.LEVEL_1
        }
        return NightRoutinePlan(level = level)
    }

    fun getPlanForLevel(level: SedentaryProgressionLevel): NightRoutinePlan {
        return NightRoutinePlan(level = level)
    }

    fun createPlanForLevel(level: SedentaryProgressionLevel): NightRoutinePlan {
        return NightRoutinePlan(level = level)
    }
}
