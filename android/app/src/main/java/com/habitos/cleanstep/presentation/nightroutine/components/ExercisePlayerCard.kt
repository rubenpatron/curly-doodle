package com.habitos.cleanstep.presentation.nightroutine.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.SkipPrevious
import androidx.compose.material.icons.filled.Vibration
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurface
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldLight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldPrimary
import com.habitos.cleanstep.core.designsystem.theme.NightViolet
import com.habitos.cleanstep.core.designsystem.theme.NightVioletContainer
import com.habitos.cleanstep.core.designsystem.theme.TextDisabled
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.TextTertiary
import com.habitos.cleanstep.domain.model.NightRoutineExercise
import com.habitos.cleanstep.domain.model.PlayerPhase

@Composable
fun ExercisePlayerCard(
    currentExercise: NightRoutineExercise?,
    exerciseIndex: Int,
    totalExercises: Int,
    playerPhase: PlayerPhase,
    secondsRemaining: Int,
    progressFraction: Float,
    isPaused: Boolean,
    onStart: () -> Unit,
    onPauseResume: () -> Unit,
    onNext: () -> Unit,
    onPrevious: () -> Unit,
    modifier: Modifier = Modifier
) {
    val phaseColor by animateColorAsState(
        targetValue = when (playerPhase) {
            PlayerPhase.NOT_STARTED -> NightViolet
            PlayerPhase.GET_READY -> Color(0xFFFBBF24)
            PlayerPhase.WORK -> EmeraldPrimary
            PlayerPhase.REST -> NightViolet
            PlayerPhase.ROUTINE_FINISHED -> EmeraldLight
        },
        label = "phase_color"
    )

    val animatedProgress by animateFloatAsState(
        targetValue = progressFraction,
        animationSpec = tween(300),
        label = "animated_progress"
    )

    Card(
        modifier = modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        phaseColor.copy(alpha = 0.5f),
                        DarkOutline
                    )
                ),
                shape = RoundedCornerShape(24.dp)
            ),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Exercise index pill & phase badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = DarkSurfaceHighlight
                ) {
                    Text(
                        text = "Ejercicio ${exerciseIndex + 1} de $totalExercises",
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = TextSecondary,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = phaseColor.copy(alpha = 0.2f),
                    border = androidx.compose.foundation.BorderStroke(1.dp, phaseColor.copy(alpha = 0.5f))
                ) {
                    Text(
                        text = when (playerPhase) {
                            PlayerPhase.NOT_STARTED -> "Listo para iniciar"
                            PlayerPhase.GET_READY -> "Prepárate"
                            PlayerPhase.WORK -> "En Movimiento"
                            PlayerPhase.REST -> "Descanso Suave"
                            PlayerPhase.ROUTINE_FINISHED -> "¡Completado!"
                        },
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = phaseColor,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Circular Countdown Timer
            Box(
                modifier = Modifier.size(180.dp),
                contentAlignment = Alignment.Center
            ) {
                Canvas(modifier = Modifier.size(170.dp)) {
                    // Background track
                    drawCircle(
                        color = DarkSurfaceHighlight,
                        radius = size.minDimension / 2,
                        style = Stroke(width = 12.dp.toPx(), cap = StrokeCap.Round)
                    )
                    // Progress arc
                    if (playerPhase != PlayerPhase.NOT_STARTED) {
                        drawArc(
                            color = phaseColor,
                            startAngle = -90f,
                            sweepAngle = 360f * animatedProgress,
                            useCenter = false,
                            style = Stroke(width = 12.dp.toPx(), cap = StrokeCap.Round)
                        )
                    }
                }

                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = currentExercise?.iconEmoji ?: "🌙",
                        fontSize = 28.sp
                    )

                    AnimatedContent(
                        targetState = secondsRemaining,
                        transitionSpec = { fadeIn() togetherWith fadeOut() },
                        label = "seconds_text"
                    ) { seconds ->
                        Text(
                            text = if (playerPhase == PlayerPhase.NOT_STARTED) {
                                "${currentExercise?.workDurationSeconds ?: 30}s"
                            } else {
                                "${seconds}s"
                            },
                            style = MaterialTheme.typography.displayMedium,
                            color = TextPrimary,
                            fontWeight = FontWeight.ExtraBold
                        )
                    }

                    Text(
                        text = if (isPaused) "PAUSADO" else if (playerPhase == PlayerPhase.REST) "DESCANSO" else "TIEMPO",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isPaused) Color(0xFFFBBF24) else TextTertiary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 10.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Exercise Title and Target
            Text(
                text = currentExercise?.name ?: "Rutina Nocturna",
                style = MaterialTheme.typography.titleLarge,
                color = TextPrimary,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Surface(
                shape = RoundedCornerShape(8.dp),
                color = DarkSurfaceHighlight
            ) {
                Text(
                    text = "Zona: ${currentExercise?.targetArea ?: ""}",
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                    style = MaterialTheme.typography.labelSmall,
                    color = NightViolet,
                    fontWeight = FontWeight.Medium
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Instructions
            Text(
                text = currentExercise?.instructions ?: "",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
                lineHeight = 18.sp
            )

            Spacer(modifier = Modifier.height(10.dp))

            // Posture Tip Card
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = DarkSurfaceHighlight.copy(alpha = 0.6f),
                border = androidx.compose.foundation.BorderStroke(1.dp, DarkOutline.copy(alpha = 0.5f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(10.dp),
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Lightbulb,
                        contentDescription = "Postura",
                        tint = Color(0xFFFBBF24),
                        modifier = Modifier
                            .size(16.dp)
                            .padding(top = 2.dp)
                    )
                    Text(
                        text = currentExercise?.postureTip ?: "",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextTertiary,
                        lineHeight = 15.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Silent Vibration Indicator Pill
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = DarkSurfaceHighlight.copy(alpha = 0.4f),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Vibration,
                        contentDescription = "Vibración silenciosa",
                        tint = EmeraldLight,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Vibración suave y silenciosa al cambiar de fase (sin sonido)",
                        style = MaterialTheme.typography.labelSmall,
                        color = TextTertiary,
                        fontSize = 11.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(18.dp))

            // Player Controls
            if (playerPhase == PlayerPhase.NOT_STARTED) {
                Button(
                    onClick = onStart,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = NightViolet,
                        contentColor = Color.White
                    )
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.PlayArrow,
                            contentDescription = "Iniciar",
                            modifier = Modifier.size(20.dp)
                        )
                        Text(
                            text = "COMENZAR RUTINA GUIADA",
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            } else {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Previous
                    FilledIconButton(
                        onClick = onPrevious,
                        enabled = exerciseIndex > 0,
                        modifier = Modifier.size(48.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = DarkSurfaceHighlight,
                            contentColor = TextPrimary,
                            disabledContainerColor = DarkSurfaceHighlight.copy(alpha = 0.3f),
                            disabledContentColor = TextDisabled
                        ),
                        shape = CircleShape
                    ) {
                        Icon(
                            imageVector = Icons.Default.SkipPrevious,
                            contentDescription = "Anterior",
                            modifier = Modifier.size(22.dp)
                        )
                    }

                    // Play / Pause
                    FilledIconButton(
                        onClick = onPauseResume,
                        modifier = Modifier.size(60.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = phaseColor,
                            contentColor = Color.Black
                        ),
                        shape = CircleShape
                    ) {
                        Icon(
                            imageVector = if (isPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                            contentDescription = if (isPaused) "Reanudar" else "Pausar",
                            modifier = Modifier.size(30.dp)
                        )
                    }

                    // Next
                    FilledIconButton(
                        onClick = onNext,
                        modifier = Modifier.size(48.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = DarkSurfaceHighlight,
                            contentColor = TextPrimary
                        ),
                        shape = CircleShape
                    ) {
                        Icon(
                            imageVector = Icons.Default.SkipNext,
                            contentDescription = "Siguiente",
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }
            }
        }
    }
}
