package com.habitos.cleanstep.domain.model

data class NightRoutineSummary(
    val isCompletedToday: Boolean = false,
    val scheduledTime: String = "22:00",
    val title: String = "Rutina Nocturna Sedentaria",
    val durationMinutes: Int = 15,
    val description: String = "Movilidad articular suave de bajo impacto para aliviar tensión lumbar y apagar el sistema nervioso."
)
