package com.habitos.cleanstep.presentation.dashboard.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.CleanStepTheme
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
import com.habitos.cleanstep.domain.model.NightRoutineSummary

@Composable
fun NightRoutinePreviewCard(
    nightRoutine: NightRoutineSummary,
    onOpenRoutine: () -> Unit,
    onToggleCompletion: () -> Unit,
    modifier: Modifier = Modifier
) {
    val borderColor by animateColorAsState(
        targetValue = if (nightRoutine.isCompletedToday) EmeraldPrimary.copy(alpha = 0.5f) else NightViolet.copy(alpha = 0.4f),
        label = "night_border"
    )

    Card(
        modifier = modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        borderColor,
                        DarkOutline
                    )
                ),
                shape = RoundedCornerShape(24.dp)
            )
            .clickable(onClick = onOpenRoutine),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = DarkSurface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(NightVioletContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Bedtime,
                            contentDescription = "Rutina Nocturna",
                            tint = NightViolet,
                            modifier = Modifier.size(16.dp)
                        )
                    }

                    Text(
                        text = "RUTINA NOCTURNA (DESPUÉS DE 22:00)",
                        style = MaterialTheme.typography.labelSmall,
                        color = NightViolet,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }

                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = DarkSurfaceHighlight
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Schedule,
                            contentDescription = "Hora",
                            tint = TextSecondary,
                            modifier = Modifier.size(12.dp)
                        )
                        Text(
                            text = "${nightRoutine.durationMinutes} min",
                            style = MaterialTheme.typography.labelSmall,
                            color = TextSecondary,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Body info
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Movilidad Suave Antisedentarismo",
                        style = MaterialTheme.typography.titleMedium,
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = nightRoutine.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary,
                        lineHeight = 16.sp
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                // Checkbox status toggle
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(
                            if (nightRoutine.isCompletedToday) EmeraldPrimary.copy(alpha = 0.2f) else DarkSurfaceHighlight
                        )
                        .border(
                            width = 1.5.dp,
                            color = if (nightRoutine.isCompletedToday) EmeraldLight else DarkOutline,
                            shape = CircleShape
                        )
                        .clickable(onClick = onToggleCompletion),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = if (nightRoutine.isCompletedToday) "Completada" else "Pendiente",
                        tint = if (nightRoutine.isCompletedToday) EmeraldLight else TextDisabled,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Quick CTA to Open Guided Routine
            Button(
                onClick = onOpenRoutine,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = NightVioletContainer,
                    contentColor = NightViolet
                )
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.PlayArrow,
                        contentDescription = "Play",
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = if (nightRoutine.isCompletedToday) "REPETIR RUTINA GUIADA" else "INICIAR RUTINA GUIADA (15 MIN)",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                        contentDescription = "Ir",
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

@Preview
@Composable
private fun NightRoutinePreviewCardPreview() {
    CleanStepTheme {
        NightRoutinePreviewCard(
            nightRoutine = NightRoutineSummary(
                isCompletedToday = false,
                scheduledTime = "22:00",
                durationMinutes = 15
            ),
            onOpenRoutine = {},
            onToggleCompletion = {},
            modifier = Modifier.padding(16.dp)
        )
    }
}
