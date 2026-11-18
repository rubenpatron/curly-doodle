package com.habitos.cleanstep.presentation.nightroutine

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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.CleanStepTheme
import com.habitos.cleanstep.core.designsystem.theme.DarkBackground
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.NightViolet
import com.habitos.cleanstep.core.designsystem.theme.NightVioletContainer
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.TextTertiary
import com.habitos.cleanstep.domain.model.PlayerPhase
import com.habitos.cleanstep.presentation.nightroutine.components.ExercisePlayerCard
import com.habitos.cleanstep.presentation.nightroutine.components.NightExerciseListView
import com.habitos.cleanstep.presentation.nightroutine.components.RoutineCompletedDialog
import com.habitos.cleanstep.presentation.nightroutine.components.WeeklyProgressionCard

@Composable
fun NightRoutineRoute(
    viewModel: NightRoutineViewModel,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    val haptic = LocalHapticFeedback.current

    LaunchedEffect(viewModel.effects) {
        viewModel.effects.collect { effect ->
            when (effect) {
                is NightRoutineEffect.TriggerSilentHaptic -> {
                    // Silent gentle tactile pulse - zero noise in nocturnal environment
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                }
                NightRoutineEffect.NavigateBack -> onNavigateBack()
            }
        }
    }

    NightRoutineScreen(
        uiState = uiState,
        onEvent = viewModel::onEvent,
        onNavigateBack = onNavigateBack,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NightRoutineScreen(
    uiState: NightRoutineUiState,
    onEvent: (NightRoutineEvent) -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBackground),
        containerColor = DarkBackground,
        topBar = {
            NightRoutineTopBar(
                onNavigateBack = onNavigateBack,
                modifier = Modifier
                    .statusBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
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
            // Science of nocturnal low-impact decompression
            item(key = "nocturnal_philosophy_card") {
                NocturnalPhilosophyCard()
            }

            // 1. Weekly Progression Card (Level 1, 2, 3 with >= 4 days rule)
            item(key = "weekly_progression_card") {
                WeeklyProgressionCard(
                    currentLevel = uiState.progressionLevel,
                    completedDaysThisWeek = uiState.completedDaysThisWeek,
                    onSelectLevel = { onEvent(NightRoutineEvent.SelectLevel(it)) }
                )
            }

            // 2. Guided Exercise Player Card with circular countdown timer & controls
            item(key = "exercise_player_card") {
                ExercisePlayerCard(
                    currentExercise = uiState.currentExercise,
                    exerciseIndex = uiState.currentExerciseIndex,
                    totalExercises = uiState.plan.exercises.size,
                    playerPhase = uiState.playerPhase,
                    secondsRemaining = uiState.secondsRemaining,
                    progressFraction = uiState.progressFraction,
                    isPaused = uiState.isPaused,
                    onStart = { onEvent(NightRoutineEvent.StartRoutine) },
                    onPauseResume = { onEvent(NightRoutineEvent.PauseResumeTimer) },
                    onNext = { onEvent(NightRoutineEvent.SkipToNextExercise) },
                    onPrevious = { onEvent(NightRoutineEvent.PreviousExercise) }
                )
            }

            // 3. Exercise Sequence Overview
            item(key = "exercise_sequence_list") {
                NightExerciseListView(
                    exercises = uiState.plan.exercises,
                    currentActiveIndex = uiState.currentExerciseIndex
                )
            }

            // Spacing
            item(key = "bottom_spacer") {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }

    // Completion Dialog
    if (uiState.playerPhase == PlayerPhase.ROUTINE_FINISHED) {
        RoutineCompletedDialog(
            completedDaysThisWeek = uiState.completedDaysThisWeek,
            unlockedNextLevel = uiState.unlockedNextLevelThisWeek,
            onDismiss = {
                onEvent(NightRoutineEvent.ResetRoutine)
                onNavigateBack()
            }
        )
    }
}

@Composable
private fun NightRoutineTopBar(
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Surface(
                modifier = Modifier.size(40.dp),
                shape = CircleShape,
                color = DarkSurfaceHighlight,
                border = androidx.compose.foundation.BorderStroke(1.dp, DarkOutline)
            ) {
                IconButton(onClick = onNavigateBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Regresar",
                        tint = TextPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Column {
                Text(
                    text = "DESACELERACIÓN NOCTURNA",
                    style = MaterialTheme.typography.labelSmall,
                    color = NightViolet,
                    fontWeight = FontWeight.ExtraBold,
                    letterSpacing = 1.sp
                )
                Text(
                    text = "Rutina Sedentaria (+10:00 PM)",
                    style = MaterialTheme.typography.headlineMedium,
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(NightVioletContainer),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Bedtime,
                contentDescription = "Noche",
                tint = NightViolet,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun NocturnalPhilosophyCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = DarkSurfaceHighlight.copy(alpha = 0.5f)
        ),
        border = androidx.compose.foundation.BorderStroke(1.dp, DarkOutline.copy(alpha = 0.5f))
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Info,
                contentDescription = "Propósito",
                tint = NightViolet,
                modifier = Modifier
                    .size(20.dp)
                    .padding(top = 2.dp)
            )
            Column {
                Text(
                    text = "¿Por qué bajo impacto a las 10:00 PM?",
                    style = MaterialTheme.typography.labelMedium,
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = "El ejercicio intenso nocturno dispara la adrenalina e insomnio. Esta rutina está diseñada específicamente para aliviar la compresión lumbar de horas sentado y desacelerar tu ritmo cardíaco para conciliar el sueño.",
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                    lineHeight = 15.sp
                )
            }
        }
    }
}

@Preview(name = "Night Routine Dark Mode", showBackground = true, backgroundColor = 0xFF0B0D13)
@Composable
private fun NightRoutineScreenPreview() {
    CleanStepTheme {
        NightRoutineScreen(
            uiState = NightRoutineUiState(
                completedDaysThisWeek = 3
            ),
            onEvent = {},
            onNavigateBack = {}
        )
    }
}
