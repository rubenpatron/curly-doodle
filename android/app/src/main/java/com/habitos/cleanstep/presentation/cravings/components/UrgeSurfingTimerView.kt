package com.habitos.cleanstep.presentation.cravings.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Waves
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.AmberAccent
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurface
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceVariant
import com.habitos.cleanstep.core.designsystem.theme.EmeraldLight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.WaterCyan
import com.habitos.cleanstep.domain.model.TimerStatus
import com.habitos.cleanstep.domain.model.UrgeSurfingPhase
import com.habitos.cleanstep.presentation.cravings.CravingsUiState

/**
 * Componente interactivo del temporizador de Urge Surfing (10 o 15 minutos).
 */
@Composable
fun UrgeSurfingTimerView(
    uiState: CravingsUiState,
    onDurationSelected: (Int) -> Unit,
    onStartTimer: () -> Unit,
    onPauseTimer: () -> Unit,
    onResumeTimer: () -> Unit,
    onResetTimer: () -> Unit,
    onConfirmNoFood: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        shape = RoundedCornerShape(24.dp),
        border = CardDefaults.outlinedCardBorder().copy(
            brush = Brush.verticalGradient(
                colors = listOf(
                    EmeraldPrimary.copy(alpha = 0.4f),
                    WaterCyan.copy(alpha = 0.2f),
                    DarkOutline
                )
            )
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header del temporizador
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Waves,
                        contentDescription = "Urge Surfing",
                        tint = EmeraldPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "SURFEO DEL ANTOJO",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = EmeraldPrimary,
                        letterSpacing = 1.2.sp
                    )
                }

                // Selector de 10 min vs 15 min
                DurationSelectorChips(
                    selectedMinutes = uiState.selectedDurationMinutes,
                    isEnabled = uiState.timerStatus != TimerStatus.RUNNING,
                    onSelected = onDurationSelected
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Anillo Circular del Temporizador
            CircularTimerDisplay(
                formattedTime = uiState.formattedRemainingTime,
                progressFraction = uiState.progressFraction,
                currentPhase = uiState.currentPhase,
                isRunning = uiState.isRunning,
                isCompleted = uiState.isCompleted
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Tarjeta de Guía Neurobiológica y Respiración Somática
            MindfulUrgeSurfingGuidanceCard(
                phase = uiState.currentPhase,
                isCompleted = uiState.isCompleted
            )

            Spacer(modifier = Modifier.height(18.dp))

            // Botones de control del temporizador
            TimerControlButtons(
                timerStatus = uiState.timerStatus,
                isCompleted = uiState.isCompleted,
                onStart = onStartTimer,
                onPause = onPauseTimer,
                onResume = onResumeTimer,
                onReset = onResetTimer,
                onConfirmNoFood = onConfirmNoFood
            )
        }
    }
}

@Composable
private fun CircularTimerDisplay(
    formattedTime: String,
    progressFraction: Float,
    currentPhase: UrgeSurfingPhase,
    isRunning: Boolean,
    isCompleted: Boolean
) {
    val animatedProgress by animateFloatAsState(
        targetValue = progressFraction,
        animationSpec = tween(durationMillis = 600, easing = FastOutSlowInEasing),
        label = "timerProgress"
    )

    val primaryRingColor by animateColorAsState(
        targetValue = when {
            isCompleted -> EmeraldPrimary
            currentPhase == UrgeSurfingPhase.PEAK_CREST -> AmberAccent
            currentPhase == UrgeSurfingPhase.SUBSIDING -> WaterCyan
            else -> EmeraldLight
        },
        label = "ringColor"
    )

    Box(
        modifier = Modifier.size(190.dp),
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.size(180.dp)) {
            val strokeWidthPx = 10.dp.toPx()
            val diameter = size.minDimension - strokeWidthPx
            val topLeft = Offset((size.width - diameter) / 2f, (size.height - diameter) / 2f)

            // Track de fondo
            drawArc(
                color = Color(0xFF222938),
                startAngle = -90f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = Size(diameter, diameter),
                style = Stroke(width = strokeWidthPx, cap = StrokeCap.Round)
            )

            // Arco de progreso animado
            val sweepAngle = animatedProgress * 360f
            if (sweepAngle > 0f) {
                drawArc(
                    brush = Brush.sweepGradient(
                        colors = listOf(
                            WaterCyan,
                            primaryRingColor,
                            EmeraldPrimary
                        )
                    ),
                    startAngle = -90f,
                    sweepAngle = sweepAngle,
                    useCenter = false,
                    topLeft = topLeft,
                    size = Size(diameter, diameter),
                    style = Stroke(width = strokeWidthPx, cap = StrokeCap.Round)
                )
            }
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            if (isCompleted) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = "Completado",
                    tint = EmeraldPrimary,
                    modifier = Modifier.size(36.dp)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "¡SURFEADO!",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = TextPrimary
                )
            } else {
                Text(
                    text = formattedTime,
                    fontSize = 38.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace,
                    color = TextPrimary
                )
                Text(
                    text = when {
                        isRunning -> "Surfeando ola..."
                        progressFraction > 0f -> "En pausa"
                        else -> "Listo para iniciar"
                    },
                    fontSize = 12.sp,
                    color = if (isRunning) EmeraldPrimary else TextSecondary
                )
            }
        }
    }
}

