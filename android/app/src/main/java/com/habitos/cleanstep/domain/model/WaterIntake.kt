package com.habitos.cleanstep.domain.model

data class WaterIntake(
    val glassesCount: Int = 0,
    val targetGlasses: Int = 8,
    val glassVolumeMl: Int = 250
) {
    val currentVolumeMl: Int
        get() = glassesCount * glassVolumeMl

    val targetVolumeMl: Int
        get() = targetGlasses * glassVolumeMl

    val progressFraction: Float
        get() = if (targetGlasses > 0) (glassesCount.toFloat() / targetGlasses.toFloat()).coerceIn(0f, 1f) else 0f

    val isGoalMet: Boolean
        get() = glassesCount >= targetGlasses

    val thirstVsHungerTip: String
        get() = when {
            glassesCount < 3 -> "💡 ¿Hambre de repente? El cerebro suele confundir la deshidratación leve con hambre. Bebe 1 vaso y espera 10 minutos."
            glassesCount in 3..6 -> "💧 Buen ritmo. Mantenerte hidratado estabiliza los niveles de energía y corta el deseo de refresco."
            else -> "✨ ¡Meta de hidratación alcanzada! Excelente protección contra los antojos nocturnos por aburrimiento."
        }
}
