package com.habitos.cleanstep.presentation.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.NotificationsNone
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.CleanStepTheme
import com.habitos.cleanstep.core.designsystem.theme.DarkBackground
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldLight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.TextTertiary
import com.habitos.cleanstep.domain.model.HabitStreak
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WaterIntake
import com.habitos.cleanstep.domain.model.WeeklySugarDay
import com.habitos.cleanstep.presentation.dashboard.components.CleanStreakCard
import com.habitos.cleanstep.presentation.dashboard.components.CravingRescueCtaCard
import com.habitos.cleanstep.presentation.dashboard.components.HydrationTrackerCard
import com.habitos.cleanstep.presentation.dashboard.components.NightRoutinePreviewCard
import com.habitos.cleanstep.presentation.dashboard.components.SugarTrafficLightCard

@Composable
fun DashboardRoute(
    viewModel: DashboardViewModel,
    onNavigateToCravingRescue: () -> Unit,
    onNavigateToNightRoutine: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(viewModel.navigationEvents) {
        viewModel.navigationEvents.collect { event ->
            when (event) {
                DashboardNavigationEvent.NavigateToCravingRescue -> onNavigateToCravingRescue()
                DashboardNavigationEvent.NavigateToNightRoutine -> onNavigateToNightRoutine()
            }
        }
    }

    DashboardScreen(
        uiState = uiState,
        onEvent = viewModel::onEvent,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    uiState: DashboardUiState,
    onEvent: (DashboardEvent) -> Unit,
    modifier: Modifier = Modifier
) {
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(uiState.userFeedbackMessage) {
        uiState.userFeedbackMessage?.let { msg ->
            snackbarHostState.showSnackbar(msg)
            onEvent(DashboardEvent.DismissFeedbackMessage)
        }
    }

    Scaffold(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBackground),
        containerColor = DarkBackground,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            DashboardHeader(
                modifier = Modifier
                    .statusBarsPadding()
                    .padding(horizontal = 20.dp, vertical = 12.dp)
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // Rule of Thumb banner: Zero calorie counting for mom's food
            item(key = "moms_food_notice") {
                MomsFoodNoticeCard()
            }

            // 1. Clean Streak Counter Card
            item(key = "streak_card") {
                CleanStreakCard(
                    streak = uiState.habitStreak
                )
            }

            // 2. Prominent Craving Rescue Emergency CTA
            item(key = "craving_cta") {
                CravingRescueCtaCard(
                    onRescueClicked = { onEvent(DashboardEvent.OpenCravingRescue) }
                )
            }

            // 3. Sugar Traffic Light Selector + Weekly Preview
            item(key = "sugar_traffic_light") {
                SugarTrafficLightCard(
                    currentSelection = uiState.sugarLevelToday,
                    weeklyHistory = uiState.weeklySugarDays,
                    onSelectLevel = { level ->
                        onEvent(DashboardEvent.SelectSugarLevel(level))
                    }
                )
            }

            // 4. Hydration Quick Tracker Card
            item(key = "hydration_tracker") {
                HydrationTrackerCard(
                    waterIntake = uiState.waterIntake,
                    onAddGlass = { onEvent(DashboardEvent.AddWaterGlass) },
                    onRemoveGlass = { onEvent(DashboardEvent.RemoveWaterGlass) }
                )
            }

            // 5. Night Routine Mobility Preview (+10:00 PM)
            item(key = "night_routine") {
                NightRoutinePreviewCard(
                    nightRoutine = uiState.nightRoutine,
                    onOpenRoutine = { onEvent(DashboardEvent.OpenNightRoutine) },
                    onToggleCompletion = { onEvent(DashboardEvent.ToggleNightRoutine) }
                )
            }

            // Bottom Spacing for navigation bar comfort
            item(key = "bottom_spacer") {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
private fun DashboardHeader(
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = "MI TABLERO",
                style = MaterialTheme.typography.labelSmall,
                color = EmeraldLight,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = 1.2.sp
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "Control Diario de Hábitos",
                style = MaterialTheme.typography.headlineMedium,
                color = TextPrimary,
                fontWeight = FontWeight.Bold
            )
        }

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(40.dp),
                shape = CircleShape,
                color = DarkSurfaceHighlight,
                border = androidx.compose.foundation.BorderStroke(1.dp, DarkOutline)
            ) {
                IconButton(onClick = { /* Notification center */ }) {
                    Icon(
                        imageVector = Icons.Default.NotificationsNone,
                        contentDescription = "Notificaciones",
                        tint = TextSecondary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(EmeraldPrimary.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = "Perfil",
                    tint = EmeraldLight,
                    modifier = Modifier.size(22.dp)
                )
            }
        }
    }
}

@Composable
private fun MomsFoodNoticeCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = DarkSurfaceHighlight.copy(alpha = 0.6f)
        ),
        border = androidx.compose.foundation.BorderStroke(1.dp, DarkOutline.copy(alpha = 0.5f))
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Info,
                contentDescription = "Regla de Oro",
                tint = EmeraldLight,
                modifier = Modifier.size(20.dp)
            )
            Column {
                Text(
                    text = "Regla de Oro: Disfruta la comida de mamá",
                    style = MaterialTheme.typography.labelMedium,
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = "Cero conteo de calorías en comida y cena. Tu meta es eliminar refresco, papas y galletas ENTRE comidas.",
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                    lineHeight = 15.sp
                )
            }
        }
    }
}

@Preview(name = "Dashboard Dark Mode", showBackground = true, backgroundColor = 0xFF0B0D13)
@Composable
private fun DashboardScreenPreview() {
    CleanStepTheme {
        DashboardScreen(
            uiState = DashboardUiState(
                habitStreak = HabitStreak(
                    currentStreak = 5,
                    bestStreak = 12,
                    daysWithoutSoda = 7,
                    daysWithoutCookies = 5,
                    daysWithoutChips = 8
                ),
                sugarLevelToday = SugarTrafficLight.GREEN,
                weeklySugarDays = listOf(
                    WeeklySugarDay("Lun", "10 Nov", SugarTrafficLight.GREEN),
                    WeeklySugarDay("Mar", "11 Nov", SugarTrafficLight.GREEN),
                    WeeklySugarDay("Mié", "12 Nov", SugarTrafficLight.AMBER),
                    WeeklySugarDay("Jue", "13 Nov", SugarTrafficLight.GREEN),
                    WeeklySugarDay("Vie", "14 Nov", SugarTrafficLight.RED),
                    WeeklySugarDay("Sáb", "15 Nov", SugarTrafficLight.GREEN),
                    WeeklySugarDay("Dom", "16 Nov", SugarTrafficLight.GREEN, isToday = true)
                ),
                waterIntake = WaterIntake(glassesCount = 5, targetGlasses = 8),
                nightRoutine = NightRoutineSummary(isCompletedToday = false)
            ),
            onEvent = {}
        )
    }
}
