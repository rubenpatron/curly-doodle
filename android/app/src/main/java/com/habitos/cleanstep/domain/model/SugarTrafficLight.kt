package com.habitos.cleanstep.domain.model

enum class SugarTrafficLight(
    val title: String,
    val subtitle: String,
    val description: String,
    val feedbackMessage: String
) {
    GREEN(
        title = "0 azúcares hoy",
        subtitle = "Día 100% limpio",
        description = "Sin bebidas azucaradas ni snacks procesados entre comidas",
        feedbackMessage = "¡Excelente! Cero picos de glucosa hoy. Tu sensibilidad a la insulina mejora."
    ),
    AMBER(
        title = "Bebida dulce",
        subtitle = "Refresco o jugo",
        description = "Consumo de calorías líquidas azucaradas",
        feedbackMessage = "Identificado. Bebe 2 vasos de agua para acelerar el vaciamiento y evitar el rebote de hambre."
    ),
    RED(
        title = "Snack procesado",
        subtitle = "Galletas o Sabritas",
        description = "Grasa + azúcar refinada/sal ultraprocesada",
        feedbackMessage = "No te castigues ni compenses dejando de cenar. El objetivo es cortar el ciclo ahora mismo."
    ),
    NONE(
        title = "Sin registrar",
        subtitle = "Toca para registrar",
        description = "Marca cómo vas con los azúcares hoy",
        feedbackMessage = "Sé honesto contigo mismo. Un registro sincero es el primer paso hacia el autocontrol."
    )
}

data class WeeklySugarDay(
    val dayOfWeek: String, // "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"
    val dateString: String,
    val status: SugarTrafficLight,
    val isToday: Boolean = false
)
