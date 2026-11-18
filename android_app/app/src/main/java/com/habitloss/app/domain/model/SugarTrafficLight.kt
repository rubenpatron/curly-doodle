package com.habitloss.app.domain.model

enum class SugarTrafficLight(
    val title: String,
    val subtitle: String,
    val colorHex: Long,
    val isClean: Boolean
) {
    GREEN(
        title = "0 azúcares hoy",
        subtitle = "Cero refrescos, galletas ni papas procesadas",
        colorHex = 0xFF10B981, // Emerald Green
        isClean = true
    ),
    AMBER(
        title = "Bebida dulce",
        subtitle = "Refresco, jugo industrial o café muy dulce",
        colorHex = 0xFFF59E0B, // Amber
        isClean = false
    ),
    RED(
        title = "Snack procesado",
        subtitle = "Galletas, Sabritas, frituras o bollería",
        colorHex = 0xFFEF4444, // Red
        isClean = false
    )
}
