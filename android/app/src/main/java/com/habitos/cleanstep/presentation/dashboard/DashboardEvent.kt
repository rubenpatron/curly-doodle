package com.habitos.cleanstep.presentation.dashboard

import com.habitos.cleanstep.domain.model.SugarTrafficLight

sealed interface DashboardEvent {
    data class SelectSugarLevel(val level: SugarTrafficLight) : DashboardEvent
    object AddWaterGlass : DashboardEvent
    object RemoveWaterGlass : DashboardEvent
    object OpenCravingRescue : DashboardEvent
    object OpenNightRoutine : DashboardEvent
    object ToggleNightRoutine : DashboardEvent
    object DismissFeedbackMessage : DashboardEvent
    object RefreshDashboard : DashboardEvent
}
