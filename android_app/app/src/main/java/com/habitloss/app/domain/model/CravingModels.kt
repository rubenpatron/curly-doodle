package com.habitloss.app.domain.model

enum class CravingType(val title: String, val iconDescription: String) {
    SWEET("Antojo de Dulce / Galletas", "Azúcar y carbohidratos refinados"),
    SALTY_CRUNCHY("Antojo de Papitas / Sabritas", "Sodio, grasa crujiente"),
    LIQUID_SUGAR("Antojo de Refresco / Jugo", "Bebidas azucaradas"),
    BOREDOM_STRESS("Hambre Emocional / Aburrimiento", "Ansiedad o hábito nocturno")
}

data class SatietySwapItem(
    val id: String,
    val cravingType: CravingType,
    val originalCraving: String,
    val healthySwap: String,
    val satietyMechanism: String,
    val preparationTime: String = "1-2 min"
)

data class CravingRescueSession(
    val id: Long = 0L,
    val timestamp: Long = System.currentTimeMillis(),
    val cravingType: CravingType,
    val delaySecondsTarget: Int = 900, // 15 minutes delay
    val secondsWaited: Int = 0,
    val resistedSuccessfully: Boolean = true,
    val selectedSwap: String? = null
)
