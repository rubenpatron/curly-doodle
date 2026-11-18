package com.habitloss.app.domain.model

/**
 * Estados del temporizador de Urge Surfing.
 */
enum class TimerStatus {
    IDLE,
    RUNNING,
    PAUSED,
    COMPLETED
}

/**
 * Fases fisiológicas de la curva del impulso ("Urge Surfing").
 * Los impulsos por dopamina tienen un patrón en forma de campana: suben rápido,
 * alcanzan una cresta a los 3-7 minutos y se disipan naturalmente a los 10-15 minutos.
 */
enum class UrgeSurfingPhase(
    val title: String,
    val subtitle: String,
    val advicePrompt: String,
    val breathingTip: String
) {
    RISING(
        title = "La ola está subiendo 🌊",
        subtitle = "Tensión e impulso inicial",
        advicePrompt = "Reconoce la sensación en tu cuerpo sin juzgarla. Es solo dopamina pidiendo un premio fácil, no es hambre real. No luches contra ella: obsérvala como una ola de mar.",
        breathingTip = "Inhala hondo por la nariz en 4 segundos, retén 4 segundos y suelta el aire despacio en 6 segundos. Toma un vaso de agua."
    ),
    PEAK_CREST(
        title = "Cresta máxima del impulso ⚡",
        subtitle = "Momento crítico (3 - 7 min)",
        advicePrompt = "Aquí la urgencia alcanza su punto más alto. Cambia de estímulo físico de inmediato: levántate de la silla, estira la espalda o lávate la cara con agua fría. El cerebro solo necesita 3 minutos de distracción motriz.",
        breathingTip = "Siente el apoyo firme de tus pies en el suelo. Respira lento y recuerda: la ola no puede subir más, a partir de aquí solo puede bajar."
    ),
    SUBSIDING(
        title = "La ola está bajando 📉",
        subtitle = "Desvanecimiento del impulso",
        advicePrompt = "La señal de urgencia química está perdiendo fuerza en tus receptores. Tu corteza prefrontal ha recuperado el control frente al sistema límbico impulsivo.",
        breathingTip = "Mantén respiraciones suaves. Comprueba si el deseo de comer chatarra sigue tan intenso como al principio."
    ),
    COMPLETED_SURF(
        title = "¡Ola surfeada con éxito! 🎉",
        subtitle = "Victoria neuroquímica",
        advicePrompt = "Has completado los 15 minutos. El 80% de los falsos antojos se apagan en este lapso. Si todavía sientes un vacío estomacal genuino, tu cuerpo te pide nutrientes reales, no chatarra.",
        breathingTip = "¡Felicitaciones! Has entrenado a tu cerebro a tolerar la incomodidad sin ceder al hábito automático."
    );

    companion object {
        fun fromProgress(remainingSeconds: Int, totalSeconds: Int): UrgeSurfingPhase {
            if (remainingSeconds <= 0) return COMPLETED_SURF
            val elapsedFraction = (totalSeconds - remainingSeconds).toFloat() / totalSeconds.coerceAtLeast(1)
            return when {
                elapsedFraction < 0.25f -> RISING
                elapsedFraction < 0.60f -> PEAK_CREST
                else -> SUBSIDING
            }
        }
    }
}
