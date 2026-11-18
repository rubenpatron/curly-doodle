package com.habitos.cleanstep.presentation.dashboard.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.CleanStepTheme
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurface
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.TextTertiary
import com.habitos.cleanstep.core.designsystem.theme.TextDisabled
import com.habitos.cleanstep.core.designsystem.theme.WaterCyan
import com.habitos.cleanstep.core.designsystem.theme.WaterCyanContainer
import com.habitos.cleanstep.core.designsystem.theme.WaterCyanDark
import com.habitos.cleanstep.core.designsystem.theme.WaterCyanLight
import com.habitos.cleanstep.domain.model.WaterIntake

@Composable
fun HydrationTrackerCard(
    waterIntake: WaterIntake,
    onAddGlass: () -> Unit,
    onRemoveGlass: () -> Unit,
    modifier: Modifier = Modifier
) {
    val progressAnimated by animateFloatAsState(
        targetValue = waterIntake.progressFraction,
        animationSpec = tween(400),
        label = "water_progress"
    )

    Card(
        modifier = modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        WaterCyan.copy(alpha = 0.4f),
                        DarkOutline
                    )
                ),
                shape = RoundedCornerShape(24.dp)
            ),
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
                            .background(WaterCyanContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.WaterDrop,
                            contentDescription = "Agua",
                            tint = WaterCyanLight,
                            modifier = Modifier.size(16.dp)
                        )
                    }

                    Text(
                        text = "REGISTRO RÁPIDO DE HIDRATACIÓN",
                        style = MaterialTheme.typography.labelSmall,
                        color = WaterCyanLight,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }

                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = DarkSurfaceHighlight
                ) {
                    Text(
                        text = "${waterIntake.currentVolumeMl} / ${waterIntake.targetVolumeMl} ml",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = TextSecondary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Main Count & Stepper Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text(
                            text = "${waterIntake.glassesCount}",
                            style = MaterialTheme.typography.displayMedium,
                            color = WaterCyan,
                            fontWeight = FontWeight.ExtraBold
                        )
                        Text(
                            text = " / ${waterIntake.targetGlasses} vasos",
                            style = MaterialTheme.typography.titleMedium,
                            color = TextSecondary,
                            modifier = Modifier.padding(bottom = 6.dp, start = 4.dp),
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                    Text(
                        text = if (waterIntake.isGoalMet) "¡Meta diaria superada! 🌊" else "Vasos de 250 ml",
                        style = MaterialTheme.typography.bodySmall,
                        color = if (waterIntake.isGoalMet) WaterCyanLight else TextTertiary
                    )
                }

                // Quick +/- Steppers
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    FilledIconButton(
                        onClick = onRemoveGlass,
                        enabled = waterIntake.glassesCount > 0,
                        modifier = Modifier.size(44.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = DarkSurfaceHighlight,
                            contentColor = TextPrimary,
                            disabledContainerColor = DarkSurfaceHighlight.copy(alpha = 0.3f),
                            disabledContentColor = TextDisabled
                        ),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Remove,
                            contentDescription = "Quitar vaso",
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    FilledIconButton(
                        onClick = onAddGlass,
                        modifier = Modifier.size(44.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = WaterCyanDark,
                            contentColor = Color.White
                        ),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Sumar vaso",
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Animated Linear Progress Bar
            LinearProgressIndicator(
                progress = { progressAnimated },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp)),
                color = WaterCyan,
                trackColor = DarkSurfaceHighlight,
                strokeCap = StrokeCap.Round
            )

            Spacer(modifier = Modifier.height(14.dp))

            // Visual Glasses Indicator (Row of 8 icons)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (i in 1..waterIntake.targetGlasses) {
                    val isFilled = i <= waterIntake.glassesCount
                    val glassTint by animateColorAsState(
                        targetValue = if (isFilled) WaterCyan else TextDisabled.copy(alpha = 0.4f),
                        animationSpec = tween(250),
                        label = "glass_tint_$i"
                    )

                    Box(
                        modifier = Modifier
                            .size(32.dp)
                            .clip(CircleShape)
                            .background(
                                if (isFilled) WaterCyanContainer.copy(alpha = 0.6f) else DarkSurfaceHighlight.copy(alpha = 0.5f)
                            )
                            .border(
                                width = 1.dp,
                                color = if (isFilled) WaterCyan.copy(alpha = 0.6f) else DarkOutline.copy(alpha = 0.4f),
                                shape = CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.WaterDrop,
                            contentDescription = "Vaso $i",
                            tint = glassTint,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Thirst vs Hunger Key Tip
            Surface(
                shape = RoundedCornerShape(14.dp),
                color = DarkSurfaceHighlight.copy(alpha = 0.6f),
                border = androidx.compose.foundation.BorderStroke(1.dp, DarkOutline.copy(alpha = 0.5f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Lightbulb,
                        contentDescription = "Tip de sed vs hambre",
                        tint = Color(0xFFFBBF24),
                        modifier = Modifier
                            .size(20.dp)
                            .padding(top = 2.dp)
                    )
                    Text(
                        text = waterIntake.thirstVsHungerTip,
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary,
                        lineHeight = 16.sp
                    )
                }
            }
        }
    }
}

@Preview
@Composable
private fun HydrationTrackerCardPreview() {
    CleanStepTheme {
        HydrationTrackerCard(
            waterIntake = WaterIntake(glassesCount = 5, targetGlasses = 8),
            onAddGlass = {},
            onRemoveGlass = {},
            modifier = Modifier.padding(16.dp)
        )
    }
}
