package com.habitloss.app.domain.model

/**
 * Ejercicio individual para la rutina nocturna de bajo impacto (+10:00 PM).
 * Adaptado a usuarios sedentarios: sin saltos, sin impacto articular y
 * diseñado específicamente para activar el retorno venoso y descompresión espinal sin adrenalina.
 */
data class NightRoutineExercise(
    val id: String,
    val name: String,
    val targetDurationSeconds: Int = 45,
    val targetReps: String = "",
    val description: String,
    val physiologicalBenefit: String,
    val isBreathingOrCooldown: Boolean = false,
    val tips: String = ""
)

/**
 * Plan de rutina nocturna según el nivel de progresión del usuario (Nivel 1, 2 o 3).
 */
data class NightRoutinePlan(
    val level: Int,
    val title: String,
    val subtitle: String,
    val totalDurationMinutes: Int,
    val completedDaysRequiredForNextLevel: Int = 4,
    val progressionIncrement: String = "+2 reps o +5 seg por ejercicio",
    val exercises: List<NightRoutineExercise>
)

/**
 * Catálogo predefinido de rutinas sedentario-amigables nocturnas.
 */
object NightRoutineCatalog {

    val ASSISTED_SQUATS = NightRoutineExercise(
        id = "assisted_squats",
        name = "Sentadilla asistida en silla",
        targetDurationSeconds = 45,
        targetReps = "10-12 reps lentas",
        description = "Siéntate y levántate controladamente desde una silla o con apoyo ligero en mesa. Empuja con los talones y aprieta glúteos arriba.",
        physiologicalBenefit = "Capta glucosa circulante en los cuádriceps y glúteos sin fatiga cardiovascular ni daño articular.",
        tips = "Rodillas alineadas con la punta de los pies, pecho erguido sin forzar lumbares."
    )

    val SLOW_HIGH_KNEES = NightRoutineExercise(
        id = "slow_high_knees",
        name = "Marcha suave con elevación de rodillas",
        targetDurationSeconds = 45,
        targetReps = "45 seg continuos",
        description = "De pie, eleva alternadamente las rodillas a la altura de la cadera a ritmo pausado y sin saltos.",
        physiologicalBenefit = "Activa la 'bomba muscular del sóleo' y el retorno venoso linfático estancado por horas sentado.",
        tips = "Mantén respiración nasal y abdomen activo; ritmo calmado como paseo."
    )

    val INCLINE_PLANK = NightRoutineExercise(
        id = "incline_plank",
        name = "Plancha inclinada en pared o mueble",
        targetDurationSeconds = 35,
        targetReps = "30-40 seg isométricos",
        description = "Apoya los antebrazos en la pared o superficie firme a 45°. Mantén el cuerpo en una línea recta sólida.",
        physiologicalBenefit = "Estabiliza el core profundo y transverso abdominal sin la compresión discal de una plancha en el piso.",
        tips = "No dejes caer la pelvis ni encorves los hombros; respira de forma constante."
    )

    val WALL_PUSHUPS = NightRoutineExercise(
        id = "wall_pushups",
        name = "Flexiones suaves en pared",
        targetDurationSeconds = 40,
        targetReps = "8-10 reps controladas",
        description = "Manos a la anchura de hombros sobre la pared. Flexiona codos acercando el pecho y empuja con control.",
        physiologicalBenefit = "Abre la postura encorvada por el teclado y celular, fortaleciendo espalda alta y deltoides sin tensión.",
        tips = "Inhala al bajar, exhala al empujar; sin prisas."
    )

    val CHILDS_POSE_DECOMPRESSION = NightRoutineExercise(
        id = "childs_pose_decompression",
        name = "Postura del niño con descompresión espinal",
        targetDurationSeconds = 60,
        targetReps = "60 seg sostenidos",
        description = "De rodillas sobre tapete o cama, lleva los glúteos hacia los talones y extiende los brazos hacia adelante relajando la frente.",
        physiologicalBenefit = "Abre los espacios intervertebrales L4-L5/S1 y estimula el nervio vago reduciendo cortisol antes de dormir.",
        isBreathingOrCooldown = true,
        tips = "Deja que la gravedad estire tu columna; relaja mandíbula y cuello por completo."
    )

    val BREATHING_478 = NightRoutineExercise(
        id = "breathing_478",
        name = "Respiración diafragmática 4-7-8",
        targetDurationSeconds = 120,
        targetReps = "4 ciclos completos",
        description = "Inhala por la nariz en 4s, retén el aire en 7s, exhala lentamente por la boca en 8s con sonido relajante.",
        physiologicalBenefit = "Apaga el sistema nervioso simpático, reduce la frecuencia cardíaca y prepara al cerebro para ondas delta de sueño profundo.",
        isBreathingOrCooldown = true,
        tips = "Realízalo sentado o acostado ya listo para dormir."
    )

    // --- Niveles de Progresión ---

    val LEVEL_1 = NightRoutinePlan(
        level = 1,
        title = "Nivel 1: Descompresión y Circulación Activa",
        subtitle = "10-12 min suaves para aliviar piernas y espalda",
        totalDurationMinutes = 10,
        completedDaysRequiredForNextLevel = 4,
        progressionIncrement = "+2 reps o +5 seg",
        exercises = listOf(
            SLOW_HIGH_KNEES.copy(targetDurationSeconds = 30),
            ASSISTED_SQUATS.copy(targetReps = "8-10 reps"),
            WALL_PUSHUPS.copy(targetReps = "6-8 reps"),
            CHILDS_POSE_DECOMPRESSION.copy(targetDurationSeconds = 60),
            BREATHING_478
        )
    )

    val LEVEL_2 = NightRoutinePlan(
        level = 2,
        title = "Nivel 2: Circulación y Tono Muscular Suave",
        subtitle = "15 min para fortalecer core y activar retorno venoso",
        totalDurationMinutes = 15,
        completedDaysRequiredForNextLevel = 4,
        progressionIncrement = "+2 reps o +5 seg",
        exercises = listOf(
            SLOW_HIGH_KNEES,
            ASSISTED_SQUATS,
            INCLINE_PLANK,
            WALL_PUSHUPS,
            CHILDS_POSE_DECOMPRESSION.copy(targetDurationSeconds = 75),
            BREATHING_478
        )
    )

    val LEVEL_3 = NightRoutinePlan(
        level = 3,
        title = "Nivel 3: Movilidad y Fuerza Isométrica Nocturna",
        subtitle = "20 min completos de descompresión profunda y estabilidad",
        totalDurationMinutes = 20,
        completedDaysRequiredForNextLevel = 4,
        progressionIncrement = "Máxima consolidación del hábito",
        exercises = listOf(
            SLOW_HIGH_KNEES.copy(targetDurationSeconds = 60),
            ASSISTED_SQUATS.copy(targetReps = "12-15 reps con pausa de 2s abajo"),
            INCLINE_PLANK.copy(targetDurationSeconds = 45),
            WALL_PUSHUPS.copy(name = "Flexiones de rodillas en colchoneta", targetReps = "10-12 reps"),
            CHILDS_POSE_DECOMPRESSION.copy(targetDurationSeconds = 90),
            BREATHING_478.copy(targetReps = "6 ciclos completos")
        )
    )

    fun getPlanForLevel(level: Int): NightRoutinePlan = when (level) {
        1 -> LEVEL_1
        2 -> LEVEL_2
        3 -> LEVEL_3
        else -> if (level > 3) LEVEL_3 else LEVEL_1
    }
}