@Composable
private fun DurationSelectorChips(
    selectedMinutes: Int,
    isEnabled: Boolean,
    onSelected: (Int) -> Unit
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(DarkSurfaceVariant)
            .padding(2.dp)
    ) {
        listOf(10, 15).forEach { minutes ->
            val isSelected = selectedMinutes == minutes
            val backgroundColor = if (isSelected) EmeraldPrimary else Color.Transparent
            val textColor = if (isSelected) Color(0xFF0B0D13) else TextSecondary

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .background(backgroundColor)
                    .clickable(enabled = isEnabled) { onSelected(minutes) }
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "$minutes min",
                    fontSize = 12.sp,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                    color = textColor
                )
            }
        }
    }
}

@Composable
private fun MindfulUrgeSurfingGuidanceCard(
    phase: UrgeSurfingPhase,
    isCompleted: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = DarkSurfaceHighlight),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = phase.title,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = if (isCompleted) EmeraldPrimary else TextPrimary
                )
                Text(
                    text = phase.subtitle,
                    fontSize = 11.sp,
                    color = TextSecondary
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = phase.advicePrompt,
                fontSize = 12.sp,
                color = Color(0xFFD1D5DB),
                lineHeight = 17.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(DarkSurface)
                    .padding(horizontal = 10.dp, vertical = 6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Air,
                    contentDescription = "Respiración",
                    tint = WaterCyan,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = phase.breathingTip,
                    fontSize = 11.sp,
                    color = Color(0xFFBAE6FD),
                    lineHeight = 15.sp
                )
            }
        }
    }
}

@Composable
private fun TimerControlButtons(
    timerStatus: TimerStatus,
    isCompleted: Boolean,
    onStart: () -> Unit,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onReset: () -> Unit,
    onConfirmNoFood: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        when {
            isCompleted -> {
                Button(
                    onClick = onConfirmNoFood,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = EmeraldPrimary),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        text = "¡El antojo pasó! No comí nada 🎉",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedButton(
                    onClick = onReset,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(42.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Reiniciar temporizador", color = TextSecondary, fontSize = 13.sp)
                }
            }

            timerStatus == TimerStatus.RUNNING -> {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = onPause,
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AmberAccent),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Pause, contentDescription = "Pausar", tint = Color.Black)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Pausar", color = Color.Black, fontWeight = FontWeight.Bold)
                    }

                    OutlinedButton(
                        onClick = onReset,
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Refresh, contentDescription = "Reiniciar", tint = TextPrimary)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Reiniciar", color = TextPrimary)
                    }
                }
            }

            timerStatus == TimerStatus.PAUSED -> {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = onResume,
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = EmeraldPrimary),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(imageVector = Icons.Default.PlayArrow, contentDescription = "Reanudar", tint = Color.Black)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Reanudar", color = Color.Black, fontWeight = FontWeight.Bold)
                    }

                    OutlinedButton(
                        onClick = onReset,
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Refresh, contentDescription = "Reiniciar", tint = TextPrimary)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Reiniciar", color = TextPrimary)
                    }
                }
            }

            else -> { // IDLE
                Button(
                    onClick = onStart,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = EmeraldPrimary),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Icon(imageVector = Icons.Default.PlayArrow, contentDescription = "Iniciar", tint = Color.Black)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Iniciar Surfeo del Antojo",
                        color = Color.Black,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
            }
        }
    }
}
